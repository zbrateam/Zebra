//
//  ZBPackage.m
//  Zebra
//
//  Created by Wilson Styres on 2/2/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackage.h"
#import "ZBPackageActions.h"

#import "ZBLog.h"
#import "ZBDevice.h"
#import "ZBUtils.h"
#import "vercmp.h"
#import "ZBSource.h"
#import "ZBPaymentVendor.h"
#import "ZBAppDelegate.h"
#import "ZBDatabaseManager.h"
#import "ZBColumn.h"
#import "ZBQueue.h"
#import "ZBSettings.h"
#import "ZBCommand.h"
#import "ZBSafariAuthenticationSession.h"

@import SDWebImage;

@interface ZBPackage () {
    BOOL checkedForPurchaseInfo;
    ZBPurchaseInfo *purchaseInfo;
}
@end

@implementation ZBPackage

@synthesize identifier;
@synthesize name;
@synthesize version;
@synthesize shortDescription;
@synthesize longDescription;
@synthesize section;
@synthesize depictionURL;
@synthesize tags;
@synthesize dependsOn;
@synthesize conflictsWith;
@synthesize provides;
@synthesize replaces;
@synthesize authorName;
@synthesize authorEmail;
@synthesize source;
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
@synthesize SHA256;

+ (NSArray *)filesInstalledBy:(NSString *)packageID {
    ZBLog(@"[Zebra] Getting installed files for %@", packageID);
    if ([ZBDevice needsSimulation]) {
        return @[@"/.", @"/You", @"/You/Are", @"/You/Are/Simulated"];
    }
    
    NSString *path = [NSString stringWithFormat:@INSTALL_PREFIX @"/var/lib/dpkg/info/%@.list", packageID];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *readError = NULL;
        NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&readError];
        if (!readError) {
            return [contents componentsSeparatedByString:@"\n"];
        }
        return @[readError.localizedDescription];
    }
    return @[@"No files found"];
}

