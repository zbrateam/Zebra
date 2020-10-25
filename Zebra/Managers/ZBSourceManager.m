//
//  ZBSourceManager.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBSourceManager.h"

#import <Helpers/utils.h>
#import <Model/ZBSource.h>
#import <Managers/ZBDatabaseManager.h>
#import <Managers/ZBPackageManager.h>
#import <Database/ZBColumn.h>
#import <Downloads/ZBDownloadManager.h>
#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <ZBLog.h>
#import <ZBSettings.h>

@import UIKit.UIDevice;

@interface ZBSourceManager () {
    NSDictionary *sourceMap;
    
    ZBPackageManager *packageManager;
    ZBDatabaseManager *databaseManager;
    ZBDownloadManager *downloadManager;
    NSMutableArray <id <ZBSourceDelegate>> *delegates;
    NSMutableDictionary *busyList;
    NSMutableArray *completedSources;
    NSDictionary *pinPreferences;
}
@end

@implementation ZBSourceManager

@synthesize refreshInProgress;

#pragma mark - Initializers

+ (id)sharedInstance {
    static ZBSourceManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZBSourceManager new];
    });
    return instance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        databaseManager = [ZBDatabaseManager sharedInstance];
        packageManager = [ZBPackageManager sharedInstance];
        
        refreshInProgress = NO;
        
        pinPreferences = [self parsePreferences];
    }
    
    return self;
}

#pragma mark - Accessing Sources

- (NSArray <ZBSource *> *)sources {
    NSError *readError = NULL;
    NSSet *baseSources = [ZBBaseSource baseSourcesFromList:[ZBAppDelegate sourcesListURL] error:&readError];
    if (readError) {
        ZBLog(@"[Zebra] Error when reading sources from %@: %@", [ZBAppDelegate sourcesListURL], readError.localizedDescription);
        
        return [NSArray new];
    }
    
    if (!sourceMap) {
        NSSet *sourcesFromDatabase = [[ZBDatabaseManager sharedInstance] sources];
        NSSet *unionSet = [sourcesFromDatabase setByAddingObjectsFromSet:baseSources];
        
        NSMutableDictionary *tempSourceMap = [NSMutableDictionary new];
        for (ZBBaseSource *source in unionSet) {
            tempSourceMap[source.uuid] = source;
        }
        sourceMap = tempSourceMap;
    } else if (sourceMap && baseSources.count != sourceMap.allValues.count) { // A source was added to sources.list at some point by someone and we don't list it
        NSMutableSet *cache = [NSMutableSet setWithArray:[sourceMap allValues]];
        
        NSMutableSet *sourcesAdded = [baseSources mutableCopy];
        [sourcesAdded minusSet:cache];
        NSLog(@"[Zebra] Sources Added: %@", sourcesAdded);
        
        NSMutableSet *sourcesRemoved = [cache mutableCopy];
        [sourcesRemoved minusSet:baseSources];
        NSLog(@"[Zebra] Sources Removed: %@", sourcesAdded);
        
        if (sourcesAdded.count) [cache unionSet:sourcesAdded];
        if (sourcesRemoved.count) [cache minusSet:sourcesRemoved];
        
        NSMutableDictionary *tempSourceMap = [NSMutableDictionary new];
        for (ZBBaseSource *source in cache) {
            tempSourceMap[source.uuid] = source;
        }
        sourceMap = tempSourceMap;
        
        if (sourcesAdded.count) [self bulkAddedSources:sourcesAdded];
        if (sourcesRemoved.count) [self bulkRemovedSources:sourcesRemoved];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            for (ZBSource *source in sourcesRemoved) {
                [[ZBDatabaseManager sharedInstance] deleteSource:source];
            }
        });
    }
    
    return [[sourceMap allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"label" ascending:TRUE selector:@selector(localizedCaseInsensitiveCompare:)]]];
}

- (ZBSource *)sourceWithUUID:(NSString *)UUID {
    return sourceMap[UUID];
}

#pragma mark - Adding and Removing Sources

