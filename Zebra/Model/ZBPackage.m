//
//  ZBPackage.m
//  Zebra
//
//  Created by Wilson Styres on 2/2/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackage.h"
#import "ZBPackageActions.h"

#import <ZBLog.h>
#import <ZBDevice.h>
#import <Helpers/vercmp.h>
#import <Model/ZBSource.h>
#import <ZBAppDelegate.h>
#import <Managers/ZBPackageManager.h>
#import <JSONParsing/ZBPurchaseInfo.h>
#import "UICKeyChainStore.h"
#import <Queue/ZBQueue.h>
#import <ZBSettings.h>
#import <Managers/ZBSourceManager.h>
#import <Console/ZBCommand.h>

@import LinkPresentation;
@import SDWebImage;
@import FirebaseCrashlytics;
@import SafariServices;

@interface ZBPackage () {
    NSString *author;
    NSString *maintainer;
    
    NSString *lowestCompatibleVersion;
    NSString *highestCompatibleVersion;
    
    BOOL checkedForPurchaseInfo;
    ZBPurchaseInfo *purchaseInfo;
    NSString *sourceUUID;
}
@end

@implementation ZBPackage

@synthesize isVersionInstalled = _isVersionInstalled;
@synthesize allVersions = _allVersions;

+ (NSArray *)filesInstalledBy:(NSString *)packageID {
    ZBLog(@"[Zebra] Getting installed files for %@", packageID);
    if ([ZBDevice needsSimulation]) {
        return @[@"/.", @"/You", @"/You/Are", @"/You/Are/Simulated"];
    }
    
    NSString *path = [NSString stringWithFormat:@"/var/lib/dpkg/info/%@.list", packageID];
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
        //We need to look up the *actual* package ID of this deb from the deb's control file
        
        NSString *stringRead = [ZBCommand execute:@"/usr/bin/dpkg" withArguments:@[@"-I", packageID, @"control"] asRoot:NO];
        __block BOOL contains = NO;
        [stringRead enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
            if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
            if (pair.count != 2) return;
            NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            if ([key isEqualToString:@"Package"]) {
                NSString *value = [pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
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

+ (NSString *)applicationBundlePathForIdentifier:(NSString *)packageID {
    if ([ZBDevice needsSimulation]) {
        return NULL;
    }
    
    if ([packageID hasSuffix:@".deb"]) {
        //We need to look up the *actual* package ID of this deb from the deb's control file
        
        NSString *stringRead = [ZBCommand execute:@"/usr/bin/dpkg" withArguments:@[@"-I", packageID, @"control"] asRoot:NO];
        __block NSString *path;
        [stringRead enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
            if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
            if (pair.count != 2) return;
            NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
            if ([key isEqualToString:@"Package"]) {
                NSString *value = [pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
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

- (id)initFromSQLiteStatement:(sqlite3_stmt *)statement {
    self = [super initFromSQLiteStatement:statement];
    
    if (self) {
        const char *authorEmail = (const char *)sqlite3_column_text(statement, ZBPackageColumnAuthorEmail);
        if (authorEmail && authorEmail[0] != '\0') { // This is the only column that is NULL usually, the rest of them are empty so we do an extra check
            _authorEmail = [NSString stringWithUTF8String:authorEmail];
        }
        
        const char *conflicts = (const char *)sqlite3_column_text(statement, ZBPackageColumnConflicts);
        if (conflicts && conflicts[0] != '\0') {
            NSString *rawConflicts = [NSString stringWithUTF8String:conflicts];
            _conflicts = [rawConflicts componentsSeparatedByString:@","];
        }
        
        const char *depends = (const char *)sqlite3_column_text(statement, ZBPackageColumnDepends);
        if (depends && depends[0] != '\0') {
            NSString *rawDepends = [NSString stringWithUTF8String:depends];
            _depends = [rawDepends componentsSeparatedByString:@","];
        }
        
        const char *depictionURL = (const char *)sqlite3_column_text(statement, ZBPackageColumnDepictionURL);
        if (depictionURL && depictionURL[0] != '\0') {
            NSString *depictionURLString = [NSString stringWithUTF8String:depictionURL];
            _depictionURL = [NSURL URLWithString:depictionURLString];
        }
        
        _essential = sqlite3_column_int(statement, ZBPackageColumnEssential);
        
        const char *filename = (const char *)sqlite3_column_text(statement, ZBPackageColumnFilename);
        if (filename && filename[0] != '\0') {
            _filename = [NSString stringWithUTF8String:filename];
        }
        
        const char *homepageURL = (const char *)sqlite3_column_text(statement, ZBPackageColumnHomepageURL);
        if (homepageURL && homepageURL[0] != '\0') {
            NSString *homepageURLString = [NSString stringWithUTF8String:homepageURL];
            _homepageURL = [NSURL URLWithString:homepageURLString];
        }
        
        const char *maintainerEmail = (const char *)sqlite3_column_text(statement, ZBPackageColumnMaintainerEmail);
        if (maintainerEmail && maintainerEmail && maintainerEmail[0] != '\0') {
            _maintainerEmail = [NSString stringWithUTF8String:maintainerEmail];
        }
        
        const char *maintainerName = (const char *)sqlite3_column_text(statement, ZBPackageColumnMaintainerName);
        if (maintainerName && maintainerName[0] != '\0') {
            _maintainerName = [NSString stringWithUTF8String:maintainerName];
        }
        
        const char *priorityChars = (const char *)sqlite3_column_text(statement, ZBPackageColumnPriority);
        if (priorityChars && priorityChars[0] != '\0') {
            _priority = [NSString stringWithUTF8String:priorityChars];
        }
        
        const char *provides = (const char *)sqlite3_column_text(statement, ZBPackageColumnProvides);
        if (provides && provides[0] != '\0') {
            NSString *rawProvides = [NSString stringWithUTF8String:provides];
            _provides = [rawProvides componentsSeparatedByString:@","];
        }
        
        const char *replaces = (const char *)sqlite3_column_text(statement, ZBPackageColumnReplaces);
        if (replaces && replaces[0] != '\0') {
            NSString *rawReplaces = [NSString stringWithUTF8String:replaces];
            _replaces = [rawReplaces componentsSeparatedByString:@","];
        }
        
        const char *SHA256 = (const char *)sqlite3_column_text(statement, ZBPackageColumnSHA256);
        if (SHA256 && SHA256[0] != '\0') {
            _SHA256 = [NSString stringWithUTF8String:SHA256];
        }
    }
    
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    
    if (self) {
//        NSString *packageID = [dictionary objectForKey:@"Package"];
//        if (!packageID) return NULL;  // This should never be NULL
//
//        NSString *name = [dictionary objectForKey:@"Name"] ?: packageID; // fall back to ID if nil
//        NSString *version = [dictionary objectForKey:@"Version"] ?: nil;
//        NSString *desc = [dictionary objectForKey:@"Description"] ?: nil;
//        NSString *section = [dictionary objectForKey:@"Section"] ?: nil;
//        NSString *depiction = [dictionary objectForKey:@"Depiction"] ?: nil;
//        NSString *author = [dictionary objectForKey:@"Author"] ?: nil;
//        NSString *depends = [dictionary objectForKey:@"Depends"] ?: nil;
//        NSString *conflicts = [dictionary objectForKey:@"Conflicts"] ?: nil;
//        NSString *provides = [dictionary objectForKey:@"Provides"] ?: nil;
//        NSString *replaces = [dictionary objectForKey:@"Replaces"] ?: nil;
//        NSString *icon = [dictionary objectForKey:@"Icon"] ?: nil;
//        NSString *priority = [dictionary objectForKey:@"Priority"] ?: nil;
//        NSString *essential = [dictionary objectForKey:@"Essential"] ?: nil;
//
//        NSString *tagString = [dictionary objectForKey:@"Tag"] ?: nil;
//        if (tagString) {
//            [self setTags:[tagString componentsSeparatedByString:@", "] ?: nil];
//        }
//
//        [self setIdentifier:packageID];
//        [self setName:name];
//        [self setVersion:version];
//        [self setPackageDescription:desc];
//        [self setSection:section];
//        [self setDepictionURL:depiction ? [NSURL URLWithString:depiction] : nil];
//        [self setAuthorName:author];
//        [self setIconPath:icon];
//        [self setPriority:priority];
//
//        if (essential && [essential isEqualToString:@"yes"]) {
//            [self setEssential:YES];
//        }
//        else if (essential && [essential isEqualToString:@"no"]) {
//            [self setEssential:NO];
//        }
//
//        if ([self.tags count] == 1 && [self.tags[0] containsString:@","]) { // Fix crimes against humanity @Dnasty
//            self.tags = [self.tags[0] componentsSeparatedByString:@","];
//        }
//
//        [self setDependsOn:[self extract:[depends UTF8String]]];
//        [self setConflictsWith:[self extract:[conflicts UTF8String]]];
//        [self setProvides:[self extract:[provides UTF8String]]];
//        [self setReplaces:[self extract:[replaces UTF8String]]];
    }
    
    return self;
}

- (id)initFromDeb:(NSString *)path {
    if (!path) return NULL;
    if (![path hasSuffix:@".deb"]) return NULL;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) return NULL;
    
    NSString *stringRead;
    if (![ZBDevice needsSimulation]) {
        stringRead = [ZBCommand execute:@"/usr/bin/dpkg" withArguments:@[@"-I", path, @"control"] asRoot:NO];
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
    
    self = [self initWithDictionary:info];
    if (self) {
        _debPath = path;
//        _source = [ZBSource localSource];
    }
    
    return self;
}

- (BOOL)isEqual:(ZBPackage *)object {
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:[ZBPackage class]])
        return NO;
    
    return ([[object identifier] isEqual:self.identifier] && [[object version] isEqual:[self version]] && [[[self source] uuid] isEqual:[[object source] uuid]]);
}

- (BOOL)sameAs:(ZBPackage *)package {
    return [self.identifier isEqualToString:package.identifier];
}

- (BOOL)sameAsStricted:(ZBPackage *)package {
    return [self sameAs:package] && [[self version] isEqualToString:package.version];
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ (%@) v%@ by %@ via %@", self.name, self.identifier, self.version, self.authorName ?: NSLocalizedString(@"Unknown", @""), [self.source label] ?: NSLocalizedString(@"Unknown", @"")];
}

- (NSComparisonResult)compare:(id)object {
    if ([object isKindOfClass:[ZBPackage class]] || [object isKindOfClass:[ZBBasePackage class]]) {
        ZBPackage *obj = (ZBPackage *)object;
        if ([self isEqual:obj])
            return NSOrderedSame;
        
        NSInteger firstPriority = self.source.pinPriority;
        NSInteger secondPriority = obj.source.pinPriority;
        if (firstPriority < 0) return NSOrderedAscending;
        if (secondPriority < 0) return NSOrderedDescending;
        
        int result = compare([[self version] UTF8String], [[obj version] UTF8String]);
        
        if (result < 0) {
            return (firstPriority >= 1000 && secondPriority == 100) || (firstPriority < 1000 && secondPriority != 100 && firstPriority > secondPriority) ? NSOrderedDescending : NSOrderedAscending;
        } else if (result > 0) {
            return (secondPriority >= 1000 && firstPriority == 100) || (secondPriority < 1000 && firstPriority != 100 && firstPriority < secondPriority) ? NSOrderedAscending : NSOrderedDescending;
        }
        return NSOrderedSame;
    } else {
        if ((NSString *)object == NULL) return NSOrderedDescending;
        return versionComparator(object, self.version);
    }
}

- (BOOL)mightRequirePayment {
    return [self requiresPayment] || (self.source.remote && self.isPaid && self.source.supportsPaymentAPI);
}

- (BOOL)requiresPayment {
    return self.requiresAuthorization || (checkedForPurchaseInfo && purchaseInfo);
}

- (void)purchaseInfo:(void (^)(ZBPurchaseInfo * _Nullable info))completion {
    //Package must have cydia::commercial in its tags in order for Zebra to send the POST request for modern API
    if (![self mightRequirePayment]) {
        completion(NULL);

        purchaseInfo = NULL;
        self.requiresAuthorization = NO;
        return;
    }

    checkedForPurchaseInfo = YES;

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];

    NSURL *packageInfoURL = [[[self source] paymentEndpointURL] URLByAppendingPathComponent:[NSString stringWithFormat:@"package/%@/info", [self identifier]]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:packageInfoURL];

    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];

    NSString *token = [keychain stringForKey:[[self source] repositoryURI]];
    NSDictionary *requestJSON;
    if (token) {
        requestJSON = @{@"token": token, @"udid": [ZBDevice UDID], @"device": [ZBDevice deviceModelID]};
    }
    else {
        requestJSON = @{@"udid": [ZBDevice UDID], @"device": [ZBDevice deviceModelID]};
    }
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestJSON options:(NSJSONWritingOptions)0 error:nil];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Zebra/%@ (%@; iOS/%@)", PACKAGE_VERSION, [ZBDevice deviceType], [[UIDevice currentDevice] systemVersion]] forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:requestData];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpReponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = [httpReponse statusCode];

        if (statusCode == 200) {
            NSError *error = NULL;
            ZBPurchaseInfo *info = [ZBPurchaseInfo fromData:data error:&error];

            if (!error) {
                completion(info);

                self->purchaseInfo = info;
                self.requiresAuthorization = YES;
                return;
            }

            completion(NULL);

            self->purchaseInfo = NULL;
            self.requiresAuthorization = NO;
            return;
        }
    }];

    [task resume];
}

- (NSString * _Nullable)getField:(NSString *)field {
    NSString *value;
    
    ZBSource *source = [self source];
    
    if (source == NULL) return NULL;
    
    NSString *listsLocation = [ZBAppDelegate listsLocation];
    NSString *filename = [NSString stringWithFormat:@"%@/%@%@", listsLocation, [source uuid], @"_Packages"];
    NSFileManager *filemanager = [NSFileManager defaultManager];
    
    if (![filemanager fileExistsAtPath:filename]) {
        filename = [NSString stringWithFormat:@"%@/%@%@", listsLocation, [source uuid], @"_main_binary-iphoneos-arm_Packages"];
        
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

- (NSString * _Nullable)downloadSizeString {
    return [NSByteCountFormatter stringFromByteCount:self.downloadSize countStyle:NSByteCountFormatterCountStyleFile];
}

- (NSString * _Nullable)installedSizeString {
    return [NSByteCountFormatter stringFromByteCount:self.installedSize * 1024 countStyle:NSByteCountFormatterCountStyleFile]; // Installed-Size is "estimated installed size in bytes, divided by 1024" but these sizes seem a little large...
}

- (BOOL)isVersionInstalled {
    if (_isVersionInstalled) return _isVersionInstalled;
    
    _isVersionInstalled = [[ZBPackageManager sharedInstance] isPackageInstalled:self checkVersion:YES];
    
    return _isVersionInstalled;
}

- (BOOL)canReinstall {
    return [[ZBPackageManager sharedInstance] canReinstallPackage:self];
}

- (NSArray <NSString *> *)allVersions {
    if (!_allVersions || _allVersions.count == 0) {
        _allVersions = [[ZBPackageManager sharedInstance] allVersionsOfPackage:self];
    }
    
    return _allVersions;
}

- (NSArray <NSString *> *)otherVersions {
    NSMutableArray *allVersions = self.allVersions.mutableCopy;
    [allVersions removeObject:self.version];
    
    return allVersions;
}

NSComparisonResult (^versionComparator)(NSString *, NSString *) = ^NSComparisonResult(NSString *version1, NSString *version2) {
    int result = compare(version1.UTF8String, version2.UTF8String);
    if (result > 0)
        return NSOrderedAscending;
    if (result < 0)
        return NSOrderedDescending;
    return NSOrderedSame;
};

- (NSArray <NSString *> *)lesserVersions {
    NSMutableArray *versions = self.otherVersions.mutableCopy;
    NSMutableArray *lesserVersions = versions.mutableCopy;
    for (NSString *version in versions) {
        if ([self compare:version] == NSOrderedAscending) {
            [lesserVersions removeObject:version];
        }
    }
    
    return [lesserVersions sortedArrayUsingComparator:versionComparator];
}

- (NSArray <NSString *> *)greaterVersions {
    NSMutableArray *versions = self.otherVersions.mutableCopy;
    NSMutableArray *greaterVersions = versions.mutableCopy;
    for (NSString *version in versions) {
        if ([self compare:version] == NSOrderedDescending) {
            [greaterVersions removeObject:version];
        }
    }
    
    return [greaterVersions sortedArrayUsingComparator:versionComparator];
}

- (BOOL)areUpdatesIgnored {
    return [ZBSettings areUpdatesIgnoredForPackageIdentifier:self.identifier];
}

- (void)setIgnoreUpdates:(BOOL)ignore {
    [ZBSettings setUpdatesIgnored:ignore forPackageIdentifier:self.identifier];
}

- (NSString * _Nullable)installedVersion {
    if (!self.source.remote) return self.version;
    
    return [[ZBPackageManager sharedInstance] installedVersionOfPackage:self];
}

- (void)addDependency:(ZBPackage *)package {
    if (!self.dependencies) self.dependencies = [NSMutableArray new];
    
    if (![self.dependencies containsObject:package]) {
        [self.dependencies addObject:package];
    }
}

- (void)addDependencyOf:(ZBPackage *)package {
    if (!self.dependencyOf) self.dependencyOf = [NSMutableArray new];
    
    if (![self.dependencyOf containsObject:package]) {
        [self.dependencyOf addObject:package];
    }
}

- (void)addIssue:(NSString *)issue {
    if (!self.issues) self.issues = [NSMutableArray new];
    
    [self.issues addObject:issue];
}

- (BOOL)hasIssues {
    return [self.issues count];
}

- (BOOL)isEssentialOrRequired {
    return self.essential || [[self.priority lowercaseString] isEqualToString:@"required"];
}

- (NSArray * _Nullable)possibleActions {
    NSMutableArray *actions = [NSMutableArray new];
    ZBQueue *queue = [ZBQueue sharedQueue];
    
    if (self.isVersionInstalled) {
        // If the package is installed then we can show other options
        if (![queue contains:self inQueue:ZBQueueTypeReinstall] && [self canReinstall]) {
            // Search for the same version of this package in the database
            [actions addObject:@(ZBPackageActionReinstall)];
        }
            
        if (![queue contains:self inQueue:ZBQueueTypeUpgrade] && [[self greaterVersions] count] ) {
            // Only going to explicitly show an "Upgrade" button if there are higher versions available
            [actions addObject:@(ZBPackageActionUpgrade)]; // Select higher versions
        }
            
        if (![queue contains:self inQueue:ZBQueueTypeDowngrade] && [[self lesserVersions] count]) {
            // Only going to explicitly show a "Downgrade" button if there are lower versions available
            [actions addObject:@(ZBPackageActionDowngrade)];
        }
        
        [actions addObject:@(ZBPackageActionRemove)]; // Show the remove button regardless
    }
    else if (self.isInstalled) { // This means the package is installed but this isn't the version that is currently installed
        // We need to calculate the actions based on the package that is actually installed
        ZBPackage *installedInstance = [[ZBPackageManager sharedInstance] installedInstanceOfPackage:self];
        
        return [installedInstance possibleActions];
    }
    else { // This means the package is not installed
        if ([[self allVersions] count] > 1 && ![ZBSettings alwaysInstallLatest]) { // Show "Select version" instead of "Install" as it makes more sense
            [actions addObject:@(ZBPackageActionSelectVersion)];
        }
        else {
            [actions addObject:@(ZBPackageActionInstall)]; // Show "Install" otherwise (could be disabled if its already in the Queue)
        }
    }
    
    return [actions sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
}

- (NSArray *_Nullable)possibleExtraActions {
    NSMutableArray *actions = [NSMutableArray new];

    if ([self authorName]) {
        if (![ZBSettings isAuthorBlocked:[self authorName] email:[self authorEmail]]) {
            [actions addObject:@(ZBPackageExtraActionBlockAuthor)];
        }
        else {
            [actions addObject:@(ZBPackageExtraActionUnblockAuthor)];
        }
    }
    
    if (!self.isInstalled) {
        // Only allow adding/removing from wishlist if the package is not installed
        if (![[ZBSettings wishlist] containsObject:[self identifier]]) {
            [actions addObject:@(ZBPackageExtraActionAddWishlist)];
        }
        else {
            [actions addObject:@(ZBPackageExtraActionRemoveWishlist)];
        }
        
        // Might want to rethink this a bit
//        if ([[ZBDatabaseManager sharedInstance] packageHasUpdate:self] && [self isEssentialOrRequired]) {
//            // If the package has an update available and it is essential or required (a "suggested" package) then you can ignore it
//            if ([self ignoreUpdates]) {
//                // Updates are ignored, show them
//                [actions addObject:@(ZBPackageExtraActionShowUpdates)];
//            }
//            else {
//                // Updates are not ignored, give the option to hide them
//                [actions addObject:@(ZBPackageExtraActionHideUpdates)];
//            }
//        }
    }
    else {
        if ([self areUpdatesIgnored]) {
            // Updates are ignored, show them
            [actions addObject:@(ZBPackageExtraActionShowUpdates)];
        }
        else {
            // Updates are not ignored, give the option to hide them
            [actions addObject:@(ZBPackageExtraActionHideUpdates)];
        }
    }
    
    [actions addObject:@(ZBPackageExtraActionShare)];
    
    return [actions sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
}

- (NSArray *)information {
    NSMutableArray *information = [NSMutableArray new];
    BOOL installed = self.isInstalled;
    
    NSArray <NSString *> *allVersions = self.allVersions;
    if (allVersions.count > 1 && installed) {
        NSString *installedVersion = [self installedVersion];
        NSString *latestVersion = allVersions[0];
        
        if (compare(latestVersion.UTF8String, installedVersion.UTF8String) > 0) {
            if (latestVersion) {
                NSDictionary *latestVersionInfo = @{@"name": NSLocalizedString(@"Latest Version", @""), @"value": latestVersion, @"cellType": @"info"};
                [information addObject:latestVersionInfo];
            }
        }
        
        if (installedVersion) {
            NSDictionary *installedVersionInfo = @{@"name": NSLocalizedString(@"Installed Version", @""), @"value": installedVersion, @"cellType": @"info"};
            [information addObject:installedVersionInfo];
        }
    }
    else if (allVersions.count) {
        NSString *latestVersion = allVersions[0];
        if (latestVersion) {
            NSDictionary *latestVersionInfo = @{@"name": NSLocalizedString(@"Version", @""), @"value": latestVersion, @"cellType": @"info"};
            [information addObject:latestVersionInfo];
        }
    }
    
    NSString *bundleIdentifier = [self identifier];
    if (bundleIdentifier) {
        NSDictionary *bundleIdentifierInfo = @{@"name": NSLocalizedString(@"Bundle Identifier", @""), @"value": bundleIdentifier, @"cellType": @"info"};
        [information addObject:bundleIdentifierInfo];
    }
    
    if (installed) {
        NSString *installedSize = [self installedSizeString];
        if (installedSize) { // Show the installed size
            NSMutableDictionary *installedSizeInfo = [@{@"name": NSLocalizedString(@"Size", @""), @"value": installedSize, @"cellType": @"info", @"class": @"ZBInstalledFilesTableViewController"} mutableCopy];
            [information addObject:installedSizeInfo];
        }
        else { // Package is installed but has no installed size, just display installed files
            NSMutableDictionary *installedFilesInfo = [@{@"name": NSLocalizedString(@"Installed Files", @""), @"cellType": @"info", @"class": @"ZBInstalledFilesTableViewController"} mutableCopy];
            [information addObject:installedFilesInfo];
        }
    }
    else { // Show the download size
        NSString *downloadSize = [self downloadSizeString];
        if (downloadSize) {
            NSMutableDictionary *downloadSizeInfo = [@{@"name": NSLocalizedString(@"Size", @""), @"value": downloadSize, @"cellType": @"info"} mutableCopy];
            [information addObject:downloadSizeInfo];
        }
    }
    
    NSString *authorName = [self authorName];
    if (authorName) {
        NSDictionary *authorNameInfo = @{@"name": NSLocalizedString(@"Author", @""), @"value": authorName, @"cellType": @"info", @"class": @"ZBPackagesByAuthorTableViewController"};
        [information addObject:authorNameInfo];
    }
    else {
        NSString *maintainerName = [self maintainerName];
        if (maintainerName) {
            NSDictionary *maintainerNameInfo = @{@"name": NSLocalizedString(@"Maintainer", @""), @"value": maintainerName, @"cellType": @"info"};
            [information addObject:maintainerNameInfo];
        }
    }
    
    NSString *sourceOrigin = [[self source] origin];
    if (sourceOrigin) {
        if (self.source.remote) {
            NSDictionary *sourceOriginInfo = @{@"name": NSLocalizedString(@"Source", @""), @"value": sourceOrigin, @"cellType": @"info", @"class": @"ZBSourceSectionsListTableViewController"};
            [information addObject:sourceOriginInfo];
        } else {
            NSDictionary *sourceOriginInfo = @{@"name": NSLocalizedString(@"Source", @""), @"value": sourceOrigin, @"cellType": @"info"};
            [information addObject:sourceOriginInfo];
        }
    }
    
    NSString *section = [self section];
    if (section) {
        NSDictionary *sectionInfo = @{@"name": NSLocalizedString(@"Section", @""), @"value": section, @"cellType": @"info"};
        [information addObject:sectionInfo];
    }
    
    if (self.depends.count) {
        NSMutableArray *strippedDepends = [NSMutableArray new];
        for (NSString *depend in self.depends) {
            if ([depend containsString:@" | "]) {
                NSArray *ord = [depend componentsSeparatedByString:@" | "];
                for (__strong NSString *conflict in ord) {
                    NSRange range = [conflict rangeOfString:@"("];
                    if (range.location != NSNotFound) {
                        conflict = [conflict substringToIndex:range.location];
                    }
                    
                    if (![strippedDepends containsObject:conflict]) {
                        [strippedDepends addObject:conflict];
                    }
                }
            }
            else if (![strippedDepends containsObject:depend]) {
                [strippedDepends addObject:depend];
            }
        }
        
        NSDictionary *dependsInfo = @{@"name": NSLocalizedString(@"Dependencies", @""), @"value": [NSString stringWithFormat:@"%lu Dependencies", (unsigned long)strippedDepends.count], @"cellType": @"info", @"more": [strippedDepends componentsJoinedByString:@"\n"]};
        [information addObject:dependsInfo];
    }
    
    if (self.conflicts.count) {
        NSMutableArray *strippedConflicts = [NSMutableArray new];
        for (NSString *conflict in self.conflicts) {
            if ([conflict containsString:@" | "]) {
                NSArray *orc = [conflict componentsSeparatedByString:@" | "];
                for (__strong NSString *conflict in orc) {
                    NSRange range = [conflict rangeOfString:@"("];
                    if (range.location != NSNotFound) {
                        conflict = [conflict substringToIndex:range.location];
                    }
                    
                    if (![strippedConflicts containsObject:conflict]) {
                        [strippedConflicts addObject:conflict];
                    }
                }
            }
            else if (![strippedConflicts containsObject:conflict]) {
                [strippedConflicts addObject:conflict];
            }
        }
        
        NSDictionary *conflictsInfo = @{@"name": NSLocalizedString(@"Conflicts", @""), @"value": [NSString stringWithFormat:@"%lu Conflicts", (unsigned long)strippedConflicts.count], @"cellType": @"info", @"more": [strippedConflicts componentsJoinedByString:@"\n"]};
        [information addObject:conflictsInfo];
    }
    
    if (self.lowestCompatibleVersion) {
        NSString *compatibility;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(self.lowestCompatibleVersion) && SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(self.highestCompatibleVersion)) {
            compatibility = @"✅";
        } else {
            compatibility = @"⚠️";
        }
        
        NSDictionary *compatibiltyInfo = @{@"name": NSLocalizedString(@"Compatibility", @""), @"value": [NSString stringWithFormat:NSLocalizedString(@"iOS %@ - %@ %@", @""), self.lowestCompatibleVersion, self.highestCompatibleVersion, compatibility], @"cellType": @"info"};
        [information addObject:compatibiltyInfo];
    }
    
    NSURL *homepage = [self homepageURL];
    if (homepage) {
        NSDictionary *homepageInfo = @{@"name": NSLocalizedString(@"Developer Website", @""), @"cellType": @"link", @"link": homepage, @"image": @"Web Link"};
        [information addObject:homepageInfo];
    }
    
    BOOL showSupport = [self authorEmail] || [self maintainerEmail];
    if (showSupport) {
        NSDictionary *homepageInfo = @{@"name": NSLocalizedString(@"Support", @""), @"cellType": @"link", @"class": @"ZBPackageSupportViewController", @"image": @"Email"};
        [information addObject:homepageInfo];
    }
    
    NSURL *depiction = [self depictionURL];
    if (depiction) {
        NSDictionary *depictionInfo = @{@"name": NSLocalizedString(@"View Depiction in Safari", @""), @"cellType": @"link", @"link": depiction, @"image": @"Web Link"};
        [information addObject:depictionInfo];
    }
    
    return information;
}

- (BOOL)hasChangelog {
//    return _changelogTitle != NULL && _changelogNotes != NULL;
    return NO;
}

- (NSString *)changelogTitle {
    return NULL;
//    if (_changelogTitle && ![_changelogTitle isEqualToString:@""]) {
//        return [NSString stringWithFormat:NSLocalizedString(@"Version %@ — %@", @""), self.version, _changelogTitle];
//    }
//    return [NSString stringWithFormat:NSLocalizedString(@"Version %@", @""), self.version];
}

- (NSString *)changelogNotes {
//    if (_changelogNotes  && ![_changelogNotes isEqualToString:@""]) {
//        return _changelogNotes;
//    }
    return NSLocalizedString(@"No Release Notes Available", @"");
}

- (void)purchase:(void (^)(BOOL success, NSError *_Nullable error))completion {
    [self purchase:YES completion:completion];
}

- (void)purchase:(BOOL)tryAgain completion:(void (^)(BOOL success, NSError *_Nullable error))completion {
    ZBSource *source = [self source];
    
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    if ([source isSignedIn]) { //Check if we have an access token
        if ([self mightRequirePayment]) { //Just a small double check to make sure the package is paid and the source supports payment
            NSError *error;
            NSString *secret = [source paymentSecret:&error];
            
            if (secret && !error) {
                NSURL *purchaseURL = [source.paymentEndpointURL URLByAppendingPathComponent:[NSString stringWithFormat:@"package/%@/purchase", [self identifier]]];
                
                NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:purchaseURL];
                
                NSDictionary *requestJSON = @{@"token": [keychain stringForKey:[source repositoryURI]], @"payment_secret": secret, @"udid": [ZBDevice UDID], @"device": [ZBDevice deviceModelID]};
                NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestJSON options:(NSJSONWritingOptions)0 error:nil];
                
                [request setHTTPMethod:@"POST"];
                [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
                [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
                [request setHTTPBody:requestData];
                
                NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    NSHTTPURLResponse *httpReponse = (NSHTTPURLResponse *)response;
                    NSInteger statusCode = [httpReponse statusCode];
                    
                    if (statusCode == 200 && !error) {
                        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                        NSInteger status = [result[@"status"] integerValue];
                        switch (status) {
                            case -1: { // An error occurred, payment api doesn't specify that an error must exist here but we may as well check it
                                NSString *localizedDescription = [result objectForKey:@"error"] ?: NSLocalizedString(@"The Payment Provider returned an unspecified error", @"");
                                
                                NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:505 userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
                                completion(NO, error);
                                break;
                            }
                            case 0: { // Success, queue the package for install
                                completion(YES, nil);
                                break;
                            }
                            case 1: { // Action is required, pass this information on to the view controller
                                NSURL *actionLink = [NSURL URLWithString:result[@"url"]];
                                if (actionLink && actionLink.host && ([actionLink.scheme isEqualToString:@"https"])) {
                                    static SFAuthenticationSession *session;
                                    session = [[SFAuthenticationSession alloc] initWithURL:actionLink callbackURLScheme:@"sileo" completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
                                        if (callbackURL && !error) {
                                            completion(YES, nil);
                                        }
                                        else if (error && !(error.domain == SFAuthenticationErrorDomain && error.code == SFAuthenticationErrorCanceledLogin)) {
                                            NSString *localizedDescription = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Could not complete purchase", @""), error.localizedDescription];
                                            
                                            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:505 userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
                                            completion(NO, error);
                                        }
                                    }];
                                    [session start];
                                }
                                else {
                                    NSString *localizedDescription = [NSString stringWithFormat:NSLocalizedString(@"The Payment Provider responded with an improper payment URL: %@", @""), result[@"url"]];
                                    
                                    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:505 userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
                                    completion(NO, error);
                                }
                                break;
                            }
                        }
                    }
                }];
                
                [task resume];
                return;
            }
            else if (error && error.code == -128) { // I believe this error means that the user cancelled authentication prompt
                return;
            }
        }
    }
    
    // Should only run if we don't have a payment secret or if we aren't logged in.
    [[self source] authenticate:^(BOOL success, BOOL notify, NSError * _Nullable error) {
        if (tryAgain && success && !error) {
            [self purchase:NO completion:completion]; // Try again, but only try once
        }
        else if (!tryAgain) {
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:4122 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Account information could not be retrieved from the source. Please sign out of the source, sign in, and try again.", @"")}];
            completion(NO, error);
        }
        else {
            completion(NO, error);
        }
    }];
}

#pragma mark - UIActivityItemSource

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
    return self.name;
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(UIActivityType)activityType {
    if (self.source.remote) {
        if (self.authorName) {
            return [NSString stringWithFormat:@"Check out %@ by %@ on Zebra! zbra://packages/%@?source=%@", self.name, self.authorName, self.identifier, self.source.repositoryURI];
        }
        else {
            return [NSString stringWithFormat:@"Check out %@ on Zebra! zbra://packages/%@?source=%@", self.name, self.identifier, self.source.repositoryURI];
        }
    }
    else {
//        ZBPackage *installableCandidate = [self installableCandidate];
//        if (installableCandidate && installableCandidate.source.sourceID > 0) {
//            return [installableCandidate activityViewController:activityViewController itemForActivityType:activityType];
//        }
//        else {
            return [NSString stringWithFormat:@"Check out %@ on Zebra! zbra://packages/%@", self.name, self.identifier];
//        }
    }
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(UIActivityType)activityType {
    return @"Check out this package on Zebra";
}

- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController thumbnailImageForActivityType:(UIActivityType)activityType suggestedSize:(CGSize)size {
    return [ZBSource imageForSection:self.section];
}

- (LPLinkMetadata *)activityViewControllerLinkMetadata:(UIActivityViewController *)activityViewController API_AVAILABLE(ios(13.0)) {
    LPLinkMetadata *metaData = [[LPLinkMetadata alloc] init];
    metaData.originalURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"zbra://package/xyz.willy.zebra"]];
    metaData.URL = metaData.originalURL;
    metaData.title = self.name;
    metaData.imageProvider = [[NSItemProvider alloc] initWithObject:[ZBSource imageForSection:self.section]];
    
    return metaData;
}

- (void)calculateCompatibleVersions {
    NSString *minVersion = NULL;
    NSString *maxVersion = NULL;
    
    for (NSString *tag in self.tag) {
        if ([tag containsString:@"compatible_min"]) {
            minVersion = tag;
        } else if ([tag containsString:@"compatible_max"]) {
            maxVersion = tag;
        }
    }
    
    if (minVersion) {
        minVersion = [minVersion stringByReplacingOccurrencesOfString:@"compatible_min::" withString:@""];
        minVersion = [minVersion stringByReplacingOccurrencesOfString:@"ios" withString:@""];
        
        lowestCompatibleVersion = minVersion;
    }
    
    if (maxVersion) {
        maxVersion = [maxVersion stringByReplacingOccurrencesOfString:@"compatible_max::" withString:@""];
        maxVersion = [maxVersion stringByReplacingOccurrencesOfString:@"ios" withString:@""];
        
        highestCompatibleVersion = maxVersion;
    } else if (minVersion) {
        highestCompatibleVersion = [[UIDevice currentDevice] systemVersion];
    }
}

- (NSString *)lowestCompatibleVersion {
    if (!self.tag || self.tag.count == 0) return NULL;
    if (lowestCompatibleVersion) return lowestCompatibleVersion;
    
    [self calculateCompatibleVersions];
    return lowestCompatibleVersion;
}

- (NSString *)highestCompatibleVersion {
    if (!self.tag || self.tag.count == 0) return NULL;
    if (highestCompatibleVersion) return highestCompatibleVersion;
    
    [self calculateCompatibleVersions];
    return highestCompatibleVersion;
}

@end
