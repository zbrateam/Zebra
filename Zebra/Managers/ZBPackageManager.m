//
//  ZBPackageManager.m
//  Zebra
//
//  Created by Wilson Styres on 10/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBPackageManager.h"

#import <Managers/ZBDatabaseManager.h>
#import <Model/ZBPackage.h>
#import <Model/ZBSource.h>
#import <string.h>
#import <Database/ZBColumn.h>

@interface ZBPackageManager () {
    ZBDatabaseManager *databaseManager;
    NSMutableSet *uuids;
    sqlite_int64 currentUpdateDate;
}
@end

@implementation ZBPackageManager

- (id)init {
    self = [super init];
    
    if (self) {
        databaseManager = [ZBDatabaseManager sharedInstance];
    }
    
    return self;
}

- (void)importPackagesFromSource:(ZBSource *)source {
    if (!source.packagesFilePath) return;
    
    NSDate *methodStart = [NSDate date];
    uuids = [[databaseManager uniqueIdentifiersForPackagesFromSource:source] mutableCopy];
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"%@ ID fetch executionTime = %f", source.label, executionTime);
    
    currentUpdateDate = (sqlite3_int64)[[NSDate date] timeIntervalSince1970];
    
    [databaseManager beginTransaction];
    NSData *packagesData = [NSData dataWithContentsOfFile:source.packagesFilePath];
    NSData *separator = [NSData dataWithBytes:"\n\n" length:2];
    NSRange searchRange = NSMakeRange(0, packagesData.length);
    NSRange foundRange = [packagesData rangeOfData:separator options:0 range:searchRange];
    while (foundRange.location != NSNotFound) {
        NSData *packageData = [packagesData subdataWithRange:NSMakeRange(searchRange.location, foundRange.location - searchRange.location)];
        [self importPackage:packageData toSource:source];
        
        searchRange.location = foundRange.location + foundRange.length;
        searchRange.length = packagesData.length  - searchRange.location;
        foundRange = [packagesData rangeOfData:separator options:0 range:searchRange];
    }
    
    if (searchRange.length > 0 && foundRange.location != NSNotFound) {
        NSData *packageData = [packagesData subdataWithRange:NSMakeRange(searchRange.location, foundRange.location - searchRange.location)];
        [self importPackage:packageData toSource:source];
    }
    [databaseManager endTransaction];
    
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
    } else if (strcmp(string, "Tag") == 0) {
        return ZBPackageColumnTag;
    } else {
        return ZBPackageColumnCount;
    }
}

- (void)importPackage:(NSData *)data toSource:(ZBSource *)source {
    char **package = malloc(ZBPackageColumnCount * sizeof(char *));
    for (int i = 0; i < ZBPackageColumnCount; i++) {
        package[i] = malloc(512 * sizeof(char *));
        package[i][0] = '\0';
    }
    
    NSString *control = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (control) {
        [control enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
            const char *charLine = [line UTF8String];
            char *key = strtok((char *)charLine, ":");
            char *value = strtok(NULL, ":");
            if (value && value[0] == ' ') value++;

            ZBPackageColumn column = [self columnFromString:key];
            if (key && value && column < ZBPackageColumnCount) strcpy(package[column], value);
        }];
        
        const char *identifier = package[ZBPackageColumnIdentifier];
        if (identifier) {
            if (!package[ZBPackageColumnName]) strcpy(package[ZBPackageColumnName], package[ZBPackageColumnIdentifier]);
            
            NSString *uniqueIdentifier = [NSString stringWithFormat:@"%s-%s-%@", package[ZBPackageColumnIdentifier], package[ZBSourceColumnVersion], source.uuid];
            if (![uuids containsObject:uniqueIdentifier]) {
                strcpy(package[ZBPackageColumnSource], source.uuid.UTF8String);
                strcpy(package[ZBPackageColumnUUID], uniqueIdentifier.UTF8String);
    //            package[ZBPackageColumnLastSeen] = &currentUpdateDate;
                
                [databaseManager insertPackage:package];
            } else {
                [uuids removeObject:uniqueIdentifier];
            }
        }
        
    }
    for (int i = 0; i < ZBPackageColumnCount; i++) {
        free(package[i]);
    }
    free(package);
}

- (NSArray <ZBBasePackage *> *)packagesFromSource:(ZBSource *)source {
    return [[ZBDatabaseManager sharedInstance] packagesMatchingFilters:@"source == 1"];
}



@end