+ (BOOL)respringRequiredFor:(NSString *)packageID {
    if ([ZBDevice needsSimulation]) {
        return NO;
    }
    
    ZBLog(@"[Zebra] Searching %@ for respringable", packageID);
    if ([packageID hasSuffix:@".deb"]) {
        NSLog(@"[Zebra] I had to use DPKG :(");
        ZBLog(@"[Zebra] Locating package ID for %@", packageID);

        // We need to look up the *actual* package ID of this deb from the deb's control file
        NSString *stringRead = [ZBCommand execute:@INSTALL_PREFIX @"/usr/bin/dpkg"
                                withArguments:@[@"-I", packageID, @"control"]
                                       asRoot:NO];

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

+ (NSString * _Nullable)applicationBundlePathForIdentifier:(NSString *)packageID {
    if ([ZBDevice needsSimulation]) {
        return NULL;
    }
    
    ZBLog(@"[Zebra] Searching %@ for app path", packageID);
    if ([packageID hasSuffix:@".deb"]) {
        NSLog(@"[Zebra] I had to use DPKG :(");
        ZBLog(@"[Zebra] Locating package ID for %@", packageID);

        // We need to look up the *actual* package ID of this deb from the deb's control file
        NSString *stringRead = [ZBCommand execute:@INSTALL_PREFIX @"/usr/bin/dpkg"
                                    withArguments:@[@"-I", packageID, @"control"]
                                           asRoot:NO];

        __block NSString *path;
        [stringRead enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
            if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
            if (pair.count != 2) return;
            NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            if ([key isEqualToString:@"Package"]) {
                NSString *value = [pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                ZBLog(@"[Zebra] Package ID found %@", value);
                path = [self applicationBundlePathForIdentifier:value];
                *stop = YES;
            }
        }];

        return path;
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
        const char *architectureChars =     (const char *)sqlite3_column_text(statement, ZBPackageColumnArchitecture);
        const char *shortDescriptionChars = (const char *)sqlite3_column_text(statement, ZBPackageColumnShortDescription);
        const char *longDescriptionChars =  (const char *)sqlite3_column_text(statement, ZBPackageColumnLongDescription);
        const char *sectionChars =          (const char *)sqlite3_column_text(statement, ZBPackageColumnSection);
        const char *depictionChars =        (const char *)sqlite3_column_text(statement, ZBPackageColumnDepiction);
        const char *tagChars =              (const char *)sqlite3_column_text(statement, ZBPackageColumnTag);
        const char *authorNameChars =       (const char *)sqlite3_column_text(statement, ZBPackageColumnAuthorName);
        const char *authorEmailChars =      (const char *)sqlite3_column_text(statement, ZBPackageColumnAuthorEmail);
        const char *supportChars =          (const char *)sqlite3_column_text(statement, ZBPackageColumnSupport);
        const char *dependsChars =          (const char *)sqlite3_column_text(statement, ZBPackageColumnDepends);
        const char *conflictsChars =        (const char *)sqlite3_column_text(statement, ZBPackageColumnConflicts);
        const char *providesChars =         (const char *)sqlite3_column_text(statement, ZBPackageColumnProvides);
        const char *replacesChars =         (const char *)sqlite3_column_text(statement, ZBPackageColumnReplaces);
        const char *filenameChars =         (const char *)sqlite3_column_text(statement, ZBPackageColumnFilename);
        const char *iconChars =             (const char *)sqlite3_column_text(statement, ZBPackageColumnIconURL);
        const char *priorityChars =         (const char *)sqlite3_column_text(statement, ZBPackageColumnPriority);
        const char *essentialChars =        (const char *)sqlite3_column_text(statement, ZBPackageColumnEssential);
        const char *sha256Chars =           (const char *)sqlite3_column_text(statement, ZBPackageColumnSHA256);
        sqlite3_int64 lastSeen =            sqlite3_column_int64(statement, ZBPackageColumnLastSeen);
        
        if (packageIDChars == 0) return NULL; // There is no "working" situation where a package ID is missing
        
        [self setIdentifier:[NSString stringWithUTF8String:packageIDChars]]; // This should never be NULL
        [self setName:[ZBUtils decodeCString:packageNameChars fallback:self.identifier]]; // fall back to ID if NULL, or Unknown if things get worse
        [self setVersion:versionChars != 0 ? [NSString stringWithUTF8String:versionChars] : NULL];
        [self setArchitecture:architectureChars != 0 ? [NSString stringWithUTF8String:architectureChars] : NULL];
        [self setShortDescription:shortDescriptionChars != 0 ? [NSString stringWithUTF8String:shortDescriptionChars] : NULL];
        [self setLongDescription:longDescriptionChars != 0 ? [NSString stringWithUTF8String:longDescriptionChars] : NULL];
        [self setSection:sectionChars != 0 ? [NSString stringWithUTF8String:sectionChars] : NULL];
        [self setDepictionURL:depictionChars != 0 ? [NSURL URLWithString:[NSString stringWithUTF8String:depictionChars]] : NULL];
        [self setAuthorName:authorNameChars != 0 ? [NSString stringWithUTF8String:authorNameChars] : NULL];
        [self setAuthorEmail:authorEmailChars != 0 ? [NSString stringWithUTF8String:authorEmailChars] : NULL];
        [self setSupportURL:supportChars != 0 ? [NSURL URLWithString:[NSString stringWithUTF8String:supportChars]] : NULL];
        [self setFilename:filenameChars != 0 ? [NSString stringWithUTF8String:filenameChars] : NULL];
        [self setIconPath:iconChars != 0 ? [NSString stringWithUTF8String:iconChars] : NULL];
        
        [self setPriority:priorityChars != 0 ? [NSString stringWithUTF8String:priorityChars] : NULL];
        
        NSString *es = essentialChars != 0 ? [[NSString stringWithUTF8String:essentialChars] lowercaseString] : NULL;
        if (es && [es isEqualToString:@"yes"]) {
            [self setEssential:YES];
        }
        else if (es && [es isEqualToString:@"no"]) {
            [self setEssential:NO];
        }
        
        [self setSHA256:sha256Chars != 0 ? [NSString stringWithUTF8String:sha256Chars] : NULL];
        
        [self setTags:tagChars != 0 ? [[NSString stringWithUTF8String:tagChars] componentsSeparatedByString:@", "] : NULL];
        if ([tags count] == 1 && [tags[0] containsString:@","]) { // Fix crimes against humanity @Dnasty
            tags = [tags[0] componentsSeparatedByString:@","];
        }
        
        [self setDependsOn:[self extract:dependsChars]];
        [self setConflictsWith:[self extract:conflictsChars]];
        [self setProvides:[self extract:providesChars]];
        [self setReplaces:[self extract:replacesChars]];
        
        int sourceID = sqlite3_column_int(statement, ZBPackageColumnSourceID);
        if (sourceID > 0) {
            [self setSource:[ZBSource sourceMatchingSourceID:sourceID]];
        } else {
            [self setSource:[ZBSource localSource:sourceID]];
        }
        
        [self setLastSeenDate:lastSeen ? [NSDate dateWithTimeIntervalSince1970:lastSeen] : [NSDate date]];
        [self setInstalledSize:sqlite3_column_int(statement, ZBPackageColumnInstalledSize)];
        [self setDownloadSize:sqlite3_column_int(statement, ZBPackageColumnDownloadSize)];
    }
    
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    
    if (self) {
        NSString *packageID = [dictionary objectForKey:@"Package"];
        if (!packageID) return NULL;  // This should never be NULL
        
        NSString *name = [dictionary objectForKey:@"Name"] ?: packageID; // fall back to ID if NULL
        NSString *version = [dictionary objectForKey:@"Version"] ?: NULL;
        NSString *architecture = [dictionary objectForKey:@"Architecture"] ?: NULL;
        NSString *desc = [dictionary objectForKey:@"Description"] ?: NULL;
        NSString *section = [dictionary objectForKey:@"Section"] ?: NULL;
        NSString *depiction = [dictionary objectForKey:@"Depiction"] ?: NULL;
        NSString *author = [dictionary objectForKey:@"Author"] ?: NULL;
        NSString *depends = [dictionary objectForKey:@"Depends"] ?: NULL;
        NSString *conflicts = [dictionary objectForKey:@"Conflicts"] ?: NULL;
        NSString *provides = [dictionary objectForKey:@"Provides"] ?: NULL;
        NSString *replaces = [dictionary objectForKey:@"Replaces"] ?: NULL;
        NSString *icon = [dictionary objectForKey:@"Icon"] ?: NULL;
        NSString *priority = [dictionary objectForKey:@"Priority"] ?: NULL;
        NSString *essential = [dictionary objectForKey:@"Essential"] ?: NULL;
        
        NSString *tagString = [dictionary objectForKey:@"Tag"] ?: NULL;
        if (tagString) {
            [self setTags:[tagString componentsSeparatedByString:@", "] ?: NULL];
        }
        
        [self setIdentifier:packageID];
        [self setName:name];
        [self setVersion:version];
        [self setArchitecture:architecture];
        [self setShortDescription:desc];
        [self setSection:section];
        [self setDepictionURL:[NSURL URLWithString:depiction]];
        [self setAuthorName:author];
        [self setIconPath:icon];
        [self setPriority:priority];
        [self setTags:tags];
        
        if (essential && [essential isEqualToString:@"yes"]) {
            [self setEssential:YES];
        }
        else if (essential && [essential isEqualToString:@"no"]) {
            [self setEssential:NO];
        }
        
        if ([tags count] == 1 && [tags[0] containsString:@","]) { // Fix crimes against humanity @Dnasty
            tags = [tags[0] componentsSeparatedByString:@","];
        }
        
        [self setDependsOn:[self extract:[depends UTF8String]]];
        [self setConflictsWith:[self extract:[conflicts UTF8String]]];
        [self setProvides:[self extract:[provides UTF8String]]];
        [self setReplaces:[self extract:[replaces UTF8String]]];
    }
    
    return self;
}

- (id)initFromDeb:(NSString *)path {
    if (!path) return NULL;
    if (![path hasSuffix:@".deb"]) return NULL;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) return NULL;
    
    NSString *stringRead;
    if (![ZBDevice needsSimulation]) {
        stringRead = [ZBCommand execute:@INSTALL_PREFIX @"/usr/bin/dpkg"
                          withArguments:@[@"-I", path, @"control"]
                                 asRoot:NO];
    }
    else {
        stringRead = [[NSString alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"control" withExtension:@"sample"] encoding:NSUTF8StringEncoding error:nil];
    }
    
    NSMutableDictionary *info = [NSMutableDictionary new];
    [stringRead enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
        if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
        if (pair.count != 2) return;
        NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        NSString *value = [pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        info[key] = value;
    }];
    
    ZBPackage *package = [self initWithDictionary:info];
    [package setDebPath:path];
    [package setSource:[ZBSource localSource:-2]];
    
    return package;
}

- (BOOL)isEqual:(ZBPackage *)object {
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:[ZBPackage class]])
        return NO;
    
    if ([self SHA256] && [object SHA256])
        return [[self SHA256] isEqual:[object SHA256]];
    
    return ([[object identifier] isEqual:self.identifier] && [[object version] isEqual:[self version]]);
}

