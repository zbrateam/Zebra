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

- (void)importPackagesFromFile:(NSString *)path toSource:(ZBSource *)source {
    if (!path) return;
    
    NSDate *methodStart = [NSDate date];
    uuids = [[databaseManager uniqueIdentifiersForPackagesFromSource:source] mutableCopy];
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"%@ ID fetch executionTime = %f", source.origin, executionTime);
    
    currentUpdateDate = (sqlite3_int64)[[NSDate date] timeIntervalSince1970];
    
    NSData *packagesData = [NSData dataWithContentsOfFile:path];
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
    
    [databaseManager deletePackagesWithUniqueIdentifiers:uuids];
    [uuids removeAllObjects];
}

- (void)importPackage:(NSData *)data toSource:(ZBSource *)source {
    NSMutableDictionary *packageDictionary = [NSMutableDictionary new];
    
    NSString *control = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [control enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        NSRange colonLocation = [line rangeOfString:@":"];
        if (colonLocation.location != NSNotFound) {
            NSString *key = [line substringWithRange:NSMakeRange(0, colonLocation.location)];
            NSString *value = [line substringWithRange:NSMakeRange(colonLocation.location + 2, line.length - colonLocation.location - 2)];
            
            packageDictionary[key] = value;
        }
    }];
    
    if (packageDictionary[@"Package"]) {
        if (!packageDictionary[@"Name"]) packageDictionary[@"Name"] = packageDictionary[@"Package"];
        
        NSString *uniqueIdentifier = [NSString stringWithFormat:@"%@-%@-%@", packageDictionary[@"Package"], packageDictionary[@"Version"], source.baseFilename];
        if (![uuids containsObject:uniqueIdentifier]) {
            packageDictionary[@"Source"] = source.baseFilename;
            packageDictionary[@"UUID"] = uniqueIdentifier;
            packageDictionary[@"Date"] = @(currentUpdateDate);
            
            [databaseManager insertPackage:packageDictionary];
            [uuids removeObject:uniqueIdentifier];
        } else {
            [uuids removeObject:uniqueIdentifier];
        }
    }
}

- (NSArray <ZBBasePackage *> *)packagesFromSource:(ZBSource *)source {
    return [[ZBDatabaseManager sharedInstance] packagesMatchingFilters:@"source == 1"];
}



@end
