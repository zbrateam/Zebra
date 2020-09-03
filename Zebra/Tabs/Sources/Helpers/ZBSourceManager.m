//
//  ZBSourceManager.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBSourceManager.h"

#import <Tabs/Sources/Helpers/ZBSource.h>
#import <Database/ZBDatabaseManager.h>
#import <Downloads/ZBDownloadManager.h>
#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <ZBLog.h>
#import <ZBSettings.h>

@import UIKit.UIDevice;

@interface ZBSourceManager () {
    BOOL recachingNeeded;
    ZBDownloadManager *downloadManager;
    NSMutableArray <id <ZBSourceDelegate>> *delegates;
    NSMutableDictionary *busyList;
    NSMutableArray *completedSources;
}
@end

@implementation ZBSourceManager

@synthesize sources = _sources;
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
        recachingNeeded = YES;
        refreshInProgress = NO;
    }
    
    return self;
}

#pragma mark - Accessing Sources

- (NSArray <ZBSource *> *)sources {
    if (!recachingNeeded)
        return _sources;
    
    NSError *readError = NULL;
    NSSet *baseSources = [ZBBaseSource baseSourcesFromList:[ZBAppDelegate sourcesListURL] error:&readError];
    if (readError) {
        ZBLog(@"[Zebra] Error when reading baseSourcse from %@: %@", [ZBAppDelegate sourcesListURL], readError.localizedDescription);
        
        return [NSArray new];
    }
    
    NSSet *sourcesFromDatabase = [[ZBDatabaseManager sharedInstance] sources];
    NSSet *unionSet = [sourcesFromDatabase setByAddingObjectsFromSet:baseSources];
    
    recachingNeeded = NO;
    _sources = [unionSet sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"label" ascending:TRUE selector:@selector(localizedCaseInsensitiveCompare:)]]];
    
    return _sources;
}

- (ZBSource *)sourceMatchingSourceID:(int)sourceID {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sourceID == %d", sourceID];
    NSArray *filteredSources = [_sources filteredArrayUsingPredicate:predicate];
    if (!filteredSources.count) {
        // If we can't find the source in sourceManager, lets just recache and see if it shows up
        // TODO: Recache sources
        filteredSources = [_sources filteredArrayUsingPredicate:predicate];
    }
    
    return filteredSources.firstObject ?: NULL;
}

#pragma mark - Adding and Removing Sources

- (void)addSources:(NSSet <ZBBaseSource *> *)sources error:(NSError **_Nullable)error {
    NSMutableSet *sourcesToAdd = [sources mutableCopy];
    for (ZBSource *source in sources) {
        if ([self.sources containsObject:source]) {
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
        
        recachingNeeded = YES;
        [self bulkAddedSources:sourcesToAdd];
        [self refreshSources:sourcesToAdd useCaching:YES error:nil];
    }
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
                if ([featured objectForKey:[source baseFilename]]) {
                    [featured removeObjectForKey:[source baseFilename]];
                }
                [featured writeToFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"] atomically:NO];
                
                // Delete source and respective packages from database
                [[ZBDatabaseManager sharedInstance] deleteSource:source];
            }
        }
        recachingNeeded = YES;
        [self bulkRemovedSources:sourcesToRemove];
    }
}

- (void)refreshSourcesUsingCaching:(BOOL)useCaching userRequested:(BOOL)requested error:(NSError **_Nullable)error {
    if (refreshInProgress)
        return;
    
    BOOL needsRefresh = NO;
    if (!requested && [ZBSettings wantsAutoRefresh]) {
        NSDate *currentDate = [NSDate date];
        NSDate *lastUpdatedDate = [ZBDatabaseManager lastUpdated];

        if (lastUpdatedDate != NULL) {
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSUInteger unitFlags = NSCalendarUnitMinute;
            NSDateComponents *components = [gregorian components:unitFlags fromDate:lastUpdatedDate toDate:currentDate options:0];

            needsRefresh = ([components minute] >= 30);
        } else {
            needsRefresh = YES;
        }
    }
    
    if (requested || needsRefresh) {
        [self refreshSources:[NSSet setWithArray:self.sources] useCaching:YES error:nil];
    }
}

- (void)refreshSources:(NSSet <ZBBaseSource *> *)sources useCaching:(BOOL)caching error:(NSError **_Nullable)error {
    if (refreshInProgress)
        return;
    
    [self bulkStartedSourceRefresh];
    downloadManager = [[ZBDownloadManager alloc] initWithDownloadDelegate:self];
    [downloadManager downloadSources:sources useCaching:TRUE];
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
        NSMutableArray *debLines = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"\n# Added at %@\n", [NSDate date]]];
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
    
    recachingNeeded = YES;
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
    if ([source.mainDirectoryURL.scheme isEqual:@"http"]) {
        NSError *insecureError = [NSError errorWithDomain:ZBSourceErrorDomain code:ZBSourceWarningInsecure userInfo:@{
            NSLocalizedDescriptionKey: NSLocalizedString(@"Insecure Source", @""),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"This repository is being accessed using an insecure scheme (HTTP).", @""),
        }];
        [warnings addObject:insecureError];
    }
    
    if ([self checkForInvalidRepo:source.mainDirectoryURL.host]) {
        NSError *insecureError = [NSError errorWithDomain:ZBSourceErrorDomain code:ZBSourceWarningIncompatible userInfo:@{
            NSLocalizedDescriptionKey: NSLocalizedString(@"Incompatible Source", @""),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"This repository has been marked as incompatible with your jailbreak (%@). Installing packages from incompatible sources could result in crashes, inability to manage packages, and loss of jailbreak.", @""),
            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Remove this source to remove this warning.", @""),
        }];
        [warnings addObject:insecureError];
    }
    
    return warnings.count ? warnings : NULL;
}