- (void)addSources:(NSSet <ZBBaseSource *> *)sources error:(NSError **_Nullable)error {
    NSMutableSet *sourcesToAdd = [sources mutableCopy];
    for (ZBSource *source in sources) {
        if (sourceMap[source.uuid]) {
            ZBLog(@"[Zebra] %@ is already a source", source.repositoryURI); // This isn't going to trigger a failure, should it?
            [sourcesToAdd removeObject:source];
        }
    }
    
    if ([sourcesToAdd count]) {
        NSError *writeError = NULL;
        [self appendBaseSources:sourcesToAdd toFile:[ZBAppDelegate sourcesListPath] error:&writeError];
        
        if (writeError) {
            NSLog(@"[Zebra] Error while writing sources to file: %@", writeError);
            *error = writeError;
            return;
        }
        
        NSMutableDictionary *tempSourceMap = [sourceMap mutableCopy];
        for (ZBBaseSource *source in sourcesToAdd) {
            tempSourceMap[source.uuid] = source;
        }
        sourceMap = tempSourceMap;
        
        [self bulkAddedSources:sourcesToAdd];
        [self refreshSources:[sourcesToAdd allObjects] useCaching:YES error:nil];
    }
}

- (void)updateURIForSource:(ZBSource *)source oldURI:(NSString *)oldURI error:(NSError**_Nullable)error {
//    if (source != nil) {
//        NSSet *sourcesToWrite = [ZBBaseSource baseSourcesFromList:[ZBAppDelegate sourcesListURL] error:nil];
//
//        for (ZBBaseSource *baseSource in sourcesToWrite) {
//            if ([oldURI isEqualToString:baseSource.repositoryURI]) {
//                baseSource.repositoryURI = [source.repositoryURI copy];
//                break;
//            }
//        }
//
//        NSError *writeError = NULL;
//        [self writeBaseSources:sourcesToWrite toFile:[ZBAppDelegate sourcesListPath] error:&writeError];
//        if (writeError) {
//            NSLog(@"[Zebra] Error while writing sources to file: %@", writeError);
//            *error = writeError;
//            return;
//        }
//
//        [[ZBDatabaseManager sharedInstance] updateURIForSource:source];
//    }
}

- (void)removeSources:(NSSet <ZBBaseSource *> *)sources error:(NSError**_Nullable)error {
    NSMutableSet *sourcesToRemove = [sources mutableCopy];
    for (ZBSource *source in sources) {
        if (![source canDelete]) {
            ZBLog(@"[Zebra] %@ cannot be removed", source.repositoryURI); // This isn't going to trigger a failure, should it?
            [sourcesToRemove removeObject:source];
        }
    }
    
    if ([sourcesToRemove count]) {
        NSMutableSet *sourcesToWrite = [[ZBBaseSource baseSourcesFromList:[ZBAppDelegate sourcesListURL] error:nil] mutableCopy];
        [sourcesToWrite minusSet:sourcesToRemove];
        
        NSError *writeError = NULL;
        [self writeBaseSources:sourcesToWrite toFile:[ZBAppDelegate sourcesListPath] error:&writeError];
        if (writeError) {
            NSLog(@"[Zebra] Error while writing sources to file: %@", writeError);
            *error = writeError;
            return;
        }
        
        for (ZBSource *source in sourcesToRemove) {
            if ([source isKindOfClass:[ZBSource class]]) {
                // These actions should theoretically only be performed if the source is in the database as a base sources wouldn't be downloaded
                // Delete cached release/packages files (if they exist)
                NSArray *lists = [source lists];
                for (NSString *list in lists) {
                    NSString *path = [[ZBAppDelegate listsLocation] stringByAppendingPathComponent:list];
                    NSError *error = NULL;
                    if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
                        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                        if (!success) {
                            NSLog(@"Error removing file at path: %@", error.localizedDescription);
                        }
                    }
                }
                
                // Delete files from featured.plist (if they exist)
                NSMutableDictionary *featured = [NSMutableDictionary dictionaryWithContentsOfFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"]];
                if ([featured objectForKey:[source uuid]]) {
                    [featured removeObjectForKey:[source uuid]];
                }
                [featured writeToFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"] atomically:NO];
                
                // Delete source and respective packages from database
                [[ZBDatabaseManager sharedInstance] deleteSource:source];
            }
        }
        
        NSMutableDictionary *tempSourceMap = [sourceMap mutableCopy];
        for (ZBBaseSource *source in sourcesToRemove) {
            [tempSourceMap removeObjectForKey:source.uuid];
        }
        sourceMap = tempSourceMap;
        
        [self bulkRemovedSources:sourcesToRemove];
    }
}

- (void)refreshSourcesUsingCaching:(BOOL)useCaching userRequested:(BOOL)requested error:(NSError **_Nullable)error {
    if (refreshInProgress)
        return;
    
    BOOL needsRefresh = NO;
    if (!requested && [ZBSettings wantsAutoRefresh]) {
        NSDate *currentDate = [NSDate date];
        NSDate *lastUpdatedDate = [self lastUpdated];

        if (lastUpdatedDate != NULL) {
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSUInteger unitFlags = NSCalendarUnitMinute;
            NSDateComponents *components = [gregorian components:unitFlags fromDate:lastUpdatedDate toDate:currentDate options:0];

            needsRefresh = ([components minute] >= 30);
        } else {
            needsRefresh = YES;
        }
    }

//    [databaseManager checkForPackageUpdates];
    if (requested || needsRefresh) {
        [self refreshSources:self.sources useCaching:NO error:nil];
    }
    
}

- (NSDate *)lastUpdated {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"lastUpdated"];
}

