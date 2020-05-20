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
#import <ZBUtils.h>
#import <Parsel/vercmp.h>
#import <Sources/Helpers/ZBSource.h>
#import <ZBAppDelegate.h>
#import <NSTask.h>
#import <Database/ZBDatabaseManager.h>
#import <Database/ZBColumn.h>
#import "ZBPurchaseInfo.h"
#import "UICKeyChainStore.h"
#import <Queue/ZBQueue.h>
#import <ZBSettings.h>

@import LinkPresentation;
@import SDWebImage;
@import FirebaseCrashlytics;

@interface ZBPackage () {
    BOOL checkedForPurchaseInfo;
    ZBPurchaseInfo *purchaseInfo;
}
@end

@implementation ZBPackage

@synthesize identifier;
@synthesize name;
@synthesize version;
@synthesize tagline;
@synthesize packageDescription;
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
        NSLog(@"[Zebra] I had to use DPKG :(");
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
            [[FIRCrashlytics crashlytics] logWithFormat:@"%@ Could not spawn dpkg. Reason: %@", e.name, e.reason];
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

+ (NSString * _Nullable)applicationBundlePathForIdentifier:(NSString *)packageID {
    if ([ZBDevice needsSimulation]) {
        return NULL;
    }
    
    ZBLog(@"[Zebra] Searching %@ for app path", packageID);
    if ([packageID hasSuffix:@".deb"]) {
        NSLog(@"[Zebra] I had to use DPKG :(");
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
                    path = [self applicationBundlePathForIdentifier:value];
                    *stop = YES;
                }
            }];
            
            return path;
        }
        @catch (NSException *e) {
            [[FIRCrashlytics crashlytics] logWithFormat:@"%@ Could not spawn dpkg. Reason: %@", e.name, e.reason];
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
        const char *taglineChars =          (const char *)sqlite3_column_text(statement, ZBPackageColumnTagline);
        const char *descriptionChars =      (const char *)sqlite3_column_text(statement, ZBPackageColumnDescription);
        const char *sectionChars =          (const char *)sqlite3_column_text(statement, ZBPackageColumnSection);
        const char *depictionChars =        (const char *)sqlite3_column_text(statement, ZBPackageColumnDepiction);
        const char *tagChars =              (const char *)sqlite3_column_text(statement, ZBPackageColumnTag);
        const char *authorNameChars =       (const char *)sqlite3_column_text(statement, ZBPackageColumnAuthorName);
        const char *authorEmailChars =      (const char *)sqlite3_column_text(statement, ZBPackageColumnAuthorEmail);
        const char *dependsChars =          (const char *)sqlite3_column_text(statement, ZBPackageColumnDepends);
        const char *conflictsChars =        (const char *)sqlite3_column_text(statement, ZBPackageColumnConflicts);
        const char *providesChars =         (const char *)sqlite3_column_text(statement, ZBPackageColumnProvides);
        const char *replacesChars =         (const char *)sqlite3_column_text(statement, ZBPackageColumnReplaces);
        const char *filenameChars =         (const char *)sqlite3_column_text(statement, ZBPackageColumnFilename);
        const char *iconChars =             (const char *)sqlite3_column_text(statement, ZBPackageColumnIcon);
        const char *priorityChars =         (const char *)sqlite3_column_text(statement, ZBPackageColumnPriority);
        const char *essentialChars =        (const char *)sqlite3_column_text(statement, ZBPackageColumnEssential);
        const char *sha256Chars =           (const char *)sqlite3_column_text(statement, ZBPackageColumnSHA256);
        const char *headerChars =           (const char *)sqlite3_column_text(statement, ZBPackageColumnHeader);
        const char *changelogTitleChars =   (const char *)sqlite3_column_text(statement, ZBPackageColumnChangelog);
        const char *changelogNotesChars =   (const char *)sqlite3_column_text(statement, ZBPackageColumnChangelogNotes);
        const char *homepageChars =         (const char *)sqlite3_column_text(statement, ZBPackageColumnHomepage);
        const char *previewsChars =         (const char *)sqlite3_column_text(statement, ZBPackageColumnPreviews);
        const char *maintainerNameChars =   (const char *)sqlite3_column_text(statement, ZBPackageColumnMaintainerName);
        const char *maintainerEmailChars =  (const char *)sqlite3_column_text(statement, ZBPackageColumnMaintainerEmail);
        const char *preferNativeChars =     (const char *)sqlite3_column_text(statement, ZBPackageColumnPreferNative);
        sqlite3_int64 lastSeen =            sqlite3_column_int64(statement, ZBPackageColumnLastSeen);
        
        if (packageIDChars == 0) return NULL; // There is no "working" situation where a package ID is missing
        
        [self setIdentifier:[NSString stringWithUTF8String:packageIDChars]]; // This should never be NULL
        [self setName:[ZBUtils decodeCString:packageNameChars fallback:self.identifier]]; // fall back to ID if NULL, or Unknown if things get worse
        [self setVersion:versionChars != 0 ? [NSString stringWithUTF8String:versionChars] : NULL];
        [self setTagline:taglineChars != 0 ? [NSString stringWithUTF8String:taglineChars] : NULL];
        [self setPackageDescription:descriptionChars != 0 ? [NSString stringWithUTF8String:descriptionChars] : NULL];
        [self setSection:sectionChars != 0 ? [NSString stringWithUTF8String:sectionChars] : NULL];
        [self setDepictionURL:depictionChars != 0 ? [NSURL URLWithString:[NSString stringWithUTF8String:depictionChars]] : NULL];
        [self setAuthorName:authorNameChars != 0 ? [NSString stringWithUTF8String:authorNameChars] : NULL];
        [self setAuthorEmail:authorEmailChars != 0 ? [NSString stringWithUTF8String:authorEmailChars] : NULL];
        [self setFilename:filenameChars != 0 ? [NSString stringWithUTF8String:filenameChars] : NULL];
        [self setIconPath:iconChars != 0 ? [NSString stringWithUTF8String:iconChars] : NULL]; // TODO: Should change to iconURL later
        [self setHeaderURL:headerChars != 0 ? [NSURL URLWithString:[NSString stringWithUTF8String:headerChars]] : NULL];
        [self setChangelogTitle:changelogTitleChars != 0 ? [NSString stringWithUTF8String:changelogTitleChars] : NULL];
        [self setChangelogNotes:changelogNotesChars != 0 ? [NSString stringWithUTF8String:changelogNotesChars] : NULL];
        [self setHomepageURL:homepageChars != 0 ? [NSURL URLWithString:[NSString stringWithUTF8String:homepageChars]] : NULL];
        [self setMaintainerName:maintainerNameChars != 0 ? [NSString stringWithUTF8String:maintainerNameChars] : NULL];
        [self setMaintainerEmail:maintainerEmailChars != 0 ? [NSString stringWithUTF8String:maintainerEmailChars] : NULL];
        
        [self setPriority:priorityChars != 0 ? [NSString stringWithUTF8String:priorityChars] : NULL];
        
        NSString *es = essentialChars != 0 ? [[NSString stringWithUTF8String:essentialChars] lowercaseString] : NULL;
        if (es && [es isEqualToString:@"yes"]) {
            [self setEssential:YES];
        }
        else if (es && [es isEqualToString:@"no"]) {
            [self setEssential:NO];
        }
        
        NSString *pn = preferNativeChars != 0 ? [[NSString stringWithUTF8String:preferNativeChars] lowercaseString] : NULL;
        if (pn && [pn isEqualToString:@"yes"]) {
            [self setPreferNative:YES];
        }
        else {
            [self setPreferNative:NO];
        }
        
        [self setSHA256:sha256Chars != 0 ? [NSString stringWithUTF8String:sha256Chars] : NULL];
        
        [self setTags:tagChars != 0 ? [[NSString stringWithUTF8String:tagChars] componentsSeparatedByString:@", "] : NULL];
        if ([tags count] == 1 && [tags[0] containsString:@","]) {
            tags = [tags[0] componentsSeparatedByString:@","];
        }
        
        [self setPreviewImageURLs:previewsChars != 0 ? [[NSString stringWithUTF8String:previewsChars] componentsSeparatedByString:@", "] : NULL];
        if ([_previewImageURLs count] == 1 && [_previewImageURLs[0] containsString:@","]) {
            _previewImageURLs = [_previewImageURLs[0] componentsSeparatedByString:@","];
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
        [self setPackageDescription:desc];
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
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/bin/dpkg"];
        [ZBDevice asRoot:task arguments:@[@"-I", path, @"control"]];
        
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput:pipe];
        
        [task launch];
        
        NSFileHandle *read = [pipe fileHandleForReading];
        NSData *dataRead = [read readDataToEndOfFile];
        [task waitUntilExit];
        
        stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
        
        [read closeFile];
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
    return [self requiresPayment] || ([[self source] sourceID] > 0 && [self isPaid] && [[self source] suppotsPaymentAPI]);
}

