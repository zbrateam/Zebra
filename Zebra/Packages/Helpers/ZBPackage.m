//
//  ZBPackage.m
//  Zebra
//
//  Created by Wilson Styres on 2/2/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackage.h"
#import <Parsel/vercmp.h>
#import <Repos/Helpers/ZBRepo.h>
#import <Queue/ZBQueueType.h>
#import <ZBAppDelegate.h>
#import <NSTask.h>
#import <Database/ZBDatabaseManager.h>
#import <Database/ZBColumn.h>

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

+ (NSArray *)filesInstalled:(NSString *)packageID {
    if ([ZBAppDelegate needsSimulation]) {
        return nil;
    }
    NSTask *checkFilesTask = [[NSTask alloc] init];
    [checkFilesTask setLaunchPath:@"/usr/libexec/zebra/supersling"];
    NSArray *filesArgs = [[NSArray alloc] initWithObjects: @"dpkg", @"-L", packageID, nil];
    [checkFilesTask setArguments:filesArgs];
    
    NSPipe *outPipe = [NSPipe pipe];
    [checkFilesTask setStandardOutput:outPipe];
    
    [checkFilesTask launch];
    [checkFilesTask waitUntilExit];
    
    NSFileHandle *read = [outPipe fileHandleForReading];
    NSData *dataRead = [read readDataToEndOfFile];
    NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    
    return [stringRead componentsSeparatedByString:@"\n"];
}

+ (BOOL)containsTweak:(NSString *)packageID {
    NSLog(@"[Zebra] Searching %@ for tweak", packageID);
    if ([ZBAppDelegate needsSimulation]) {
        return true;
    }
    if ([packageID hasSuffix:@".deb"]) {
        NSLog(@"[Zebra] Tring to find package id");
        //do the ole dpkg -I
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/libexec/zebra/supersling"];
        [task setArguments:@[@"/usr/bin/dpkg", @"-I", packageID, @"control"]];
        
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput:pipe];
        
        [task launch];
        [task waitUntilExit];
        
        NSFileHandle *read = [pipe fileHandleForReading];
        NSData *dataRead = [read readDataToEndOfFile];
        NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
        
        __block BOOL contains;
        [stringRead enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
            if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
            if (pair.count != 2) return;
            NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            NSLog(@"[Zebra] %@", pair);
            if ([key isEqualToString:@"Package"]) {
                contains = [self containsTweak:[pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]];
                return;
            }
        }];
        
        return contains;
    }
    
    NSArray *files = [self filesInstalled:packageID];
    
    for (NSString *path in files) {
        if ([path rangeOfString:@"/Library/MobileSubstrate/DynamicLibraries"].location != NSNotFound) {
            if ([path rangeOfString:@".dylib"].location != NSNotFound) {
                return true;
            }
        }
    }
    return false;
}

+ (BOOL)containsApp:(NSString *)packageID {
    NSLog(@"[Zebra] Searching %@ for app bundle", packageID);
    if ([ZBAppDelegate needsSimulation]) {
        return true;
    }
    if ([packageID hasSuffix:@".deb"]) {
        NSLog(@"[Zebra] Tring to find package id");
        //do the ole dpkg -I
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/libexec/zebra/supersling"];
        [task setArguments:@[@"/usr/bin/dpkg", @"-I", packageID, @"control"]];
        
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput:pipe];
        
        [task launch];
        [task waitUntilExit];
        
        NSFileHandle *read = [pipe fileHandleForReading];
        NSData *dataRead = [read readDataToEndOfFile];
        NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
        
        __block BOOL contains;
        [stringRead enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
            if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
            if (pair.count != 2) return;
            NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            NSLog(@"[Zebra] %@", pair);
            if ([key isEqualToString:@"Package"]) {
                contains = [self containsApp:[pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]];
                return;
            }
        }];
        
        return contains;
    }
    
    NSArray *files = [self filesInstalled:packageID];
    
    for (NSString *path in files) {
        if ([path rangeOfString:@".app/Info.plist"].location != NSNotFound) {
            return true;
        }
    }
    return false;
}