- (void)updateLastUpdated {
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastUpdated"];
}

- (void)refreshSources:(NSArray <ZBBaseSource *> *)sources useCaching:(BOOL)caching error:(NSError **_Nullable)error {
    if (refreshInProgress)
        return;
    
    [self bulkStartedSourceRefresh];
    downloadManager = [[ZBDownloadManager alloc] initWithDownloadDelegate:self];
    [downloadManager downloadSources:sources useCaching:caching];
    [self updateLastUpdated];
}

- (void)appendBaseSources:(NSSet <ZBBaseSource *> *)sources toFile:(NSString *)filePath error:(NSError **_Nullable)error {
    NSError *readError = NULL;
    NSString *contents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&readError];
    
    if (readError) {
        NSLog(@"[Zebra] ERROR while loading from sources.list: %@", readError);
        *error = readError;
        return;
    }
    else {
        NSMutableArray *debLines = [NSMutableArray new];
        for (ZBBaseSource *baseSource in sources) {
            [debLines addObject:[baseSource debLine]];
        }
        contents = [contents stringByAppendingString:[debLines componentsJoinedByString:@""]];
        
        NSError *writeError = NULL;
        [contents writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
        
        if (writeError) {
            NSLog(@"[Zebra] Error while writing sources to file: %@", writeError);
            *error = writeError;
        }
    }
}

- (void)writeBaseSources:(NSSet <ZBBaseSource *> *)sources toFile:(NSString *)filePath error:(NSError **_Nullable)error {
    NSMutableArray *debLines = [NSMutableArray new];
    for (ZBBaseSource *baseSource in sources) {
        [debLines addObject:[baseSource debLine]];
    }
    
    NSError *writeError = NULL;
    [[debLines componentsJoinedByString:@""] writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
    if (writeError) {
        NSLog(@"[Zebra] Error while writing sources to file: %@", writeError);
        *error = writeError;
    }
}

#pragma mark - Verifying Sources

- (void)verifySources:(NSSet <ZBBaseSource *> *)sources delegate:(id <ZBSourceVerificationDelegate>)delegate {
    if ([delegate respondsToSelector:@selector(startedSourceVerification:)]) [delegate startedSourceVerification:sources.count > 1];
    
    NSUInteger sourcesToVerify = sources.count;
    NSMutableArray *existingSources = [NSMutableArray new];
    NSMutableArray *imaginarySources = [NSMutableArray new];
    
    for (ZBBaseSource *source in sources) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [source verify:^(ZBSourceVerificationStatus status) {
                if ([delegate respondsToSelector:@selector(source:status:)]) [delegate source:source status:status];
                
                if (status == ZBSourceExists) {
                    [existingSources addObject:source];
                }
                else if (status == ZBSourceImaginary) {
                    [imaginarySources addObject:source];
                }
                
                if ([delegate respondsToSelector:@selector(finishedSourceVerification:imaginarySources:)] && sourcesToVerify == existingSources.count + imaginarySources.count) {
                    [delegate finishedSourceVerification:existingSources imaginarySources:imaginarySources];
                }
            }];
        });
    }
}

