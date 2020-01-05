//
//  ZBPackage.m
//  Zebra
//
//  Created by Wilson Styres on 2/2/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackage.h"
#import <ZBLog.h>
#import <ZBDevice.h>
#import <Parsel/vercmp.h>
#import <Repos/Helpers/ZBRepo.h>
#import <Queue/ZBQueueType.h>
#import <ZBAppDelegate.h>
#import <NSTask.h>
#import <Database/ZBDatabaseManager.h>
#import <Database/ZBColumn.h>

@import Crashlytics;

@interface ZBPackage () {
    NSUInteger possibleActions;
}
@end

@implementation ZBPackage

@synthesize identifier;
@synthesize name;
@synthesize version;
@synthesize shortDescription;
@synthesize longDescription;
@synthesize section;
@synthesize sectionImageName;
@synthesize depictionURL;
@synthesize tags;
@synthesize dependsOn;
@synthesize conflictsWith;
@synthesize provides;
@synthesize replaces;
@synthesize author;
@synthesize repo;
@synthesize filename;
@synthesize debPath;
@synthesize dependencies;
@synthesize dependencyOf;
@synthesize issues;
@synthesize removedBy;
@synthesize installedSize;
@synthesize downloadSize;
@synthesize priority;
@synthesize essential;
@synthesize ignoreDependencies;

+ (NSArray *)filesInstalledBy:(NSString *)packageID {
    ZBLog(@"[Zebra] Getting installed files for %@", packageID);
    if ([ZBDevice needsSimulation]) {
        return @[@"/.", @"/You", @"/You/Are", @"/You/Are/Simulated"];
    }
    
    NSString *path = [NSString stringWithFormat:@"/Library/dpkg/info/%@.list", packageID];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *readError;
        NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&readError];
        if (!readError) {
            return [contents componentsSeparatedByString:@"\n"];
        }
        else {
            return @[readError.localizedDescription];
        }
    }
    else {
        return @[@"No files found"];
    }
}

