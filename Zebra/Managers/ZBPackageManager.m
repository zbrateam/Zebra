//
//  ZBPackageManager.m
//  Zebra
//
//  Created by Wilson Styres on 10/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBPackageManager.h"

#import <string.h>
#import <ZBDevice.h>
#import <Managers/ZBDatabaseManager.h>
#import <Model/ZBPackage.h>
#import <Model/ZBPackageFilter.h>
#import <Model/ZBSource.h>
#import <Helpers/utils.h>
#import <Database/ZBDependencyResolver.h>

@interface ZBPackageManager () {
    ZBDatabaseManager *databaseManager;
    NSMutableSet *uuids;
    sqlite_int64 currentUpdateDate;
}
@end

@implementation ZBPackageManager

@synthesize installedPackagesList = _installedPackagesList;
@synthesize virtualPackagesList = _virtualPackagesList;
@synthesize updates = _updates;

+ (instancetype)sharedInstance {
    static ZBPackageManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZBPackageManager new];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        databaseManager = [ZBDatabaseManager sharedInstance];
    }
    
    return self;
}

- (void)packagesFromSource:(ZBSource *)source inSection:(NSString * _Nullable)section completion:(void (^)(NSArray <ZBPackage *> *packages))completion {
    if ([section isEqual:@"Uncategorized"]) section = @"";
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSArray *packages = [self->databaseManager packagesFromSource:source inSection:section];
        if (completion) completion(packages);
    });
}

- (NSArray <ZBPackage *> *)latestPackages:(NSUInteger)limit {
    return [databaseManager latestPackages:limit];
}

- (NSDictionary<NSString *,NSString *> *)installedPackagesList {
    if (!_installedPackagesList) {
        _installedPackagesList = [databaseManager packageListFromSource:[ZBSource localSource]];
    }
    
    return _installedPackagesList;
}

- (NSDictionary<NSString *,NSString *> *)virtualPackagesList {
    if (!_virtualPackagesList) {
        _virtualPackagesList = [databaseManager virtualPackageListFromSource:[ZBSource localSource]];
    }
    
    return _virtualPackagesList;
}

- (NSArray <ZBPackage *> *)updates {
    if (!_updates) {
        _updates = [databaseManager updatesForPackageList:self.installedPackagesList];
    }
    
    return _updates;
}

- (BOOL)isPackageInstalled:(ZBPackage *)package {
    return [self isPackageInstalled:package checkVersion:NO];
}

- (BOOL)isPackageInstalled:(ZBPackage *)package checkVersion:(BOOL)checkVersion {
    if (checkVersion) {
        NSString *version = [self.installedPackagesList objectForKey:package.identifier];
        if (!version) return NO;
        
        return [package.version isEqualToString:version];
    } else {
        return [self.installedPackagesList objectForKey:package.identifier];
    }
}

