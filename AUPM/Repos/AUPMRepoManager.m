//
//  AUPMRepoManager.m
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "AUPMRepoManager.h"
#import "AUPMRepo.h"
#import "AUPMPackage.h"
#import "NSTask.h"
#import "AUPMDatabaseManager.h"
#import "AUPMAppDelegate.h"
#include "../Parser/dpkgver.c"

@interface AUPMRepoManager ()
@property (nonatomic, retain) NSMutableArray *repos;
@end

@implementation AUPMRepoManager

NSArray *packages_to_array(const char *path);
//
//+ (id)sharedInstance {
//    static AUPMRepoManager *instance = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        instance = [AUPMRepoManager new];
//    });
//    return instance;
//}

- (id)init {
    self = [super init];
    
    if (self) {
        self.repos = [[self managedRepoList] mutableCopy];
    }
    
    return self;
}

#ifdef DEBUG
- (NSArray *)basicRelease {
    NSMutableArray *array = [NSMutableArray new];
    NSError *readError;
    NSString *path = @"xtm3x.github.io_repo_._Release";
    NSString *content = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"xtm3x.github.io_repo_._Release" ofType:@"tx"] encoding:NSUTF8StringEncoding error:&readError];
    
    if (readError != nil)
    {
        NSLog(@"[AUPM] Error while reading repo: %@", readError);
    }
    
    NSString *trimmedString = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *keyValuePairs = [trimmedString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    for (NSString *keyValuePair in keyValuePairs) {
        NSString *trimmedPair = [keyValuePair stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        NSArray *keyValues = [trimmedPair componentsSeparatedByString:@":"];
        
        dict[[keyValues.firstObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]] = [keyValues.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    AUPMRepo *repo = [[AUPMRepo alloc] init];
    
    repo.repoName = dict[@"Origin"];
    repo.repoDescription = dict[@"Description"];
    repo.suite = dict[@"Suite"];
    repo.components = dict[@"Components"];
    
    NSString *baseFileName = [path stringByReplacingOccurrencesOfString:@"_Release" withString:@""];
    repo.repoBaseFileName = baseFileName;
    
    NSString *fullRepoURL = baseFileName;
    fullRepoURL = [fullRepoURL stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    repo.fullURL = fullRepoURL; //Store full URL for cydia icon
    
    NSString *repoURL = [fullRepoURL copy];
    if ([repoURL rangeOfString:@"dists"].location != NSNotFound) {
        NSArray *urlsep = [repoURL componentsSeparatedByString:@"dists"];
        repoURL = [urlsep objectAtIndex:0];
        repoURL = [repoURL stringByAppendingString:@"/"];
    }
    repoURL = [NSString stringWithFormat:@"http://%@", repoURL];
    repoURL = [repoURL substringToIndex:[repoURL length] - 1];
    repo.repoURL = repoURL;
    
    NSError *error;
    NSURL *iconURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/CydiaIcon.png", fullRepoURL]];
    NSData *iconData = [NSData dataWithContentsOfURL:iconURL options:NSDataReadingUncached error:&error];
    if (error != nil) {
        NSLog(@"Error while getting icon: %@", error);
    }
    repo.icon = iconData;
    
    if ([baseFileName rangeOfString:@"saurik"].location != NSNotFound || [baseFileName rangeOfString:@"bigboss"].location != NSNotFound || [baseFileName rangeOfString:@"zodttd"].location != NSNotFound) {
        repo.defaultRepo = true;
    }
    
    [array addObject:repo];

    NSSortDescriptor *sortByRepoName = [NSSortDescriptor sortDescriptorWithKey:@"repoName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByRepoName];

    return (NSArray*)[array sortedArrayUsingDescriptors:sortDescriptors];
}
#endif

- (NSArray *)managedRepoList {
#ifdef DEBUG
    NSLog(@"[AUPM] basic ! debug!");
    return [self basicRelease];
#endif
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *aptListDirectory = @"/var/lib/aupm/lists";
    NSArray *listOfFiles = [fileManager contentsOfDirectoryAtPath:aptListDirectory error:nil];
    NSMutableArray *managedRepoList = [[NSMutableArray alloc] init];
    
    for (NSString *path in listOfFiles) {
        if (([path rangeOfString:@"Release"].location != NSNotFound) && ([path rangeOfString:@".gpg"].location == NSNotFound)) {
            NSString *fullPath = [NSString stringWithFormat:@"/var/lib/aupm/lists/%@", path];
            NSError *readError;
            NSString *content = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&readError];
            
            if (readError != nil)
            {
                NSLog(@"[AUPM] Error while reading repo: %@", readError);
            }
            
            NSString *trimmedString = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSArray *keyValuePairs = [trimmedString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            
            for (NSString *keyValuePair in keyValuePairs) {
                NSString *trimmedPair = [keyValuePair stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                NSArray *keyValues = [trimmedPair componentsSeparatedByString:@":"];
                
                dict[[keyValues.firstObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]] = [keyValues.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }
            
            AUPMRepo *repo = [[AUPMRepo alloc] init];
            
            repo.repoName = dict[@"Origin"];
            repo.repoDescription = dict[@"Description"];
            repo.suite = dict[@"Suite"];
            repo.components = dict[@"Components"];
            
            NSString *baseFileName = [path stringByReplacingOccurrencesOfString:@"_Release" withString:@""];
            repo.repoBaseFileName = baseFileName;
            
            NSString *fullRepoURL = baseFileName;
            fullRepoURL = [fullRepoURL stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
            repo.fullURL = fullRepoURL; //Store full URL for cydia icon
            
            NSString *repoURL = [fullRepoURL copy];
            if ([repoURL rangeOfString:@"dists"].location != NSNotFound) {
                NSArray *urlsep = [repoURL componentsSeparatedByString:@"dists"];
                repoURL = [urlsep objectAtIndex:0];
                repoURL = [repoURL stringByAppendingString:@"/"];
            }
            repoURL = [NSString stringWithFormat:@"http://%@", repoURL];
            repoURL = [repoURL substringToIndex:[repoURL length] - 1];
            repo.repoURL = repoURL;
            
            NSError *error;
            NSURL *iconURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/CydiaIcon.png", fullRepoURL]];
            NSData *iconData = [NSData dataWithContentsOfURL:iconURL options:NSDataReadingUncached error:&error];
            if (error != nil) {
                NSLog(@"Error while getting icon: %@", error);
            }
            repo.icon = iconData;
            
            if ([baseFileName rangeOfString:@"saurik"].location != NSNotFound || [baseFileName rangeOfString:@"bigboss"].location != NSNotFound || [baseFileName rangeOfString:@"zodttd"].location != NSNotFound) {
                repo.defaultRepo = true;
            }
            
            [managedRepoList addObject:repo];
        }
    }
    
    NSSortDescriptor *sortByRepoName = [NSSortDescriptor sortDescriptorWithKey:@"repoName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByRepoName];
    
    return (NSArray*)[managedRepoList sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)cleanUpDuplicatePackages:(NSArray *)packageList {
    NSMutableDictionary *packageVersionDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *cleanedPackageList = [packageList mutableCopy];
    
    for (AUPMPackage *package in packageList) {
        if (packageVersionDict[[package packageIdentifier]] == NULL) {
            packageVersionDict[[package packageIdentifier]] = package;
        }
        
        NSString *arrayVersion = [(AUPMPackage *)packageVersionDict[[package packageIdentifier]] version];
        NSString *packageVersion = [package version];
        int result = verrevcmp([packageVersion UTF8String], [arrayVersion UTF8String]);
        
        if (result > 0) {
            [cleanedPackageList removeObject:packageVersionDict[[package packageIdentifier]]];
            packageVersionDict[[package packageIdentifier]] = package;
        }
        else if (result < 0) {
            [cleanedPackageList removeObject:package];
        }
    }
    
    return (NSArray *)cleanedPackageList;
}

- (NSArray<AUPMPackage *> *)basicPackages:(AUPMRepo *)repo {
    NSDate *methodStart = [NSDate date];
    NSString *cachedPackagesFile = [[NSBundle mainBundle] pathForResource:@"Packages" ofType:@"tx"];
    
    NSArray *packageArray = packages_to_array([cachedPackagesFile UTF8String]);
    NSMutableArray<AUPMPackage *> *packageListForRepo = [[NSMutableArray alloc] init];
    
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
        package.repoVersion = [NSString stringWithFormat:@"%@~%@", [repo repoBaseFileName], dict[@"Package"]];
        package.repo = repo;
        
        NSString *urlString = [dict[@"Depiction"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        urlString = [urlString substringToIndex:[urlString length] - 3]; //idk why this is here
        package.depictionURL = urlString;
        
        if ([dict[@"Package"] rangeOfString:@"gsc"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"saffron-jailbreak"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"cy+"].location == NSNotFound) {
            [packageListForRepo addObject:package];
        }
    }
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"[AUPM] Time to parse %@ package files: %f seconds", [repo repoName], executionTime);
    
    NSArray *cleanedArray = (NSArray *)[self cleanUpDuplicatePackages:packageListForRepo];
    NSSortDescriptor *sortByPackageName = [NSSortDescriptor sortDescriptorWithKey:@"packageName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByPackageName];
    
    return [cleanedArray sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray<AUPMPackage *> *)packageListForRepo:(AUPMRepo *)repo {
#ifdef DEBUG
    return [self basicPackages:repo];
#endif
    NSDate *methodStart = [NSDate date];
    NSString *cachedPackagesFile = [NSString stringWithFormat:@"/var/lib/aupm/lists/%@_Packages", [repo repoBaseFileName]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachedPackagesFile]) {
        cachedPackagesFile = [NSString stringWithFormat:@"/var/lib/aupm/lists/%@_main_binary-iphoneos-arm_Packages", [repo repoBaseFileName]]; //Do some funky package file with the default repos
    }
    
    NSArray *packageArray = packages_to_array([cachedPackagesFile UTF8String]);
    NSMutableArray<AUPMPackage *> *packageListForRepo = [[NSMutableArray alloc] init];
    
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
        package.repoVersion = [NSString stringWithFormat:@"%@~%@", [repo repoBaseFileName], dict[@"Package"]];
        package.repo = repo;
        
        NSString *urlString = [dict[@"Depiction"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        urlString = [urlString substringToIndex:[urlString length] - 3]; //idk why this is here
        package.depictionURL = urlString;
        
        if ([dict[@"Package"] rangeOfString:@"gsc"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"saffron-jailbreak"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"cy+"].location == NSNotFound) {
            [packageListForRepo addObject:package];
        }
    }
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"[AUPM] Time to parse %@ package files: %f seconds", [repo repoName], executionTime);
    
    NSArray *cleanedArray = (NSArray *)[self cleanUpDuplicatePackages:packageListForRepo];
    NSSortDescriptor *sortByPackageName = [NSSortDescriptor sortDescriptorWithKey:@"packageName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByPackageName];
    
    return [cleanedArray sortedArrayUsingDescriptors:sortDescriptors];
}

- (void)addSource:(NSURL *)sourceURL completion:(void (^)(BOOL success))completion {
    NSString *URL = [sourceURL absoluteString];
    NSString *output = @"";
    
    for (AUPMRepo *repo in _repos) {
        if ([repo defaultRepo]) {
            if ([[repo repoName] isEqual:@"Cydia/Telesphoreo"]) {
                output = [output stringByAppendingFormat:@"deb http://apt.saurik.com/ ios/%.2f main\n",kCFCoreFoundationVersionNumber];
            }
            else {
                output = [output stringByAppendingFormat:@"deb %@ %@ %@\n", [repo repoURL], [repo suite], [repo components]];
            }
        }
        else {
            output = [output stringByAppendingFormat:@"deb %@ ./\n", [repo repoURL]];
        }
    }
    output = [output stringByAppendingFormat:@"deb %@ ./\n", URL];
    
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
    NSString *filePath = [documentPath stringByAppendingString:@"aupm.list"];
    
    NSError *error;
    [output writeToFile:filePath atomically:TRUE encoding:NSUTF8StringEncoding error:&error];
    if (error != NULL) {
        NSLog(@"[AUPM] Error while writing sources to file: %@", error);
        completion(false);
    }
    else {
#if TARGET_CPU_ARM
        NSTask *updateListTask = [[NSTask alloc] init];
        [updateListTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
        NSArray *updateArgs = [[NSArray alloc] initWithObjects:@"cp", filePath, @"/var/lib/aupm/aupm.list", nil];
        [updateListTask setArguments:updateArgs];
        
        [updateListTask launch];
        [updateListTask waitUntilExit];
        
#endif
        completion(true);
    }
}

- (void)deleteSource:(AUPMRepo *)delRepo {
    NSString *output = @"";
    for (AUPMRepo *repo in _repos) {
        if (![[delRepo repoBaseFileName] isEqual:[repo repoBaseFileName]]) {
            if ([repo defaultRepo]) {
                if ([[repo repoName] isEqual:@"Cydia/Telesphoreo"]) {
                    output = [output stringByAppendingFormat:@"deb http://apt.saurik.com/ ios/%.2f main\n",kCFCoreFoundationVersionNumber];
                }
                else {
                    output = [output stringByAppendingFormat:@"deb %@ %@ %@\n", [repo repoURL], [repo suite], [repo components]];
                }
            }
            else {
                output = [output stringByAppendingFormat:@"deb %@ ./\n", [repo repoURL]];
            }
        }
    }
    
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
    NSString *filePath = [documentPath stringByAppendingString:@"aupm.list"];
    
    NSError *error;
    [output writeToFile:filePath atomically:TRUE encoding:NSUTF8StringEncoding error:&error];
    if (error != NULL) {
        NSLog(@"[AUPM] Error while writing sources to file: %@", error);
    }
    else {
        NSTask *updateListTask = [[NSTask alloc] init];
        [updateListTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
        NSArray *updateArgs = [[NSArray alloc] initWithObjects:@"cp", filePath, @"/var/lib/aupm/aupm.list", nil];
        [updateListTask setArguments:updateArgs];
        
        [updateListTask launch];
        [updateListTask waitUntilExit];
        
        AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
        [databaseManager deleteRepo:delRepo];
    }
}

@end