#pragma mark - Warnings

- (NSArray <NSError *> *)warningsForSource:(ZBBaseSource *)source {
    NSMutableArray *warnings = [NSMutableArray new];
    if ([source.mainDirectoryURL.scheme isEqual:@"http"] && ![self checkForAncientRepo:source.mainDirectoryURL.host]) {
        NSError *insecureError = [NSError errorWithDomain:ZBSourceErrorDomain code:ZBSourceWarningInsecure userInfo:@{
            NSLocalizedDescriptionKey: NSLocalizedString(@"Insecure Source", @""),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"This repository is being accessed using an insecure scheme (HTTP). Switch to HTTPS to silence this warning.", @""),
        }];
        [warnings addObject:insecureError];
    }
    
    if ([self checkForInvalidRepo:source.mainDirectoryURL]) {
        NSError *insecureError = [NSError errorWithDomain:ZBSourceErrorDomain code:ZBSourceWarningIncompatible userInfo:@{
            NSLocalizedDescriptionKey: NSLocalizedString(@"Incompatible Source", @""),
            NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"This repository has been marked as incompatible with your jailbreak (%@). Installing packages from incompatible sources could result in crashes, inability to manage packages, and loss of jailbreak.", @""), [ZBDevice jailbreakType]], 
        }];
        [warnings addObject:insecureError];
    }
    
    return warnings.count ? warnings : NULL;
}

- (BOOL)checkForAncientRepo:(NSString *)baseURL {
    return [baseURL isEqualToString:@"apt.thebigboss.org"] || [baseURL isEqualToString:@"apt.modmyi.com"] || [baseURL isEqualToString:@"cydia.zodttd.com"] || [baseURL isEqualToString:@"apt.saurik.com"];
}

- (BOOL)checkForInvalidRepo:(NSURL *)baseURL {
    NSString *host = [baseURL host];
    
    if ([ZBDevice isOdyssey]) { // odyssey
        return ([host isEqualToString:@"checkra.in"] || [host isEqualToString:@"apt.saurik.com"] || [host isEqualToString:@"electrarepo64.coolstar.org"] || [host isEqualToString:@"repo.chimera.sh"] || [host isEqualToString:@"apt.bingner.com"]);
    }
    if ([ZBDevice isCheckrain]) { // checkra1n
        return ([host isEqualToString:@"apt.saurik.com"] || [host isEqualToString:@"electrarepo64.coolstar.org"] || [host isEqualToString:@"repo.chimera.sh"] || [host isEqualToString:@"apt.procurs.us"]);
    }
    if ([ZBDevice isChimera]) { // chimera
        return ([host isEqualToString:@"checkra.in"] || [host isEqualToString:@"apt.bingner.com"] || [host isEqualToString:@"apt.saurik.com"] || [host isEqualToString:@"electrarepo64.coolstar.org"] || [host isEqualToString:@"apt.procurs.us"]);
    }
    if ([ZBDevice isUncover]) { // uncover
        return ([host isEqualToString:@"checkra.in"] || [host isEqualToString:@"repo.chimera.sh"] || [host isEqualToString:@"apt.saurik.com"] || [host isEqualToString:@"electrarepo64.coolstar.org"] || [host isEqualToString:@"apt.procurs.us"]);
    }
    if ([ZBDevice isElectra]) { // electra
        return ([host isEqualToString:@"checkra.in"] || [host isEqualToString:@"repo.chimera.sh"] || [host isEqualToString:@"apt.saurik.com"] || [host isEqualToString:@"apt.bingner.com"] || [host isEqualToString:@"apt.procurs.us"]);
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"]) { // cydia
        return ([host isEqualToString:@"checkra.in"] || [host isEqualToString:@"repo.chimera.sh"] || [host isEqualToString:@"electrarepo64.coolstar.org"] || [host isEqualToString:@"apt.bingner.com"] || [host isEqualToString:@"apt.procurs.us"]);
    }
    
    return NO;
}