- (BOOL)sameAs:(ZBPackage *)package {
    return [self.identifier isEqualToString:package.identifier];
}

- (BOOL)sameAsStricted:(ZBPackage *)package {
    return [self sameAs:package] && [[self version] isEqualToString:package.version];
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ (%@) v%@ by %@ via %@", name, identifier, version, authorName ?: NSLocalizedString(@"Unknown", @""), [source label] ?: NSLocalizedString(@"Unknown", @"")];
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

- (BOOL)mightRequirePayment {
    return [self requiresPayment] || ([[self source] sourceID] > 0 && [self isPaid] && [[self source] supportsPaymentAPI]);
}

- (BOOL)requiresPayment {
    return self.requiresAuthorization || (checkedForPurchaseInfo && purchaseInfo);
}

- (void)purchaseInfo:(void (^)(ZBPurchaseInfo *_Nullable info))completion {
    // Package must have cydia::commercial in its tags in order for Zebra to send the POST request for modern API
    if (![self mightRequirePayment]) {
        completion(nil);
        purchaseInfo = nil;
        self.requiresAuthorization = NO;
        return;
    }
    
    checkedForPurchaseInfo = YES;

    [self.source.paymentVendor getInfoForPackage:self.identifier completion:^(ZBPurchaseInfo * _Nonnull info, NSError * _Nonnull error) {
        if (error) {
            completion(nil);
            self->purchaseInfo = nil;
            self.requiresAuthorization = NO;
            return;
        }
        completion(info);
        self->purchaseInfo = info;
        self.requiresAuthorization = YES;
    }];
}

- (NSString * _Nullable)getField:(NSString *)field {
    NSString *value;
    
    ZBSource *source = [self source];
    
    if (source == NULL) return NULL;
    
    NSString *listsLocation = [ZBAppDelegate listsLocation];
    NSString *filename = [NSString stringWithFormat:@"%@/%@%@", listsLocation, [source baseFilename], @"_Packages"];
    NSFileManager *filemanager = [NSFileManager defaultManager];
    
    if (![filemanager fileExistsAtPath:filename]) {
        filename = [NSString stringWithFormat:@"%@/%@_main_binary-%@_Packages", listsLocation, [source baseFilename], [ZBDevice debianArchitecture]];
        
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
    NSString *packageInfo = NULL;
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
    if (downloadSize <= 0) return nil;
    return [NSByteCountFormatter stringFromByteCount:downloadSize countStyle:NSByteCountFormatterCountStyleFile];
}

- (NSString *)installedSizeString {
    if (installedSize <= 0) return nil;
    return [NSByteCountFormatter stringFromByteCount:installedSize * 1024 countStyle:NSByteCountFormatterCountStyleFile];
}

- (BOOL)isInstalled:(BOOL)strict {
    if (source && [source sourceID] <= 0) { // Package is in sourceID 0 or -1
        return YES;
    }
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    return [databaseManager packageIsInstalled:self versionStrict:strict];
}

- (BOOL)isReinstallable {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    return [databaseManager packageIsAvailable:self versionStrict:YES];
}

- (NSMutableArray <ZBPackage *> *)allVersions {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    NSMutableArray *versions = [NSMutableArray arrayWithArray:[databaseManager allVersionsForPackage:self]];
    
    return versions;
}

- (NSMutableArray <ZBPackage *> *)otherVersions {
    NSMutableArray *versions = [self allVersions];
    [versions removeObject:self];
    
    return versions;
}

- (NSMutableArray <ZBPackage *> *)lesserVersions {
    NSMutableArray *versions = [[self otherVersions] mutableCopy];
    NSMutableArray *lesserVersions = [versions mutableCopy];
    for (ZBPackage *package in versions) {
        if ([self compare:package] == NSOrderedAscending) {
            [lesserVersions removeObject:package];
        }
    }
    
    return lesserVersions;
}

- (NSMutableArray <ZBPackage *> *)greaterVersions {
    NSMutableArray *versions = [[self otherVersions] mutableCopy];
    NSMutableArray *greaterVersions = [versions mutableCopy];
    for (ZBPackage *package in versions) {
        if ([self compare:package] == NSOrderedDescending) {
            [greaterVersions removeObject:package];
        }
    }
    
    return greaterVersions;
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

- (ZBPackage * _Nullable)installableCandidate {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    ZBPackage *candidate = [databaseManager packageForIdentifier:self.identifier thatSatisfiesComparison:@"<=" ofVersion:[self version]];
    
    return candidate;
}

- (ZBPackage * _Nullable)removeableCandidate {
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
	NSString *listPath = [NSString stringWithFormat:@INSTALL_PREFIX @"/var/lib/dpkg/info/%@.list", self.identifier];
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:listPath error:NULL];
	return attributes[NSFileModificationDate];
}

- (NSString * _Nullable)installedVersion {
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

- (void)setIconImageForImageView:(UIImageView *)imageView {
    UIImage *sectionImage = [ZBSource imageForSection:self.section];
    if (self.iconPath) {
        [imageView sd_setImageWithURL:[NSURL URLWithString:self.iconPath] placeholderImage:sectionImage];
    }
    else {
        [imageView setImage:sectionImage];
    }
}

- (NSArray * _Nullable)possibleActions {    
    if ([[self source] sourceID] == -1) {
        return nil; // No actions for virtual dependencies
    }
    else if ([[self source] sourceID] == -2) {
        return @[@(ZBPackageActionInstall)];
    }
    
    NSMutableArray *actions = [NSMutableArray new];
    ZBQueue *queue = [ZBQueue sharedQueue];
    
    if ([[self source] sourceID] == 0) {
        // If the package is installed then we can show other options
        if (![queue contains:self inQueue:ZBQueueTypeReinstall] && [self isReinstallable]) {
            // Search for the same version of this package in the database
            [actions addObject:@(ZBPackageActionReinstall)];
        }
            
        if (![queue contains:self inQueue:ZBQueueTypeUpgrade] && [[self greaterVersions] count] ) {
            // Only going to explicitly show an "Upgrade" button if there are higher versions available
            [actions addObject:@(ZBPackageActionUpgrade)]; // Select higher versions
        }
            
        if (![queue contains:self inQueue:ZBQueueTypeDowngrade] && [[self lesserVersions] count]) {
            // Only going to explicily show a "Downgrade" button if there are lower versions available
            [actions addObject:@(ZBPackageActionDowngrade)];
        }
        
        if ([self ignoreUpdates]) {
            // Updates are ignored, show them
            [actions addObject:@(ZBPackageActionShowUpdates)];
        }
        else {
            // Updates are not ignored, give the option to hide them
            [actions addObject:@(ZBPackageActionHideUpdates)];
        }
        [actions addObject:@(ZBPackageActionRemove)]; // Show the remove button regardless
    }
    else if ([self isInstalled:NO]) { // This means the package is installed but this isn't the version that is currently installed
        // We need to calculate the actions based on the package that is actually installed
        ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
        ZBPackage *basePackage = [databaseManager localVersionForPackage:self];
        
        return [basePackage possibleActions];
    }
    else { // This means the package is not installed
        if ([[ZBDatabaseManager sharedInstance] packageHasUpdate:self] && [self isEssentialOrRequired]) {
            // If the package has an update available and it is essential or required (a "suggested" package) then you can ignore it
            if ([self ignoreUpdates]) {
                // Updates are ignored, show them
                [actions addObject:@(ZBPackageActionShowUpdates)];
            }
            else {
                // Updates are not ignored, give the option to hide them
                [actions addObject:@(ZBPackageActionHideUpdates)];
            }
        }
        if ([[self allVersions] count] > 1 && ![ZBSettings alwaysInstallLatest]) { // Show "Select version" instead of "Install" as it makes more sense
            [actions addObject:@(ZBPackageActionSelectVersion)];
        }
        else {
            [actions addObject:@(ZBPackageActionInstall)]; // Show "Install" otherwise (could be disabled if its already in the Queue)
        }
    }
    
    return [actions sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
}

- (void)purchase:(void (^)(BOOL success, NSError *_Nullable error))completion {
    [self purchase:YES completion:completion];
}

- (void)purchase:(BOOL)tryAgain completion:(void (^)(BOOL success, NSError *_Nullable error))completion {
    ZBSource *source = [self source];

    void (^authenticate)(void) = ^{
        // Should only run if we don't have a payment secret or if we aren't logged in.
        [self.source.paymentVendor authenticate:^(BOOL success, BOOL notify, NSError * _Nullable error) {
            if (!success && notify) {
                if (tryAgain) {
                    [self purchase:NO completion:completion]; // Try again, but only try once
                } else {
                    if (!error) {
                        error = [NSError errorWithDomain:ZBPaymentVendorErrorDomain code:0 userInfo:@{
                            NSLocalizedDescriptionKey: NSLocalizedString(@"Account information could not be retrieved from the source. Please sign out of the source, sign in, and try again.", @"")
                        }];
                    }
                    completion(NO, error);
                }
            }
        }];
    };
    
    if ([self mightRequirePayment] && [source.paymentVendor isSignedIn]) { // Check if we have an access token
        [source.paymentVendor getPaymentSecret:^(NSString * _Nullable secret, NSError * _Nullable error) {
            if (!error) {
                [self.source.paymentVendor initiatePurchaseForPackage:self.identifier
                                                        paymentSecret:secret
                                                           completion:^(NSError * _Nullable error) {
                    completion(error == nil, error);
                }];
                return;
            } else if (error.code != errSecUserCanceled) {
                authenticate();
            }
        }];
        return;
    }
    authenticate();
}

@end