- (BOOL)requiresPayment {
    return self.requiresAuthorization || (checkedForPurchaseInfo && purchaseInfo);
}

- (void)purchaseInfo:(void (^)(ZBPurchaseInfo *_Nullable info))completion {
    //Package must have cydia::commercial in its tags in order for Zebra to send the POST request for modern API
    if (![self mightRequirePayment]) {
        completion(NULL);
        
        purchaseInfo = NULL;
        self.requiresAuthorization = NO;
        return;
    }
    
    checkedForPurchaseInfo = YES;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    
    NSURL *packageInfoURL = [[[self source] paymentVendorURL] URLByAppendingPathComponent:[NSString stringWithFormat:@"package/%@/info", [self identifier]]];
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
//            NSString *repsonse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//            NSLog(@"response %@", repsonse);
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
    NSString *filename = [NSString stringWithFormat:@"%@/%@%@", listsLocation, [source baseFilename], @"_Packages"];
    NSFileManager *filemanager = [NSFileManager defaultManager];
    
    if (![filemanager fileExistsAtPath:filename]) {
        filename = [NSString stringWithFormat:@"%@/%@%@", listsLocation, [source baseFilename], @"_main_binary-iphoneos-arm_Packages"];
        
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
	NSString *listPath = [NSString stringWithFormat:@"/var/lib/dpkg/info/%@.list", self.identifier];
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:listPath error:NULL];
	return attributes[NSFileModificationDate];
}