- (void)importPackagesFromSource:(ZBBaseSource *)source {
    if (!source.packagesFilePath) return;
    
    uuids = [[databaseManager uniqueIdentifiersForPackagesFromSource:source] mutableCopy];
    currentUpdateDate = (sqlite3_int64)[[NSDate date] timeIntervalSince1970];
    
    [databaseManager performTransaction:^{
        FILE *file = fopen(source.packagesFilePath.UTF8String, "r");
        char line[2048];
        char **package = dualArrayOfSize(ZBPackageColumnCount);
        
        while (fgets(line, 2048, file)) {
            if (line[0] == '\n' || line[0] == '\r') {
                const char *identifier = package[ZBPackageColumnIdentifier];
                if (identifier && strcmp(identifier, "") != 0) {
                    if (!source.remote && package[ZBPackageColumnStatus]) {
                        const char *status = package[ZBPackageColumnStatus];
                        if (strcasestr(status, "config-files") != NULL || strcasestr(status, "not-installed") != NULL || strcasestr(status, "deinstall") != NULL) {
                            continue;
                        }
                        
                        NSString *identifier = [NSString stringWithUTF8String:package[ZBPackageColumnIdentifier]];
                        NSString *version = [NSString stringWithUTF8String:package[ZBPackageColumnVersion]];                        
                    }
                    
                    if (!package[ZBPackageColumnName]) strcpy(package[ZBPackageColumnName], package[ZBPackageColumnIdentifier]);
                    
                    NSString *uniqueIdentifier = [NSString stringWithFormat:@"%s-%s-%@", package[ZBPackageColumnIdentifier], package[ZBPackageColumnVersion], source.uuid];
                    if (![self->uuids containsObject:uniqueIdentifier]) {
                        strcpy(package[ZBPackageColumnSource], source.uuid.UTF8String);
                        strcpy(package[ZBPackageColumnUUID], uniqueIdentifier.UTF8String);
                        memcpy(package[ZBPackageColumnLastSeen], &self->currentUpdateDate, sizeof(sqlite_int64 *));
                        
                        [self->databaseManager insertPackage:package];
                        
                        freeDualArrayOfSize(package, ZBPackageColumnCount);
                        package = dualArrayOfSize(ZBPackageColumnCount);
                    } else {
                        [self->uuids removeObject:uniqueIdentifier];
                    }
                }
            } else {
                char *key = strtok((char *)line, ":");
                ZBPackageColumn column = [self columnFromString:key];
                if (key && column < ZBPackageColumnCount) {
                    char *value = strtok(NULL, "");
                    if (value && value[0] == ' ') value++;
                    if (value) strcpy(package[column], trimWhitespaceFromString(value));
                }
            }
        }
        if (package) {
            const char *identifier = package[ZBPackageColumnIdentifier];
            if (identifier && strcmp(identifier, "") != 0) {
                if (!source.remote && package[ZBPackageColumnStatus]) {
                    const char *status = package[ZBPackageColumnStatus];
                    if (strcasestr(status, "config-files") != NULL || strcasestr(status, "not-installed") != NULL || strcasestr(status, "deinstall") != NULL) {
                        freeDualArrayOfSize(package, ZBPackageColumnCount);
                        fclose(file);
                        return;
                    }
                }
                
                if (!package[ZBPackageColumnName]) strcpy(package[ZBPackageColumnName], package[ZBPackageColumnIdentifier]);
                
                NSString *uniqueIdentifier = [NSString stringWithFormat:@"%s-%s-%@", package[ZBPackageColumnIdentifier], package[ZBPackageColumnVersion], source.uuid];
                if (![self->uuids containsObject:uniqueIdentifier]) {
                    strcpy(package[ZBPackageColumnSource], source.uuid.UTF8String);
                    strcpy(package[ZBPackageColumnUUID], uniqueIdentifier.UTF8String);
                    memcpy(package[ZBPackageColumnLastSeen], &self->currentUpdateDate, sizeof(sqlite_int64 *));
                    
                    [self->databaseManager insertPackage:package];
                    
                    freeDualArrayOfSize(package, ZBPackageColumnCount);
                    package = dualArrayOfSize(ZBPackageColumnCount);
                } else {
                    [self->uuids removeObject:uniqueIdentifier];
                }
            }
        }
        
        freeDualArrayOfSize(package, ZBPackageColumnCount);
        fclose(file);
    }];
    
    [databaseManager deletePackagesWithUniqueIdentifiers:uuids];
    [uuids removeAllObjects];
}