#pragma mark - Download Delegate

- (void)startedDownloads {
    ZBLog(@"[Zebra](ZBSourceManager) Started downloads");
    
    if (!busyList) busyList = [NSMutableDictionary new];
    if (!completedSources) completedSources = [NSMutableArray new];
    refreshInProgress = YES;
}

- (void)startedDownloadingSource:(ZBBaseSource *)source {
    ZBLog(@"[Zebra](ZBSourceManager) Started downloading %@", source);
    
    [busyList setObject:@YES forKey:source.uuid];
    [self bulkStartedDownloadForSource:source];
}

- (void)progressUpdate:(CGFloat)progress forSource:(ZBBaseSource *)baseSource {
    ZBLog(@"[Zebra](ZBSourceManager) Progress update for %@", baseSource);
}

- (void)finishedDownloadingSource:(ZBBaseSource *)source withError:(NSArray <NSError *> *)errors {
    NSLog(@"[Zebra](ZBSourceManager) Finished downloading %@", source);
    
//    if (source) {
//        [busyList setObject:@NO forKey:source.baseFilename];
//
//        if (errors && errors.count) {
//            source.errors = errors;
//            source.warnings = [self warningsForSource:source];
//        }
//        else {
//            [completedSources addObject:source];
//        }
//
//        [self bulkFinishedDownloadForSource:source];
//    }
    
    NSDate *methodStart = [NSDate date];
    if (source) [self importSource:source];
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"%@ import executionTime = %f", source.label, executionTime);
}

- (void)finishedAllDownloads {
    ZBLog(@"[Zebra](ZBSourceManager) Finished all downloads");
    downloadManager = NULL;
    
//    [databaseManager parseSources:completedSources];
}

- (void)packageUpdatesAvailable:(int)numberOfUpdates {
    [self bulkUpdatesAvailable:numberOfUpdates];
}

- (void)importSource:(ZBBaseSource *)baseSource {
    if (baseSource.remote && baseSource.releaseFilePath) {
        FILE *file = fopen(baseSource.releaseFilePath.UTF8String, "r");
        char line[2048];
        char **source = dualArrayOfSize(ZBSourceColumnCount);
        
        while (fgets(line, 2048, file)) {
            if (line[0] != '\n' && line[0] != '\r') {
                char *key = strtok((char *)line, ":");
                ZBSourceColumn column = [self columnFromString:key];
                if (key && column < ZBSourceColumnCount) {
                    char *value = strtok(NULL, ":");
                    if (value && value[0] == ' ') value++;
                    if (value) strcpy(source[column], trimWhitespaceFromString(value));
                }
            }
        }
        
        strcpy(source[ZBSourceColumnArchiveType], baseSource.archiveType.UTF8String);
        
        const char *components = [baseSource.components componentsJoinedByString:@" "].UTF8String;
        if (components) strcpy(source[ZBSourceColumnComponents], components);
        
        strcpy(source[ZBSourceColumnDistribution], baseSource.distribution.UTF8String);
        
        int remote = baseSource.remote;
        memcpy(source[ZBSourceColumnRemote], &remote, 1);
        
        strcpy(source[ZBSourceColumnURL], baseSource.repositoryURI.UTF8String);
        strcpy(source[ZBSourceColumnUUID], baseSource.uuid.UTF8String);
        
        [databaseManager insertSource:source];
        
        freeDualArrayOfSize(source, ZBSourceColumnCount);
        fclose(file);
    }
    
    [packageManager importPackagesFromSource:baseSource];
}

