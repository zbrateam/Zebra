//
//  ZBSourceManager.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBSourceManager.h"
@import UIKit.UIDevice;
#import <Tabs/Sources/Helpers/ZBSource.h>
#import <Database/ZBDatabaseManager.h>
#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <ZBLog.h>

@interface ZBSourceManager () {
    NSArray <ZBSource *> *sourceCache;
    BOOL recachingNeeded;
}
@end

@implementation ZBSourceManager

//@synthesize verifiedSources;

+ (id)sharedInstance {
    static ZBSourceManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ZBSourceManager new];
    });
    return instance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        recachingNeeded = YES;
    }
    
    return self;
}

- (NSArray <ZBSource *> *)sources {
    if (!recachingNeeded)
        return sourceCache;
    
    recachingNeeded = NO;
    NSError *readError = NULL;
    NSSet *baseSources = [ZBBaseSource baseSourcesFromList:[ZBAppDelegate sourcesListURL] error:&readError];
    if (readError) {
        ZBLog(@"[Zebra] Error when reading baseSourcse from %@: %@", [ZBAppDelegate sourcesListURL], readError.localizedDescription);
        
        return [NSArray new];
    }
    NSSet *sourcesFromDatabase = [[ZBDatabaseManager sharedInstance] sources];
    
    NSSet *unionSet = [sourcesFromDatabase setByAddingObjectsFromSet:baseSources];
    sourceCache = [unionSet sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"label" ascending:TRUE selector:@selector(localizedCaseInsensitiveCompare:)]]];
    
    return sourceCache;
}

//TODO: This needs error pointers
- (void)addBaseSources:(NSSet <ZBBaseSource *> *)baseSources {
    NSError *readError = NULL;
    NSSet <ZBBaseSource *> *currentSources = [ZBBaseSource baseSourcesFromList:[ZBAppDelegate sourcesListURL] error:&readError];
    
    NSMutableSet *sourcesToAdd = [baseSources mutableCopy];
    for (ZBBaseSource *source in baseSources) {
        if ([currentSources containsObject:source]) {
            ZBLog(@"[Zebra] %@ is already contained in list", source.repositoryURI);
            [sourcesToAdd removeObject:source];
        }
    }
    
    if ([sourcesToAdd count]) {
        [self appendBaseSources:sourcesToAdd toFile:[ZBAppDelegate sourcesListPath]];
        
        //TODO: Send out source added notification
    }
}

- (void)deleteSource:(ZBSource *)source {
    if ([source canDelete]) {
        [self deleteBaseSource:source];
        
        if ([source isKindOfClass:[ZBSource class]]) {
            ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
            [databaseManager deleteSource:source];
        }
    }
}

- (void)deleteBaseSource:(ZBBaseSource *)source {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    
    NSMutableSet *sourcesToWrite = [[databaseManager sources] mutableCopy];
    [sourcesToWrite removeObject:source];
    
    [self writeBaseSources:sourcesToWrite toFile:[ZBAppDelegate sourcesListPath]];
    
    //Delete .list file (if it exists)
    NSArray *lists = [self sourceLists:source];
    for (NSString *list in lists) {
        NSString *path = [[ZBAppDelegate listsLocation] stringByAppendingPathComponent:list];
        NSError *error = NULL;
        if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            if (!success) {
                NSLog(@"Error removing file at path: %@", error.localizedDescription);
            }
        }
    }
    
    //Delete files from featured.plist (if they exist)
    NSMutableDictionary *featured = [NSMutableDictionary dictionaryWithContentsOfFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"]];
    if ([featured objectForKey:[source baseFilename]]) {
        [featured removeObjectForKey:[source baseFilename]];
    }
    [featured writeToFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"] atomically:NO];
    
    //TODO: Send out source update notificaiton
}

//TODO: This needs error pointers
- (void)appendBaseSources:(NSSet <ZBBaseSource *> *)sources toFile:(NSString *)filePath {
    NSError *error = NULL;
    NSString *contents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"[Zebra] ERROR while loading from sources.list: %@", error);
        return;
    }
    else {
        NSMutableArray *debLines = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"\n# Added at %@\n", [NSDate date]]];
        for (ZBBaseSource *baseSource in sources) {
            [debLines addObject:[baseSource debLine]];
        }
        contents = [contents stringByAppendingString:[debLines componentsJoinedByString:@""]];
        [contents writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            NSLog(@"[Zebra] Error while writing sources to file: %@", error);
        }
    }
}

- (void)writeBaseSources:(NSSet <ZBBaseSource *> *)sources toFile:(NSString *)filePath {
    NSMutableArray *debLines = [NSMutableArray new];
    for (ZBBaseSource *baseSource in sources) {
        [debLines addObject:[baseSource debLine]];
    }
    
    NSError *error = NULL;
    [[debLines componentsJoinedByString:@""] writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error != NULL) {
        NSLog(@"[Zebra] Error while writing sources to file: %@", error);
    }
    
    recachingNeeded = YES;
}

- (void)verifySources:(NSSet <ZBBaseSource *> *)sources delegate:(id <ZBSourceVerificationDelegate>)delegate {
    if ([delegate respondsToSelector:@selector(startedSourceVerification:)]) [delegate startedSourceVerification:sources.count > 1];
    
    NSUInteger sourcesToVerify = sources.count;
    NSMutableArray *existingSources = [NSMutableArray new];
    NSMutableArray *imaginarySources = [NSMutableArray new];
    
    for (ZBBaseSource *source in sources) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [source verify:^(ZBSourceVerificationStatus status) {
                if ([delegate respondsToSelector:@selector(source:status:)]) [delegate source:source status:status];
                
                if (status == ZBSourceExists) {
                    [existingSources addObject:source];
                }
                else if (status == ZBSourceImaginary) {
                    [imaginarySources addObject:source];
                }
                
                if ([delegate respondsToSelector:@selector(finishedSourceVerification:imaginarySources:)] && sourcesToVerify == existingSources.count + imaginarySources.count) {
                    [delegate finishedSourceVerification:existingSources imaginarySources:imaginarySources];
                }
            }];
        });
    }
}

- (NSArray <NSString *> *)sourceLists:(ZBBaseSource *)source {
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[ZBAppDelegate listsLocation] error:nil];
    
    return [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[cd] %@", [source baseFilename]]];
}

- (ZBSource *)sourceMatchingSourceID:(int)sourceID {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sourceID == %d", sourceID];
    NSArray *filteredArray = [sourceCache filteredArrayUsingPredicate:predicate];
    if (!filteredArray.count) {
        // If we can't find the source in sourceManager, lets just recache and see if it shows up
        // TODO: Send out source update notification
        filteredArray = [sourceCache filteredArrayUsingPredicate:predicate];
    }
    
    return filteredArray[0];
}


@end