- (NSString * _Nullable)installedVersion {
    if ([[self source] sourceID] == 0) return self.version;
    
    return [[ZBDatabaseManager sharedInstance] installedVersionForPackage:self];
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
        
        [actions addObject:@(ZBPackageActionRemove)]; // Show the remove button regardless
    }
    else if ([self isInstalled:NO]) { // This means the package is installed but this isn't the version that is currently installed
        // We need to calculate the actions based on the package that is actually installed
        ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
        ZBPackage *basePackage = [databaseManager localVersionForPackage:self];
        
        return [basePackage possibleActions];
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
    if ([[self source] sourceID] == -1) {
        return nil; // No actions for virtual dependencies
    }
    
    NSMutableArray *actions = [NSMutableArray new];

    if ([self authorName]) {
        if (![ZBSettings isAuthorBlocked:[self authorName] email:[self authorEmail]]) {
            [actions addObject:@(ZBPackageExtraActionBlockAuthor)];
        }
        else {
            [actions addObject:@(ZBPackageExtraActionUnblockAuthor)];
        }
    }
    
    if (![self isInstalled:NO]) {
        // Only allow adding/removing from wishlist if the package is not installed
        if (![[ZBSettings wishlist] containsObject:[self identifier]]) {
            [actions addObject:@(ZBPackageExtraActionAddWishlist)];
        }
        else {
            [actions addObject:@(ZBPackageExtraActionRemoveWishlist)];
        }
        
        if ([[ZBDatabaseManager sharedInstance] packageHasUpdate:self] && [self isEssentialOrRequired]) {
            // If the package has an update available and it is essential or required (a "suggested" package) then you can ignore it
            if ([self ignoreUpdates]) {
                // Updates are ignored, show them
                [actions addObject:@(ZBPackageExtraActionShowUpdates)];
            }
            else {
                // Updates are not ignored, give the option to hide them
                [actions addObject:@(ZBPackageExtraActionHideUpdates)];
            }
        }
    }
    else {
        if ([self ignoreUpdates]) {
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
    BOOL installed = [self isInstalled:NO];
    
    if (installed) {
        NSString *installedVersion = [self installedVersion];
        if (installedVersion) {
            NSDictionary *installedVersionInfo = @{@"name": NSLocalizedString(@"Installed Version", @""), @"value": installedVersion, @"cellType": @"info"};
            [information addObject:installedVersionInfo];
        }
    }
    else {
        NSArray <ZBPackage *> *allVersions = [self allVersions];
        if (allVersions.count) { // Theres at least one package
            NSString *latestVersion = [allVersions[0] version];
            if (latestVersion) {
                NSDictionary *latestVersionInfo = @{@"name": NSLocalizedString(@"Version", @""), @"value": latestVersion, @"cellType": @"info"};
                [information addObject:latestVersionInfo];
            }
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
        NSDictionary *sourceOriginInfo = @{@"name": NSLocalizedString(@"Source", @""), @"value": sourceOrigin, @"cellType": @"info"};
        [information addObject:sourceOriginInfo];
    }
    
    NSString *section = [self section];
    if (section) {
        NSDictionary *sectionInfo = @{@"name": NSLocalizedString(@"Section", @""), @"value": section, @"cellType": @"info"};
        [information addObject:sectionInfo];
    }
    
    NSArray *dependencies = [self dependsOn];
    if ([dependencies count]) {
        NSDictionary *dependsInfo = @{@"name": NSLocalizedString(@"Dependencies", @""), @"value": [NSString stringWithFormat:@"%lu Dependencies", (unsigned long)dependencies.count], @"cellType": @"info", @"more": [dependencies componentsJoinedByString:@"\n"]};
        [information addObject:dependsInfo];
    }
    
    NSArray *conflicts = [self conflictsWith];
    if ([conflicts count]) {
        NSDictionary *conflictsInfo = @{@"name": NSLocalizedString(@"Conflicts", @""), @"value": [NSString stringWithFormat:@"%lu Conflicts", (unsigned long)conflicts.count], @"cellType": @"info", @"more": [conflicts componentsJoinedByString:@"\n"]};
        [information addObject:conflictsInfo];
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
    
    return information;
}

- (NSString *)changelogTitle {
    if (_changelogTitle && ![_changelogTitle isEqualToString:@""]) {
        return [NSString stringWithFormat:NSLocalizedString(@"Version %@ — %@", @""), version, _changelogTitle];
    }
    return [NSString stringWithFormat:NSLocalizedString(@"Version %@", @""), version];
}

- (NSString *)changelogNotes {
    if (_changelogNotes  && ![_changelogNotes isEqualToString:@""]) {
        return _changelogNotes;
    }
    return NSLocalizedString(@"No Release Notes Available", @"");
}

- (void)purchase:(void (^)(BOOL success, NSError *_Nullable error))completion {
    ZBSource *source = [self source];
    
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    if ([source isSignedIn]) { //Check if we have an access token
        if ([self mightRequirePayment]) { //Just a small double check to make sure the package is paid and the source supports payment
            NSError *error;
            NSString *secret = [source paymentSecret:&error];
            
            if (secret && !error) {
                NSURL *purchaseURL = [[source paymentVendorURL] URLByAppendingPathComponent:[NSString stringWithFormat:@"package/%@/purchase", [self identifier]]];
                
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
        if (success) {
            [self purchase:completion];
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
    if (self.source.sourceID > 0) {
        if (self.authorName) {
            return [NSString stringWithFormat:@"Check out %@ by %@ on Zebra! zbra://packages/%@?source=%@", self.name, self.authorName, self.identifier, self.source.repositoryURI];
        }
        else {
            return [NSString stringWithFormat:@"Check out %@ on Zebra! zbra://packages/%@?source=%@", self.name, self.identifier, self.source.repositoryURI];
        }
    }
    else {
        ZBPackage *installableCandidate = [self installableCandidate];
        if (installableCandidate && installableCandidate.source.sourceID > 0) {
            return [installableCandidate activityViewController:activityViewController itemForActivityType:activityType];
        }
        else {
            return [NSString stringWithFormat:@"Check out %@ on Zebra! zbra://packages/%@", self.name, self.identifier];
        }
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

@end