- (ZBPackageColumn)columnFromString:(char *)string {
    if (strcmp(string, "Author") == 0) {
        return ZBPackageColumnAuthorName;
    } else if (strcmp(string, "Description") == 0) {
        return ZBPackageColumnDescription;
    } else if (strcmp(string, "Package") == 0) {
        return ZBPackageColumnIdentifier;
    } else if (strcmp(string, "Name") == 0) {
        return ZBPackageColumnName;
    } else if (strcmp(string, "Version") == 0) {
        return ZBPackageColumnVersion;
    } else if (strcmp(string, "Section") == 0) {
        return ZBPackageColumnSection;
    } else if (strcmp(string, "Conflicts") == 0) {
        return ZBPackageColumnConflicts;
    } else if (strcmp(string, "Depends") == 0) {
        return ZBPackageColumnDepends;
    } else if (strcmp(string, "Depiction") == 0) {
        return ZBPackageColumnDepictionURL;
    } else if (strcmp(string, "Size") == 0) {
        return ZBPackageColumnDownloadSize;
    } else if (strcmp(string, "Essential") == 0) {
        return ZBPackageColumnEssential;
    } else if (strcmp(string, "Filename") == 0) {
        return ZBPackageColumnFilename;
    } else if (strcmp(string, "Homepage") == 0) {
        return ZBPackageColumnHomepageURL;
    } else if (strcmp(string, "Icon") == 0) {
        return ZBPackageColumnIconURL;
    } else if (strcmp(string, "Installed-Size") == 0) {
        return ZBPackageColumnInstalledSize;
    } else if (strcmp(string, "Maintainer") == 0) {
        return ZBPackageColumnMaintainerName;
    } else if (strcmp(string, "Priority") == 0) {
        return ZBPackageColumnPriority;
    } else if (strcmp(string, "Provides") == 0) {
        return ZBPackageColumnProvides;
    } else if (strcmp(string, "Replaces") == 0) {
        return ZBPackageColumnReplaces;
    } else if (strcmp(string, "SHA256") == 0) {
        return ZBPackageColumnSHA256;
    } else if (strcmp(string, "Status") == 0) {
        return ZBPackageColumnStatus;
    } else if (strcmp(string, "Tag") == 0) {
        return ZBPackageColumnTag;
    } else {
        return ZBPackageColumnCount;
    }
}

- (ZBPackage *_Nullable)installedInstanceOfPackage:(ZBPackage *)package {
    return [databaseManager installedInstanceOfPackage:package];
}

- (ZBPackage *_Nullable)packageWithUniqueIdentifier:(NSString *)uuid {
    return [databaseManager packageWithUniqueIdentifier:uuid];
}

- (NSArray <ZBPackage *> *)packagesByAuthorWithName:(NSString *)name email:(NSString *_Nullable)email {
    return [databaseManager packagesByAuthorWithName:name email:email];
}

- (BOOL)canReinstallPackage:(ZBPackage *)package {
    return [databaseManager isPackageAvailable:package checkVersion:YES];
}

- (void)searchForPackagesByName:(NSString *)name completion:(void (^)(NSArray <ZBPackage *> *packages))completion {
    [databaseManager searchForPackagesByName:name completion:completion];
}

- (void)searchForPackagesByDescription:(NSString *)description completion:(void (^)(NSArray <ZBPackage *> *packages))completion {
    [databaseManager searchForPackagesByDescription:description completion:completion];
}

- (void)searchForPackagesByAuthorWithName:(NSString *)name completion:(void (^)(NSArray <ZBPackage *> *packages))completion {
    [databaseManager searchForPackagesByAuthorWithName:name completion:completion];
}

- (NSString *)installedVersionOfPackage:(ZBPackage *)package {
    return [databaseManager installedVersionOfPackage:package];
}

- (NSArray <NSString *> *)allVersionsOfPackage:(ZBPackage *)package {
    return [databaseManager allVersionsOfPackage:package];
}

- (NSArray <ZBPackage *> *)allInstancesOfPackage:(ZBPackage *)package {
    return [databaseManager allInstancesOfPackage:package];
}

- (NSArray <ZBPackage *> *)filterPackages:(NSArray <ZBPackage *> *)packages withFilter:(ZBPackageFilter *)filter {
    if (!filter) return packages;
    
    NSArray *filteredPackages = [packages filteredArrayUsingPredicate:filter.compoundPredicate];
    return [filteredPackages sortedArrayUsingDescriptors:filter.sortDescriptors];
}

- (ZBPackage *)instanceOfPackage:(ZBPackage *)package withVersion:(NSString *)version {
    return [databaseManager instanceOfPackage:package withVersion:version];
}

#pragma mark - Source Delegate

- (void)finishedSourceRefresh {
    _updates = [databaseManager updatesForPackageList:self.installedPackagesList];
}

@end