+ (NSString *)pathForApplication:(NSString *)packageID {
    if ([packageID hasSuffix:@".deb"]) {
        //do the ole dpkg -I
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/libexec/zebra/supersling"];
        [task setArguments:@[@"/usr/bin/dpkg", @"-I", packageID, @"control"]];
        
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput:pipe];
        
        [task launch];
        [task waitUntilExit];
        
        NSFileHandle *read = [pipe fileHandleForReading];
        NSData *dataRead = [read readDataToEndOfFile];
        NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
        
        __block NSString *path;
        [stringRead enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
            if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
            if (pair.count != 2) return;
            NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            if ([key isEqualToString:@"Package"]) {
                path = [self pathForApplication:[pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]];
                return;
            }
        }];
        
        return path;
    }
    
    NSArray *files = [self filesInstalled:packageID];
    
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
        
        [self setIdentifier:[NSString stringWithUTF8String:packageIDChars]]; //This should never be NULL
        [self setName:[NSString stringWithUTF8String:packageNameChars]]; //This should never be NULL
        [self setVersion:[NSString stringWithUTF8String:versionChars]]; //This should never be NULL
        [self setShortDescription:shortDescriptionChars != 0 ? [NSString stringWithUTF8String:shortDescriptionChars] : NULL];
        [self setLongDescription:longDescriptionChars != 0 ? [NSString stringWithUTF8String:longDescriptionChars] : NULL];
        [self setSection:sectionChars != 0 ? [NSString stringWithUTF8String:sectionChars] : NULL];
        [self setDepictionURL:depictionChars != 0 ? [NSURL URLWithString:[NSString stringWithUTF8String:depictionChars]] : NULL];
        [self setAuthor:authorChars != 0 ? [NSString stringWithUTF8String:authorChars] : NULL];
        [self setFilename:filenameChars != 0 ? [NSString stringWithUTF8String:filenameChars] : NULL];
        [self setIconPath:iconChars != 0 ? [NSString stringWithUTF8String:iconChars] : NULL];
        
        [self setTags:tagChars != 0 ? [[NSString stringWithUTF8String:tagChars] componentsSeparatedByString:@", "] : NULL];
        if ([tags count] == 1 && [tags[0] containsString:@","]) { //Fix crimes against humanity @Dnasty
            tags = [tags[0] componentsSeparatedByString:@","];
        }
        
        [self setDependsOn:dependsChars != 0 ? [[NSString stringWithUTF8String:dependsChars] componentsSeparatedByString:@", "] : NULL];
        if ([dependsOn count] == 1 && [dependsOn[0] containsString:@","]) { //Fix crimes against humanity @Dnasty
            dependsOn = [dependsOn[0] componentsSeparatedByString:@","];
        }
        
        [self setConflictsWith:conflictsChars != 0 ? [[NSString stringWithUTF8String:conflictsChars] componentsSeparatedByString:@", "] : NULL];
        if ([conflictsWith count] == 1 && [conflictsWith[0] containsString:@","]) { //Fix crimes against humanity @Dnasty
            conflictsWith = [conflictsWith[0] componentsSeparatedByString:@","];
        }
        
        [self setProvides:providesChars != 0 ? [[NSString stringWithUTF8String:providesChars] componentsSeparatedByString:@", "] : NULL];
        if ([provides count] == 1 && [provides[0] containsString:@","]) { //Fix crimes against humanity @Dnasty
            provides = [provides[0] componentsSeparatedByString:@","];
        }
        
        [self setProvides:replacesChars != 0 ? [[NSString stringWithUTF8String:replacesChars] componentsSeparatedByString:@", "] : NULL];
        if ([replaces count] == 1 && [replaces[0] containsString:@","]) { //Fix crimes against humanity @Dnasty
            replaces = [replaces[0] componentsSeparatedByString:@","];
        }
        
        int repoID = sqlite3_column_int(statement, ZBPackageColumnRepoID);
        if (repoID > 0) {
            [self setRepo:[ZBRepo repoMatchingRepoID:repoID]];
        }
        else {
            [self setRepo:[ZBRepo localRepo]];
        }
        
        NSString *sectionStripped = [section stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        if ([section characterAtIndex:[section length] - 1] == ')') {
            NSArray *items = [section componentsSeparatedByString:@"("]; //Remove () from section
            sectionStripped = [items[0] substringToIndex:[items[0] length] - 1];
        }
        [self setSectionImageName:sectionStripped];
    }
    
    return self;
}