+ (BOOL)respringRequiredFor:(NSString *)packageID {
    if ([ZBDevice needsSimulation]) {
        return NO;
    }
    
    ZBLog(@"[Zebra] Searching %@ for respringable", packageID);
    if ([packageID hasSuffix:@".deb"]) {
        ZBLog(@"[Zebra] Locating package ID for %@", packageID);
        //We need to look up the *actual* package ID of this deb from the deb's control file
        NSMutableData *output = [NSMutableData new];
        NSTask *locatePackage = [[NSTask alloc] init];
        [locatePackage setLaunchPath:@"/usr/bin/dpkg"]; //not sure this needs root but we'll leave it for now
        [locatePackage setArguments:@[@"-I", packageID, @"control"]];
        
        locatePackage.standardOutput = [NSPipe pipe];
        [[locatePackage.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
            NSData *data = [file availableData];
            [output appendData:data];
        }];
        
        @try {
            [locatePackage launch];
            [locatePackage waitUntilExit];
            [locatePackage.standardOutput fileHandleForReading].readabilityHandler = nil;
            
            NSString *stringRead = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
            __block BOOL contains = NO;
            [stringRead enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
                if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
                if (pair.count != 2) return;
                NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                if ([key isEqualToString:@"Package"]) {
                    NSString *value = [pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                    ZBLog(@"[Zebra] Package ID found %@", value);
                    contains = [self respringRequiredFor:value];
                    *stop = YES;
                }
            }];
            
            return contains;
        }
        @catch (NSException *e) {
            CLS_LOG(@"%@ Could not spawn dpkg. Reason: %@", e.name, e.reason);
            NSLog(@"[Zebra] %@ Could not spawn dpkg. Reason: %@", e.name, e.reason);
            
            return NO;
        }
    }
    
    NSArray *files = [self filesInstalledBy:packageID];
    
    for (NSString *path in files) {
        // Usual tweaks
        if ([path rangeOfString:@"/Library/MobileSubstrate/DynamicLibraries"].location != NSNotFound && [path hasSuffix:@".dylib"]) {
            return YES;
        }
        // CC bundles
        if ([path rangeOfString:@"/Library/ControlCenter/Bundles"].location != NSNotFound && [path hasSuffix:@".bundle"]) {
            return YES;
        }
        // Flipswitch bundles
        if ([path rangeOfString:@"/Library/Switches"].location != NSNotFound && [path hasSuffix:@".bundle"]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)containsApplicationBundle:(NSString *)packageID {
    if ([ZBDevice needsSimulation]) {
        return NO;
    }
    
    ZBLog(@"[Zebra] Searching %@ for app bundle", packageID);
    if ([packageID hasSuffix:@".deb"]) {
        ZBLog(@"[Zebra] Locating package ID for %@", packageID);
        //We need to look up the *actual* package ID of this deb from the deb's control file
        NSMutableData *output = [NSMutableData new];
        NSTask *locatePackage = [[NSTask alloc] init];
        [locatePackage setLaunchPath:@"/usr/bin/dpkg"]; //not sure if root is needed but we'll leave it for now
        [locatePackage setArguments:@[@"-I", packageID, @"control"]];
        
        locatePackage.standardOutput = [NSPipe pipe];
        [[locatePackage.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
            NSData *data = [file availableData];
            [output appendData:data];
        }];
        
        @try {
            [locatePackage launch];
            [locatePackage waitUntilExit];
            [locatePackage.standardOutput fileHandleForReading].readabilityHandler = nil;
            
            NSString *stringRead = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
            __block BOOL contains = NO;
            [stringRead enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
                if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
                if (pair.count != 2) return;
                NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                if ([key isEqualToString:@"Package"]) {
                    NSString *value = [pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                    ZBLog(@"[Zebra] Package ID found %@", value);
                    contains = [self containsApplicationBundle:value];
                    *stop = YES;
                }
            }];
            
            return contains;
        }
        @catch (NSException *e) {
            CLS_LOG(@"%@ Could not spawn dpkg. Reason: %@", e.name, e.reason);
            NSLog(@"[Zebra] %@ Could not spawn dpkg. Reason: %@", e.name, e.reason);
            
            return NO;
        }
    }
    
    NSArray *files = [self filesInstalledBy:packageID];
    
    for (NSString *path in files) {
        if ([path containsString:@".app/Info.plist"]) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)pathForApplication:(NSString *)packageID {
    if ([ZBDevice needsSimulation]) {
        return NULL;
    }
    
    ZBLog(@"[Zebra] Searching %@ for app path", packageID);
    if ([packageID hasSuffix:@".deb"]) {
        ZBLog(@"[Zebra] Locating package ID for %@", packageID);
        //We need to look up the *actual* package ID of this deb from the deb's control file
        NSMutableData *output = [NSMutableData new];
        NSTask *locatePackage = [[NSTask alloc] init];
        [locatePackage setLaunchPath:@"/usr/bin/dpkg"]; //not sure if root is needed but we'll leave it for now
        [locatePackage setArguments:@[@"-I", packageID, @"control"]];
        
        locatePackage.standardOutput = [NSPipe pipe];
        [[locatePackage.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
            NSData *data = [file availableData];
            [output appendData:data];
        }];
        
        @try {
            [locatePackage launch];
            [locatePackage waitUntilExit];
            [locatePackage.standardOutput fileHandleForReading].readabilityHandler = nil;
            
            NSString *stringRead = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
            __block NSString *path;
            [stringRead enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
                if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
                if (pair.count != 2) return;
                NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                if ([key isEqualToString:@"Package"]) {
                    NSString *value = [pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                    ZBLog(@"[Zebra] Package ID found %@", value);
                    path = [self pathForApplication:value];
                    *stop = YES;
                }
            }];
            
            return path;
        }
        @catch (NSException *e) {
            CLS_LOG(@"%@ Could not spawn dpkg. Reason: %@", e.name, e.reason);
            NSLog(@"[Zebra] %@ Could not spawn dpkg. Reason: %@", e.name, e.reason);
            
            return NULL;
        }
    }
    
    NSArray *files = [self filesInstalledBy:packageID];
    
    NSString *appPath;
    for (NSString *path in files) {
        if ([path rangeOfString:@".app/Info.plist"].location != NSNotFound) {
            appPath = path;
            break;
        }
    }
    return appPath != NULL ? [appPath stringByDeletingLastPathComponent] : NULL;
}

- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name version:(NSString *)version description:(NSString *)desc section:(NSString *)section depictionURL:(NSString *)url {
    
    self = [super init];
    
    if (self) {
        [self setIdentifier:identifier];
        [self setName:name];
        [self setVersion:version];
        [self setShortDescription:desc];
        [self setSection:section];
        [self setDepictionURL:[NSURL URLWithString:url]];
    }
    
    return self;
}

+ (NSCharacterSet *)delimiters {
    static NSCharacterSet *charSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        charSet = [NSCharacterSet characterSetWithCharactersInString:@","];
    });
    return charSet;
}

- (NSArray *)extract:(const char *)packages_ {
    NSCharacterSet *delimiters = [[self class] delimiters];
    NSArray *packages = packages_ != 0 ? [[NSString stringWithUTF8String:packages_] componentsSeparatedByCharactersInSet:delimiters] : NULL;
    if (packages) {
        NSMutableArray *finalPackages = [NSMutableArray array];
        for (NSString *line in packages) {
            [finalPackages addObject:[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
        return finalPackages;
    }
    return packages;
}

- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement {
    self = [super init];
    
    if (self) {
        const char *packageIDChars =        (const char *)sqlite3_column_text(statement, ZBPackageColumnPackage);
        const char *packageNameChars =      (const char *)sqlite3_column_text(statement, ZBPackageColumnName);
        const char *versionChars =          (const char *)sqlite3_column_text(statement, ZBPackageColumnVersion);
        const char *shortDescriptionChars = (const char *)sqlite3_column_text(statement, ZBPackageColumnShortDescription);
        const char *longDescriptionChars =  (const char *)sqlite3_column_text(statement, ZBPackageColumnLongDescription);
        const char *sectionChars =          (const char *)sqlite3_column_text(statement, ZBPackageColumnSection);
        const char *depictionChars =        (const char *)sqlite3_column_text(statement, ZBPackageColumnDepiction);
        const char *tagChars =              (const char *)sqlite3_column_text(statement, ZBPackageColumnTag);
        const char *authorChars =           (const char *)sqlite3_column_text(statement, ZBPackageColumnAuthor);
        const char *dependsChars =          (const char *)sqlite3_column_text(statement, ZBPackageColumnDepends);
        const char *conflictsChars =        (const char *)sqlite3_column_text(statement, ZBPackageColumnConflicts);
        const char *providesChars =         (const char *)sqlite3_column_text(statement, ZBPackageColumnProvides);
        const char *replacesChars =         (const char *)sqlite3_column_text(statement, ZBPackageColumnReplaces);
        const char *filenameChars =         (const char *)sqlite3_column_text(statement, ZBPackageColumnFilename);
        const char *iconChars =             (const char *)sqlite3_column_text(statement, ZBPackageColumnIconURL);
        const char *priorityChars =         (const char *)sqlite3_column_text(statement, ZBPackageColumnPriority);
        const char *essentialChars =        (const char *)sqlite3_column_text(statement, ZBPackageColumnEssential);
        sqlite3_int64 lastSeen =            sqlite3_column_int64(statement, ZBPackageColumnLastSeen);
        
        [self setIdentifier:[NSString stringWithUTF8String:packageIDChars]]; // This should never be NULL
        [self setName:packageNameChars != 0 ? [NSString stringWithUTF8String:packageNameChars] : (self.identifier ?: @"Unknown")]; // fall back to ID if NULL, or Unknown if things get worse
        [self setVersion:versionChars != 0 ? [NSString stringWithUTF8String:versionChars] : NULL];
        [self setShortDescription:shortDescriptionChars != 0 ? [NSString stringWithUTF8String:shortDescriptionChars] : NULL];
        [self setLongDescription:longDescriptionChars != 0 ? [NSString stringWithUTF8String:longDescriptionChars] : NULL];
        [self setSection:sectionChars != 0 ? [NSString stringWithUTF8String:sectionChars] : NULL];
        [self setDepictionURL:depictionChars != 0 ? [NSURL URLWithString:[NSString stringWithUTF8String:depictionChars]] : NULL];
        [self setAuthor:authorChars != 0 ? [NSString stringWithUTF8String:authorChars] : NULL];
        [self setFilename:filenameChars != 0 ? [NSString stringWithUTF8String:filenameChars] : NULL];
        [self setIconPath:iconChars != 0 ? [NSString stringWithUTF8String:iconChars] : NULL];
        
        [self setPriority:priorityChars != 0 ? [NSString stringWithUTF8String:priorityChars] : NULL];
        
        NSString *es = essentialChars != 0 ? [[NSString stringWithUTF8String:essentialChars] lowercaseString] : NULL;
        if (es && [es isEqualToString:@"yes"]) {
            [self setEssential:true];
        }
        else if (es && [es isEqualToString:@"no"]) {
            [self setEssential:false];
        }
        
        [self setTags:tagChars != 0 ? [[NSString stringWithUTF8String:tagChars] componentsSeparatedByString:@", "] : NULL];
        if ([tags count] == 1 && [tags[0] containsString:@","]) { // Fix crimes against humanity @Dnasty
            tags = [tags[0] componentsSeparatedByString:@","];
        }
        
        [self setDependsOn:[self extract:dependsChars]];
        [self setConflictsWith:[self extract:conflictsChars]];
        [self setProvides:[self extract:providesChars]];
        [self setReplaces:[self extract:replacesChars]];
        
        int repoID = sqlite3_column_int(statement, ZBPackageColumnRepoID);
        if (repoID > 0) {
            [self setRepo:[ZBRepo repoMatchingRepoID:repoID]];
        } else {
            [self setRepo:[ZBRepo localRepo:repoID]];
        }
        
        NSString *sectionStripped = [section stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        if ([section characterAtIndex:[section length] - 1] == ')') {
            NSArray *items = [section componentsSeparatedByString:@"("]; // Remove () from section
            sectionStripped = [items[0] substringToIndex:[items[0] length] - 1];
        }
        [self setSectionImageName:sectionStripped];
        [self setLastSeenDate:lastSeen ? [NSDate dateWithTimeIntervalSince1970:lastSeen] : [NSDate date]];
        [self setInstalledSize:sqlite3_column_int(statement, ZBPackageColumnInstalledSize)];
        [self setDownloadSize:sqlite3_column_int(statement, ZBPackageColumnDownloadSize)];
    }
    
    return self;
}

- (BOOL)isEqual:(ZBPackage *)object {
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:[ZBPackage class]])
        return NO;
    
    return ([[object identifier] isEqual:self.identifier] && [[object version] isEqual:[self version]]);
}

- (BOOL)sameAs:(ZBPackage *)package {
    return [self.identifier isEqualToString:package.identifier];
}

- (BOOL)sameAsStricted:(ZBPackage *)package {
    return [self sameAs:package] && [[self version] isEqualToString:package.version];
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ (%@) V%@", name, identifier, version];
}

- (NSComparisonResult)compare:(id)object {
    if ([object isKindOfClass:[ZBPackage class]]) {
        ZBPackage *obj = (ZBPackage *)object;
        if ([self isEqual:obj])
            return NSOrderedSame;
        
        if (compare([[self version] UTF8String], [[obj version] UTF8String]) < 0)
            return NSOrderedAscending;
        return NSOrderedDescending;
    } else {
        if ((NSString *)object == NULL) return NSOrderedDescending;
        int result = compare([[self version] UTF8String], [(NSString *)object UTF8String]);
        if (result < 0)
            return NSOrderedAscending;
        if (result > 0)
            return NSOrderedDescending;
        return NSOrderedSame;
    }
}

- (BOOL)isPaid {
    return [tags containsObject:@"cydia::commercial"];
}

- (NSString *)getField:(NSString *)field {
    NSString *value;
    
    ZBRepo *repo = [self repo];
    
    if (repo == NULL) return NULL;
    
    NSString *listsLocation = [ZBAppDelegate listsLocation];
    NSString *filename = [NSString stringWithFormat:@"%@/%@%@", listsLocation, [repo baseFileName], @"_Packages"];
    NSFileManager *filemanager = [NSFileManager defaultManager];
    
    if (![filemanager fileExistsAtPath:filename]) {
        filename = [NSString stringWithFormat:@"%@/%@%@", listsLocation, [repo baseFileName], @"_main_binary-iphoneos-arm_Packages"];
        
        if (![filemanager fileExistsAtPath:filename]) {
            return NULL;
        }
    }
    
    NSError *readError = NULL;
    NSString *contents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&readError];
    
    if (readError != NULL) {
        NSLog(@"[Zebra] Error getting package field (%@): %@", field, readError);
        
        return readError.localizedDescription;
    }
    
    NSString *packageIdentifier = [self.identifier stringByAppendingString:@"\n"];
    NSString *packageVersion = [[self version] stringByAppendingString:@"\n"];
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:contents];
    [scanner scanUpToString:packageIdentifier intoString:NULL];
    [scanner scanUpToString:packageVersion intoString:NULL];
    NSString *packageInfo;
    [scanner scanUpToString:@"\n\n" intoString:&packageInfo];
    if (packageInfo == NULL) return NULL;
    scanner = [[NSScanner alloc] initWithString:packageInfo];
    do {
        [scanner scanUpToString:[field stringByAppendingString:@": "] intoString:NULL];
        if ([scanner isAtEnd])
            break;
        ++scanner.scanLocation;
    } while ([packageInfo characterAtIndex:scanner.scanLocation - 2] != '\n');
    [scanner scanUpToString:@"\n" intoString:&value];
    
    return [[value componentsSeparatedByString:@": "] objectAtIndex:1];
}

- (NSString *)downloadSizeString {
    if (downloadSize <= 0) return NULL;
    double size = (double)downloadSize;
    if (size > 1024 * 1024) {
        return [NSString stringWithFormat:NSLocalizedString(@"%.2f MB", @""), size / 1024 / 1024];
    }
    if (size > 1024) {
        return [NSString stringWithFormat:NSLocalizedString(@"%.2f KB", @""), size / 1024];
    }
    return [NSString stringWithFormat:NSLocalizedString(@"%d bytes", @""), downloadSize];
}

- (NSString *)installedSizeString {
    if (installedSize <= 0) return NULL;
    double size = (double)installedSize;
    if (size > 1024) {
        return [NSString stringWithFormat:NSLocalizedString(@"%.2f MB", @""), size / 1024];
    }
    return [NSString stringWithFormat:NSLocalizedString(@"%d KB", @""), installedSize];
}

- (BOOL)isInstalled:(BOOL)strict {
    if ([repo repoID] <= 0) { // Package is in repoID 0 or -1 and is installed
        return YES;
    }
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    return [databaseManager packageIsInstalled:self versionStrict:strict];
}

- (BOOL)isReinstallable {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    return [databaseManager packageIsAvailable:self versionStrict:YES];
}

- (NSArray <ZBPackage *> *)otherVersions {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    NSMutableArray *versions = [NSMutableArray arrayWithArray:[databaseManager allVersionsForPackage:self]];
    [versions removeObject:self];
    
    return versions;
}

- (NSArray <ZBPackage *> *)lesserVersions {
    NSMutableArray *versions = [[self otherVersions] mutableCopy];
    NSMutableArray *lesserVersions = [versions mutableCopy];
    for (ZBPackage *package in versions) {
        if ([self compare:package] == NSOrderedAscending) {
            [lesserVersions removeObject:package];
        }
    }
    
    return lesserVersions;
}

- (NSArray <ZBPackage *> *)greaterVersions {
    NSMutableArray *versions = [[self otherVersions] mutableCopy];
    NSMutableArray *greaterVersions = [versions mutableCopy];
    for (ZBPackage *package in versions) {
        if ([self compare:package] == NSOrderedDescending) {
            [greaterVersions removeObject:package];
        }
    }
    
    return greaterVersions;
}

- (NSUInteger)possibleActions {
    if (self.repo.repoID == -1) {
        // We do nothing with virtual dependencies
        return 0;
    }
    if (possibleActions == 0) {
        // Bits order: Select Ver. - Upgrade - Reinstall - Remove - Install
        if ([self isInstalled:NO]) {
            ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
            if ([self isReinstallable]) {
                possibleActions |= ZBQueueTypeReinstall; // Reinstall
            }
            if ([databaseManager packageHasUpdate:self]) {
                // A package update is even possible for a package installed from repo A, repo A got deleted, and an update comes from repo B
                possibleActions |= ZBQueueTypeUpgrade; // Upgrade
            }
            possibleActions |= ZBQueueTypeRemove; // Remove
        } else {
            possibleActions |= ZBQueueTypeInstall; // Install
        }
        NSArray *otherVersions = [self otherVersions];
        if (otherVersions.count) {
            // Calculation of otherVersions will ignore local packages and packages of the same version as the current one
            // Therefore, there will only be packages of the same identifier but different version, though not necessarily downgrades
            possibleActions |= ZBQueueTypeDowngrade; // Select other versions
        }
    }
    return possibleActions;
}

- (NSString *)longDescription {
    return longDescription == NULL ? shortDescription : longDescription;
}

- (BOOL)ignoreUpdates {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    return [databaseManager areUpdatesIgnoredForPackage:self];
}

- (void)setIgnoreUpdates:(BOOL)ignore {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    [databaseManager setUpdatesIgnored:ignore forPackage:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
}

- (ZBPackage *)installableCandidate {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    ZBPackage *candidate = [databaseManager packageForIdentifier:self.identifier thatSatisfiesComparison:@"<=" ofVersion:[self version]];
    
    return candidate;
}

- (ZBPackage *)removeableCandidate {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    ZBPackage *candidate = [databaseManager installedPackageForIdentifier:self.identifier thatSatisfiesComparison:@"<=" ofVersion:[self version]];
    
    return candidate;
}

- (NSDate *)installedDate {
    if ([ZBDevice needsSimulation]) {
        // Just to make sections in simulators less cluttered
        // https://stackoverflow.com/questions/1149256/round-nsdate-to-the-nearest-5-minutes/19123570
        NSTimeInterval seconds = round([[NSDate date] timeIntervalSinceReferenceDate] / 300.0) * 300.0;
        return [NSDate dateWithTimeIntervalSinceReferenceDate:seconds];
    }
	NSString *listPath = [NSString stringWithFormat:@"/var/lib/dpkg/info/%@.list", self.identifier];
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:listPath error:NULL];
	return attributes[NSFileModificationDate];
}

- (NSString *)installedVersion {
    NSString *installedVersion = [[ZBDatabaseManager sharedInstance] installedVersionForPackage:self];
    
    if ([self.version isEqualToString:installedVersion]) return NULL;
    return installedVersion;
}

- (void)addDependency:(ZBPackage *)package {
    if (!dependencies) dependencies = [NSMutableArray new];
    
    if (![dependencies containsObject:package]) {
        [dependencies addObject:package];
    }
}

- (void)addDependencyOf:(ZBPackage *)package {
    if (!dependencyOf) dependencyOf = [NSMutableArray new];
    
    if (![dependencyOf containsObject:package]) {
        [dependencyOf addObject:package];
    }
}

- (void)addIssue:(NSString *)issue {
    if (!issues) issues = [NSMutableArray new];
    
    [issues addObject:issue];
}

- (BOOL)hasIssues {
    return [issues count];
}

- (BOOL)isEssentialOrRequired {
    return essential || [[priority lowercaseString] isEqualToString:@"required"];
}

@end