- (BOOL)checkForInvalidRepo:(NSString *)baseURL {
    NSURL *url = [NSURL URLWithString:baseURL];
    NSString *host = [url host];
    
    if ([ZBDevice isOdyssey]) { // odyssey
        return ([host isEqualToString:@"apt.saurik.com"] || [host isEqualToString:@"electrarepo64.coolstar.org"] || [host isEqualToString:@"repo.chimera.sh"] || [host isEqualToString:@"apt.bingner.com"]);
    }
    if ([ZBDevice isCheckrain]) { // checkra1n
        return ([host isEqualToString:@"apt.saurik.com"] || [host isEqualToString:@"electrarepo64.coolstar.org"] || [host isEqualToString:@"repo.chimera.sh"]);
    }
    if ([ZBDevice isChimera]) { // chimera
        return ([host isEqualToString:@"checkra.in"] || [host isEqualToString:@"apt.bingner.com"] || [host isEqualToString:@"apt.saurik.com"] || [host isEqualToString:@"electrarepo64.coolstar.org"]);
    }
    if ([ZBDevice isUncover]) { // uncover
        return ([host isEqualToString:@"checkra.in"] || [host isEqualToString:@"repo.chimera.sh"] || [host isEqualToString:@"apt.saurik.com"] || [host isEqualToString:@"electrarepo64.coolstar.org"]);
    }
    if ([ZBDevice isElectra]) { // electra
        return ([host isEqualToString:@"checkra.in"] || [host isEqualToString:@"repo.chimera.sh"] || [host isEqualToString:@"apt.saurik.com"] || [host isEqualToString:@"apt.bingner.com"]);
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"]) { // cydia
        return ([host isEqualToString:@"checkra.in"] || [host isEqualToString:@"repo.chimera.sh"] || [host isEqualToString:@"electrarepo64.coolstar.org"] || [host isEqualToString:@"apt.bingner.com"]);
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
    
    [busyList setObject:@YES forKey:source.baseFilename];
    [self bulkStartedDownloadForSource:source];
}

- (void)progressUpdate:(CGFloat)progress forSource:(ZBBaseSource *)baseSource {
    ZBLog(@"[Zebra](ZBSourceManager) Progress update for %@", baseSource);
}

- (void)finishedDownloadingSource:(ZBBaseSource *)source withError:(NSArray <NSError *> *)errors {
    NSLog(@"[Zebra](ZBSourceManager) Finished downloading %@", source);
    
    if (source) {
        [busyList setObject:@NO forKey:source.baseFilename];
        
        if (errors && errors.count) {
            source.errors = errors;
            source.warnings = [self warningsForSource:source];
        }
        else {
            [completedSources addObject:source];
        }
        
        [self bulkFinishedDownloadForSource:source];
    }
}

- (void)finishedAllDownloads {
    ZBLog(@"[Zebra](ZBSourceManager) Finished all downloads");
    downloadManager = NULL;
    
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    [databaseManager addDatabaseDelegate:self];
    [databaseManager parseSources:completedSources];
}

#pragma mark - Database Delegate

- (void)databaseStartedUpdate {
    ZBLog(@"[Zebra](ZBSourceManager) Started parsing sources");
}

- (void)startedImportingSource:(ZBBaseSource *)source {
    ZBLog(@"[Zebra](ZBSourceManager) Started parsing %@", source);
    [busyList setObject:@YES forKey:source.baseFilename];
    [self bulkStartedImportForSource:source];
}

- (void)finishedImportingSource:(ZBBaseSource *)source error:(NSError *)error {
    ZBLog(@"[Zebra](ZBSourceManager) Finished parsing %@", source);
//    recachingNeeded = YES;
    [busyList setObject:@NO forKey:source.baseFilename];
    
    if (error) {
        source.errors = source.errors ? [source.errors arrayByAddingObject:error] : @[error];
    }
    source.warnings = [self warningsForSource:source];
    
    [self bulkFinishedImportForSource:source];
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    ZBLog(@"[Zebra](ZBSourceManager) Finished parsing sources");
    refreshInProgress = NO;
    busyList = NULL;
    completedSources = NULL;
    [self bulkFinishedSourceRefresh];
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
    return [[busyList objectForKey:source.baseFilename] boolValue];
}

@end
