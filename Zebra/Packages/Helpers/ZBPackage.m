//
//  ZBPackage.m
//  Zebra
//
//  Created by Wilson Styres on 2/2/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackage.h"
#import <Parsel/dpkgver.h>
#import <Repos/Helpers/ZBRepo.h>
#import <ZBAppDelegate.h>

@implementation ZBPackage

@synthesize identifier;
@synthesize name;
@synthesize version;
@synthesize desc;
@synthesize section;
@synthesize depictionURL;
@synthesize tags;
@synthesize dependsOn;
@synthesize conflictsWith;
@synthesize author;
@synthesize repo;
@synthesize filename;

- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name version:(NSString *)version description:(NSString *)desc section:(NSString *)section depictionURL:(NSString *)url {
    
    self = [super init];
    
    if (self) {
        [self setIdentifier:identifier];
        [self setName:name];
        [self setVersion:version];
        [self setDesc:desc];
        [self setSection:section];
        [self setDepictionURL:[NSURL URLWithString:url]];
    }
    
    return self;
}

- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement {
    self = [super init];
    
    if (self) {
        const char *packageIDChars =   (const char *)sqlite3_column_text(statement, 0);
        const char *packageNameChars = (const char *)sqlite3_column_text(statement, 1);
        const char *versionChars =     (const char *)sqlite3_column_text(statement, 2);
        const char *descriptionChars = (const char *)sqlite3_column_text(statement, 3);
        const char *sectionChars =     (const char *)sqlite3_column_text(statement, 4);
        const char *depictionChars =   (const char *)sqlite3_column_text(statement, 5);
        const char *tagChars =         (const char *)sqlite3_column_text(statement, 6);
        const char *dependsChars =     (const char *)sqlite3_column_text(statement, 7);
        const char *conflictsChars =   (const char *)sqlite3_column_text(statement, 8);
        const char *authorChars =      (const char *)sqlite3_column_text(statement, 9);
        const char *filenameChars =    (const char *)sqlite3_column_text(statement, 11);
        
        [self setIdentifier:[NSString stringWithUTF8String:packageIDChars]]; //This should never be NULL
        [self setName:[NSString stringWithUTF8String:packageNameChars]]; //This should never be NULL
        [self setVersion:[NSString stringWithUTF8String:versionChars]]; //This should never be NULL
        [self setDesc:descriptionChars != 0 ? [NSString stringWithUTF8String:descriptionChars] : NULL];
        [self setSection:sectionChars != 0 ? [NSString stringWithUTF8String:sectionChars] : NULL];
        [self setDepictionURL:depictionChars != 0 ? [NSURL URLWithString:[NSString stringWithUTF8String:depictionChars]] : NULL];
        [self setAuthor:authorChars != 0 ? [NSString stringWithUTF8String:authorChars] : NULL];
        [self setFilename:filenameChars != 0? [NSString stringWithUTF8String:filenameChars] : NULL];
        
        [self setTags:tagChars != 0 ? [[NSString stringWithUTF8String:tagChars] componentsSeparatedByString:@", "] : NULL];
        if ([tags count] == 1 && [tags[0] containsString:@","]) { //Fix crimes against humanity @Dnasty
            tags = [tags[0] componentsSeparatedByString:@","];
        }
        
        [self setDependsOn:dependsChars != 0 ? [[NSString stringWithUTF8String:dependsChars] componentsSeparatedByString:@", "] : NULL];
        if ([dependsOn count] == 1 && [dependsOn[0] containsString:@","]) { //Fix crimes against humanity @Dnasty
            dependsOn = [dependsOn[0] componentsSeparatedByString:@","];
        }
        
        [self setConflictsWith:conflictsChars != 0 ? [[NSString stringWithUTF8String:conflictsChars] componentsSeparatedByString:@", "] : NULL];
        if ([conflictsWith count] == 1 && [conflictsWith[0] containsString:@","]) { //Fix crimes against humanity @Dnasty
            conflictsWith = [conflictsWith[0] componentsSeparatedByString:@","];
        }
        
        int repoID = sqlite3_column_int(statement, 12);
        if (repoID > 0) {
            [self setRepo:[ZBRepo repoMatchingRepoID:repoID]];
        }
        else {
            [self setRepo:[ZBRepo localRepo]];
        }
    }
    
    return self;
}

- (BOOL)isEqual:(ZBPackage *)object {
    if (self == object)
        return TRUE;
    
    if (![object isKindOfClass:[ZBPackage class]])
        return FALSE;
    
    return ([[object identifier] isEqual:[self identifier]] && [[object version] isEqual:[self version]]);
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ (%@) V%@", name, identifier, version];
}

- (NSComparisonResult)compare:(id)object {
    if ([object isKindOfClass:[ZBPackage class]]) {
        ZBPackage *obj = (ZBPackage *)object;
        if ([self isEqual:obj])
            return NSOrderedSame;
        
        if (verrevcmp([[self version] UTF8String], [[obj version] UTF8String]) < 0)
            return NSOrderedAscending;
        else
            return NSOrderedDescending;
    }
    else {
        if (verrevcmp([[self version] UTF8String], [(NSString *)object UTF8String]) < 0)
            return NSOrderedAscending;
        else if (verrevcmp([[self version] UTF8String], [(NSString *)object UTF8String]) > 0)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }
}

- (BOOL)isPaid {
    return [tags containsObject:@"cydia::commercial"];
}

- (NSString *)getField:(NSString *)field {
    NSString *value;
    
    ZBRepo *repo = [self repo];
    
    if (repo == NULL) return NULL;
    
    NSString *listsLocation = [ZBAppDelegate listsLocation];
    NSString *filename = [NSString stringWithFormat:@"%@/%@%@", listsLocation, [repo baseFileName], @"_Packages"];
    NSFileManager *filemanager = [NSFileManager defaultManager];
    
    if (![filemanager fileExistsAtPath:filename]) {
        filename = [NSString stringWithFormat:@"%@/%@%@", listsLocation, [repo baseFileName], @"_main_binary-iphoneos-arm_Packages"];
        
        if (![filemanager fileExistsAtPath:filename]) {
            return NULL;
        }
    }
    
    NSString *packageIdentifier = [[self identifier] stringByAppendingString:@"\n"];
    
    NSError *readError;
    NSString *contents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&readError];
    
    if (readError != NULL) {
        NSLog(@"Error: %@", readError);
        
        return readError.localizedDescription;
    }
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:contents];
    [scanner scanUpToString:packageIdentifier intoString:NULL];
    NSString *packageInfo;
    [scanner scanUpToString:@"\n\n" intoString:&packageInfo];
    if (packageInfo == NULL) return NULL;
    scanner = [[NSScanner alloc] initWithString:packageInfo];
    [scanner scanUpToString:[field stringByAppendingString:@": "] intoString:NULL];
    [scanner scanUpToString:@"\n" intoString:&value];
    
    return [[value componentsSeparatedByString:@": "] objectAtIndex:1];
}

@end
