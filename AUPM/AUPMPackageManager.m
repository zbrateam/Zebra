//
//  AUPMPackageManager.m
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "AUPMPackageManager.h"
#import "AUPMPackage.h"

@implementation AUPMPackageManager

NSArray *packages_to_array(const char *path);

//Parse installed package list from dpkg and create an AUPMPackage for each one and return an array
- (NSArray *)installedPackageList {
#ifdef DEBUG
    NSString *dbPath = [[NSBundle mainBundle] pathForResource:@"status" ofType:@"tx"];
#else
    NSString *dbPath = @"/var/lib/dpkg/status";
#endif
    NSArray *packageArray = packages_to_array([dbPath UTF8String]);
    NSMutableArray *installedPackageList = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dict in packageArray) {
        AUPMPackage *package = [[AUPMPackage alloc] init];
        if (dict[@"Name"] == NULL) {
            package.packageName = [dict[@"Package"] substringToIndex:[dict[@"Package"] length] - 1];
        }
        else {
            package.packageName = [dict[@"Name"] substringToIndex:[dict[@"Name"] length] - 1];
        }
        
        package.packageIdentifier = [dict[@"Package"] substringToIndex:[dict[@"Package"] length] - 1];
        package.version = [dict[@"Version"] substringToIndex:[dict[@"Version"] length] - 1];
        package.section = [dict[@"Section"] substringToIndex:[dict[@"Section"] length] - 1];
        package.packageDescription = [dict[@"Description"] substringToIndex:[dict[@"Description"] length] - 1];
        package.repoVersion = [NSString stringWithFormat:@"local~%@", dict[@"Package"]];
        
        package.tags = [dict[@"Tag"] substringToIndex:[dict[@"Tag"] length] - 1];
        
        NSString *urlString = [dict[@"Depiction"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        urlString = [urlString substringToIndex:[urlString length] - 3]; //idk why this is here
        package.depictionURL = urlString;
        package.installed = true;
        
        if ([dict[@"Status"] rangeOfString:@"deinstall"].location == NSNotFound && [dict[@"Status"] rangeOfString:@"not-installed"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"saffron-jailbreak"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"gsc"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"cy+"].location == NSNotFound) {
            [installedPackageList addObject:package];
        }
    }
    
    NSSortDescriptor *sortByPackageName = [NSSortDescriptor sortDescriptorWithKey:@"packageName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByPackageName];
    
    return (NSArray*)[installedPackageList sortedArrayUsingDescriptors:sortDescriptors];
}

//- (NSArray *)filesInstalledByPackage:(AUPMPackage *)package {
//    NSTask *checkFilesTask = [[NSTask alloc] init];
//    [checkFilesTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
//    NSArray *filesArgs = [[NSArray alloc] initWithObjects: @"dpkg", @"-L", [package packageIdentifier], nil];
//    [checkFilesTask setArguments:filesArgs];
//    
//    NSPipe * out = [NSPipe pipe];
//    [checkFilesTask setStandardOutput:out];
//    
//    [checkFilesTask launch];
//    [checkFilesTask waitUntilExit];
//    
//    NSFileHandle *read = [out fileHandleForReading];
//    NSData *dataRead = [read readDataToEndOfFile];
//    NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
//    
//    return [stringRead componentsSeparatedByString: @"\n"];
//}
//
//- (BOOL)packageHasTweak:(AUPMPackage *)package {
//    NSArray *files = [self filesInstalledByPackage:package];
//    
//    for (NSString *path in files) {
//        if ([path rangeOfString:@"/Library/MobileSubstrate/DynamicLibraries"].location != NSNotFound) {
//            if ([path rangeOfString:@".dylib"].location != NSNotFound) {
//                return true;
//            }
//        }
//    }
//    return false;
//}
//
//- (BOOL)packageHasApp:(AUPMPackage *)package {
//    NSArray *files = [self filesInstalledByPackage:package];
//    
//    for (NSString *path in files) {
//        if ([path rangeOfString:@".app/Info.plist"].location != NSNotFound) {
//            return true;
//        }
//    }
//    return false;
//}

@end