- (ZBSourceColumn)columnFromString:(char *)string {
    if (strcmp(string, "Author") == 0) {
        return ZBSourceColumnArchitectures;
    } else if (strcmp(string, "Codename") == 0) {
        return ZBSourceColumnCodename;
    } else if (strcmp(string, "Label") == 0) {
        return ZBSourceColumnLabel;
    } else if (strcmp(string, "Origin") == 0) {
        return ZBSourceColumnOrigin;
    } else if (strcmp(string, "Description") == 0) {
        return ZBSourceColumnDescription;
    } else if (strcmp(string, "Suite") == 0) {
        return ZBSourceColumnSuite;
    } else if (strcmp(string, "Version") == 0) {
        return ZBSourceColumnVersion;
    } else {
        return ZBSourceColumnCount;
    }
}

#pragma mark - Reading Pin Priorities

- (NSInteger)pinPriorityForSource:(ZBSource *)source {
    return [self pinPriorityForSource:source strict:NO];
}

- (NSInteger)pinPriorityForSource:(ZBSource *)source strict:(BOOL)strict {
    if (source.sourceID <= 0) return 100;
    
    if ([pinPreferences objectForKey:source.origin]) {
        return [[pinPreferences objectForKey:source.origin] integerValue];
    } else if ([pinPreferences objectForKey:source.label]) {
        return [[pinPreferences objectForKey:source.label] integerValue];
    } else if ([pinPreferences objectForKey:source.codename]) {
        return [[pinPreferences objectForKey:source.codename] integerValue];
    } else if (!strict) {
        return 500;
    } else {
        return 499;
    }
}

- (NSDictionary *)parsePreferences {
    NSMutableDictionary *priorities = [NSMutableDictionary new];
    NSArray *preferences = [self prioritiesForFile:[ZBDevice needsSimulation] ? [[NSBundle mainBundle] pathForResource:@"pin" ofType:@"pref"] : @"/etc/apt/preferences.d/"];
    
    for (NSDictionary *preference in preferences) {
        NSInteger pinPriority = [preference[@"Pin-Priority"] integerValue];
        NSString *pin = preference[@"Pin"];
        if (pin == NULL) continue;
        
        NSRange rangeOfSpace = [pin rangeOfString:@" "];
        NSString *value = rangeOfSpace.location == NSNotFound ? pin : [pin substringToIndex:rangeOfSpace.location];
        NSString *options = rangeOfSpace.location == NSNotFound ? nil :[pin substringFromIndex:rangeOfSpace.location + 1];
        if (!value || !options) continue;
        
        if ([value isEqualToString:@"origin"]) {
            [priorities setValue:@(pinPriority) forKey:options];
        } else if ([value isEqualToString:@"release"]) {
            NSArray *components = [options componentsSeparatedByString:@", "];
            if (components.count == 1 && [options containsString:@","]) components = [options componentsSeparatedByString:@","];
            
            for (NSString *option in components) {
                NSArray *components = [option componentsSeparatedByString:@"="];
                NSArray *choices = @[@"o", @"l", @"n"];
                
                if (components.count == 2 && [choices containsObject:components[0]]) {
                    [priorities setValue:@(pinPriority) forKey:[components[1] stringByReplacingOccurrencesOfString:@"\"" withString:@""]];
                }
            }
        }
    }
    
    return priorities;
}

