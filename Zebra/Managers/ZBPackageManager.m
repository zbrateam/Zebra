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

char** new_package() {
    char **package = malloc(ZBPackageColumnCount * sizeof(char *));
    for (int i = 0; i < ZBPackageColumnCount; i++) {
        package[i] = malloc(512 * sizeof(char *));
        package[i][0] = '\0';
    }
    
    return package;
}

void free_package(char **package) {
    for (int i = 0; i < ZBPackageColumnCount; i++) {
        free(package[i]);
    }
    free(package);
}

- (void)importPackagesFromSource:(ZBSource *)source {
    if (!source.packagesFilePath) return;
    
    NSDate *methodStart = [NSDate date];
    uuids = [[databaseManager uniqueIdentifiersForPackagesFromSource:source] mutableCopy];
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"%@ ID fetch executionTime = %f", source.label, executionTime);
    
    currentUpdateDate = (sqlite3_int64)[[NSDate date] timeIntervalSince1970];
    
    FILE *file = fopen(source.packagesFilePath.UTF8String, "r");
    char line[2048];
    char **package = new_package();
    
    [databaseManager beginTransaction];
    while (fgets(line, 2048, file)) {
        if (line[0] == '\n' || line[0] == '\r') {
            const char *identifier = package[ZBPackageColumnIdentifier];
            if (identifier) {
                if (!package[ZBPackageColumnName]) strcpy(package[ZBPackageColumnName], package[ZBPackageColumnIdentifier]);
                
                NSString *uniqueIdentifier = [NSString stringWithFormat:@"%s-%s-%@", package[ZBPackageColumnIdentifier], package[ZBSourceColumnVersion], source.uuid];
                if (![uuids containsObject:uniqueIdentifier]) {
                    strcpy(package[ZBPackageColumnSource], source.uuid.UTF8String);
                    strcpy(package[ZBPackageColumnUUID], uniqueIdentifier.UTF8String);
        //            package[ZBPackageColumnLastSeen] = &currentUpdateDate;
                    
                    [databaseManager insertPackage:package];
                    free_package(package);
                    package = new_package();
                } else {
                    [uuids removeObject:uniqueIdentifier];
                }
            }
        } else {
            char *key = strtok((char *)line, ":");
            ZBPackageColumn column = [self columnFromString:key];
            if (key && column < ZBPackageColumnCount) {
                char *value = strtok(NULL, ":");
                if (value && value[0] == ' ') value++;
                if (value) strcpy(package[column], value);
            }
        }
    }
    [databaseManager endTransaction];
    free_package(package);
    fclose(file);
    
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

- (NSArray <ZBBasePackage *> *)packagesFromSource:(ZBSource *)source {
    return [[ZBDatabaseManager sharedInstance] packagesMatchingFilters:@"source == 1"];
}



@end