- (BOOL)isEqual:(ZBPackage *)object {
    if (self == object)
        return TRUE;
    
    if (![object isKindOfClass:[ZBPackage class]])
        return FALSE;
    
    return ([[object identifier] isEqual:[self identifier]] && [[object version] isEqual:[self version]]);
}

- (BOOL)sameAs:(ZBPackage *)package {
    return [[self identifier] isEqualToString:[package identifier]];
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
        else
            return NSOrderedDescending;
    }
    else {
        int result = compare([[self version] UTF8String], [(NSString *)object UTF8String]);
        if (result < 0)
            return NSOrderedAscending;
        else if (result > 0)
            return NSOrderedDescending;
        else
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
    
    NSError *readError;
    NSString *contents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&readError];
    
    if (readError != NULL) {
        NSLog(@"Error: %@", readError);
        
        return readError.localizedDescription;
    }
    
    NSString *packageIdentifier = [[self identifier] stringByAppendingString:@"\n"];
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

- (int)numericSize {
    NSString *sizeField = [self getField:@"Size"];
    if (!sizeField) return 0;
    return [sizeField intValue];
}

- (NSString *)size {
    int numericSize = [self numericSize];
    if (!numericSize) return NULL;
    double size = (double)numericSize;
    if (size > 1024 * 1024) {
        return [NSString stringWithFormat:@"%.2f MB", size / 1024 / 1024];
    }
    if (size > 1024) {
        return [NSString stringWithFormat:@"%.2f KB", size / 1024];
    }
    return [NSString stringWithFormat:@"%d bytes", numericSize];
}

- (int)numericInstalledSize {
    NSString *sizeField = [self getField:@"Installed-Size"];
    if (!sizeField) return 0;
    return [sizeField intValue];
}

- (NSString *)installedSize {
    int numericSize = [self numericInstalledSize];
    if (!numericSize) return NULL;
    double size = (double)numericSize;
    if (size > 1024) {
        return [NSString stringWithFormat:@"%.2f MB", size / 1024];
    }
    return [NSString stringWithFormat:@"%d KB", numericSize];
}

- (BOOL)isInstalled:(BOOL)strict {
    if ([repo repoID] <= 0) { //Package is in repoID 0 or -1 and is installed
        return true;
    }
    else {
        ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
        return [databaseManager packageIsInstalled:self versionStrict:strict];
    }
}

- (BOOL)isReinstallable {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    return [databaseManager packageIsAvailable:self versionStrict:true];
}

- (NSArray <ZBPackage *> *)otherVersions {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    NSMutableArray *versions = [NSMutableArray arrayWithArray:[databaseManager allVersionsForPackage:self]];
    [versions removeObject:self];
    return versions;
}

- (NSUInteger)possibleActions {
    NSUInteger actions = 0;
    // Bits order: Select Ver. - Upgrade - Reinstall - Remove - Install
    if ([self isInstalled:false]) {
        ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
        if ([self isReinstallable]) {
            actions |= ZBQueueTypeReinstall; // Reinstall
        }
        if ([databaseManager packageHasUpdate:self]) {
            // A package update is even possible for a package installed from repo A, repo A got deleted, and an update comes from repo B
            actions |= ZBQueueTypeUpgrade; // Upgrade
        }
        actions |= ZBQueueTypeRemove; // Remove
    }
    else {
        actions |= ZBQueueTypeInstall; // Install
    }
    NSArray *otherVersions = [self otherVersions];
    if (otherVersions.count) {
        // Calculation of otherVersions will ignore local packages and packages of the same version as the current one
        // Therefore, there will only be packages of the same identifier but different version, though not necessarily downgrades
        actions |= ZBQueueTypeSelectable; // Select other versions
    }
    return actions;
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
}

- (ZBPackage *)installableCandidate {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    return [databaseManager packageForID:[self identifier] thatSatisfiesComparison:@"<=" ofVersion:[self version] checkInstalled:false checkProvides:true];
}

- (NSDate *)installedDate {
	NSString *listPath = [NSString stringWithFormat:@"/var/lib/dpkg/info/%@.list", self.identifier];
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:listPath error:NULL];
	return attributes[NSFileModificationDate];
}

@end