- (NSArray *)prioritiesForFile:(NSString *)path {
    BOOL isDirectory = NO;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (isDirectory) {
        NSMutableArray *prioritiesForDirectory = [NSMutableArray new];
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
        NSString *directory;
        NSString *file;
        
        if ([path hasSuffix:@"/"]) {
            directory = [path copy];
        } else {
            directory = [path stringByAppendingString:@"/"];
        }

        while (file = [enumerator nextObject]) {
            file = [directory stringByAppendingString:file];
            [prioritiesForDirectory addObjectsFromArray:[self prioritiesForFile:file]];
        }
        return prioritiesForDirectory;
    } else if (fileExists) {
        NSError *readError = NULL;
        NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&readError];
        if (readError) return @[];
        
        NSMutableArray *prioritiesForFile = [NSMutableArray new];
        __block NSMutableDictionary *currentGroup = [NSMutableDictionary new];
        [contents enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            if ([line isEqual:@""]) {
                [prioritiesForFile addObject:currentGroup];
                currentGroup = [NSMutableDictionary new];
            }
            
            NSArray <NSString *> *pair = [line componentsSeparatedByString:@": "];
            if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
            if (pair.count != 2) return;
            NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            NSString *value = [pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            
            [currentGroup setValue:value forKey:key];
        }];
        if (currentGroup.allValues.count) [prioritiesForFile addObject:currentGroup];
        
        return prioritiesForFile;
    }
    
    return @[];
}

#pragma mark - Source Delegate Notifiers

- (void)bulkStartedSourceRefresh {
    for (NSObject <ZBSourceDelegate> *delegate in delegates) {
        if ([delegate respondsToSelector:@selector(startedSourceRefresh)]) {
            [delegate startedSourceRefresh];
        }
    }
}

- (void)bulkStartedDownloadForSource:(ZBBaseSource *)source {
    for (NSObject <ZBSourceDelegate> *delegate in delegates) {
        if ([delegate respondsToSelector:@selector(startedDownloadForSource:)]) {
            [delegate startedDownloadForSource:source];
        }
    }
}

- (void)bulkFinishedDownloadForSource:(ZBBaseSource *)source {
    for (NSObject <ZBSourceDelegate> *delegate in delegates) {
        if ([delegate respondsToSelector:@selector(finishedDownloadForSource:)]) {
            [delegate finishedDownloadForSource:source];
        }
    }
}

- (void)bulkStartedImportForSource:(ZBBaseSource *)source {
    for (NSObject <ZBSourceDelegate> *delegate in delegates) {
        if ([delegate respondsToSelector:@selector(startedImportForSource:)]) {
            [delegate startedImportForSource:source];
        }
    }
}

- (void)bulkFinishedImportForSource:(ZBBaseSource *)source {
    for (NSObject <ZBSourceDelegate> *delegate in delegates) {
        if ([delegate respondsToSelector:@selector(finishedImportForSource:)]) {
            [delegate finishedImportForSource:source];
        }
    }
}

- (void)bulkFinishedSourceRefresh {
    for (NSObject <ZBSourceDelegate> *delegate in delegates) {
        if ([delegate respondsToSelector:@selector(finishedSourceRefresh)]) {
            [delegate finishedSourceRefresh];
        }
    }
}


- (void)bulkAddedSources:(NSSet <ZBBaseSource *> *)sources {
    for (NSObject <ZBSourceDelegate> *delegate in delegates) {
        if ([delegate respondsToSelector:@selector(addedSources:)]) {
            [delegate addedSources:sources];
        }
    }
}

- (void)bulkRemovedSources:(NSSet <ZBBaseSource *> *)sources {
    for (NSObject <ZBSourceDelegate> *delegate in delegates) {
        if ([delegate respondsToSelector:@selector(removedSources:)]) {
            [delegate removedSources:sources];
        }
    }
}

- (void)bulkUpdatesAvailable:(int)numberOfUpdates {
    for (NSObject <ZBSourceDelegate> *delegate in delegates) {
        if ([delegate respondsToSelector:@selector(updatesAvailable:)]) {
            [delegate updatesAvailable:numberOfUpdates];
        }
    }
}

- (void)addDelegate:(id<ZBSourceDelegate>)delegate {
    if (!delegates) delegates = [NSMutableArray new];
    
    [delegates addObject:delegate];
}

- (void)removeDelegate:(id<ZBSourceDelegate>)delegate {
    if (!delegates) return;
    
    [delegates removeObject:delegate];
}

- (void)cancelSourceRefresh {
    // TODO: More things are probably required here
    [downloadManager stopAllDownloads];
}

- (BOOL)isSourceBusy:(ZBBaseSource *)source {
    return [[busyList objectForKey:source.uuid] boolValue];
}

@end
