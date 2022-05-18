//
//  ZBSource.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBSource.h"
#import "ZBSourceManager.h"
#import "ZBDatabaseManager.h"
#import "ZBColumn.h"
#import "ZBUtils.h"
#import "ZBPaymentVendor.h"

@interface ZBSource () {
    NSURL *paymentVendorURI;
}
@end

@implementation ZBSource

@synthesize sourceDescription;
@synthesize origin;
@synthesize version;
@synthesize suite;
@synthesize codename;
@synthesize architectures;
@synthesize sourceID;

const char *textColumn(sqlite3_stmt *statement, int column) {
    return (const char *)sqlite3_column_text(statement, column);
}

+ (ZBSource *)sourceMatchingSourceID:(int)sourceID {
    ZBSource *possibleSource = [[ZBSourceManager sharedInstance] sources][@(sourceID)];
    if (!possibleSource) {
        // If we can't find the source in sourceManager, lets just recache and see if it shows up
        [[ZBSourceManager sharedInstance] needRecaching];
        
        // If it still fails, check the database but since we're already checking the database in sourceManager, it is unlikely we will find it
        possibleSource = [[ZBSourceManager sharedInstance] sources][@(sourceID)] ?: [[ZBDatabaseManager sharedInstance] sourceFromSourceID:sourceID];
    }
    
    return possibleSource;
}

+ (ZBSource *)localSource:(int)sourceID {
    ZBSource *local = [[ZBSource alloc] init];
    [local setOrigin:sourceID == -2 ? NSLocalizedString(@"Local File", @"") : NSLocalizedString(@"Local Repository", @"")];
    [local setLabel:local.origin];
    [local setSourceDescription:NSLocalizedString(@"Locally installed packages", @"")];
    [local setSourceID:sourceID];
    [local setBaseFilename:@"/var/lib/dpkg/status"];
    return local;
}

+ (ZBSource *)sourceFromBaseURL:(NSString *)baseURL {
    return [[ZBDatabaseManager sharedInstance] sourceFromBaseURL:baseURL];
}

+ (ZBSource *)sourceFromBaseFilename:(NSString *)baseFilename {
    return [[ZBDatabaseManager sharedInstance] sourceFromBaseFilename:baseFilename];
}

+ (BOOL)exists:(NSString *)urlString {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    return [databaseManager sourceIDFromBaseURL:urlString strict:NO] > 0;
}

+ (UIImage *)imageForSection:(NSString *)section {
    NSString *imageName = [section stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    if ([imageName containsString:@"("]) {
        NSArray *components = [imageName componentsSeparatedByString:@"_("];
        if ([components count] < 2) {
            components = [imageName componentsSeparatedByString:@"("];
        }
        imageName = components[0];
    }
    
    UIImage *sectionImage = [UIImage imageNamed:imageName] ?: [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Applications/Zebra.app/Sections/%@.png", imageName]] ?: [UIImage imageNamed:@"Other"];
    return sectionImage;
}

- (id)initWithSQLiteStatement:(sqlite3_stmt *)statement {
    const char *archiveTypeChars   = textColumn(statement, ZBSourceColumnArchiveType);
    const char *repositoryURIChars = textColumn(statement, ZBSourceColumnRepositoryURI);
    const char *distributionChars  = textColumn(statement, ZBSourceColumnDistribution);
    const char *componenetsChars   = textColumn(statement, ZBSourceColumnComponents);
    
    NSArray *components;
    if (componenetsChars != 0 && strcmp(componenetsChars, "") != 0) {
        components = [[NSString stringWithUTF8String:componenetsChars] componentsSeparatedByString:@" "];
    }
    
    self = [super initWithArchiveType:archiveTypeChars != 0 ? [NSString stringWithUTF8String:archiveTypeChars] : @"deb" repositoryURI:[NSString stringWithUTF8String:repositoryURIChars] distribution:[NSString stringWithUTF8String:distributionChars] components:components];
    
    if (self) {
        const char *descriptionChars   = textColumn(statement, ZBSourceColumnDescription);
        const char *originChars        = textColumn(statement, ZBSourceColumnOrigin);
        const char *labelChars         = textColumn(statement, ZBSourceColumnLabel);
        const char *versionChars       = textColumn(statement, ZBSourceColumnVersion);
        const char *suiteChars         = textColumn(statement, ZBSourceColumnSuite);
        const char *codenameChars      = textColumn(statement, ZBSourceColumnCodename);
        const char *architectureChars  = textColumn(statement, ZBSourceColumnArchitectures);
        const char *vendorChars        = textColumn(statement, ZBSourceColumnPaymentVendor);
        const char *baseFilenameChars  = textColumn(statement, ZBSourceColumnBaseFilename);
        
        [self setSourceDescription:descriptionChars != 0 ? [[NSString alloc] initWithUTF8String:descriptionChars] : NULL];
        [self setOrigin:originChars != 0 ? [[NSString alloc] initWithUTF8String:originChars] : NSLocalizedString(@"Unknown", @"")];
        [self setLabel:[ZBUtils decodeCString:labelChars fallback:NSLocalizedString(@"Unknown", @"")]];
        [self setVersion:versionChars != 0 ? [[NSString alloc] initWithUTF8String:versionChars] : NSLocalizedString(@"Unknown", @"")];
        [self setSuite:suiteChars != 0 ? [[NSString alloc] initWithUTF8String:suiteChars] : NSLocalizedString(@"Unknown", @"")];
        [self setCodename:codenameChars != 0 ? [[NSString alloc] initWithUTF8String:codenameChars] : NSLocalizedString(@"Unknown", @"")];
        
        if (vendorChars != 0) {
            NSString *vendor = [[[NSString alloc] initWithUTF8String:vendorChars] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            self->paymentVendorURI = [[NSURL alloc] initWithString:vendor];
        }
        
        if (architectureChars != 0) {
            NSArray *architectures = [[NSString stringWithUTF8String:architectureChars] componentsSeparatedByString:@" "];
            [self setArchitectures:architectures];
        }
        else {
            [self setArchitectures:@[@"all"]];
        }
        
        [self setBaseFilename:baseFilenameChars != 0 ? [[NSString alloc] initWithUTF8String:baseFilenameChars] : NULL];
        [self setSourceID:sqlite3_column_int(statement, ZBSourceColumnSourceID)];
        [self setIconURL:[self.mainDirectoryURL URLByAppendingPathComponent:@"CydiaIcon.png"]];
        self.paymentVendor = [[ZBPaymentVendor alloc] initWithRepositoryURI:self.repositoryURI paymentVendorURL:self.paymentVendorURL];
    }
    
    return self;
}

- (BOOL)canDelete {
    return ![[self baseFilename] isEqualToString:@"getzbra.com_repo_"];
}

- (BOOL)isEqual:(ZBSource *)object {
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:[ZBSource class]])
        return NO;
    
    return [[object baseFilename] isEqual:[self baseFilename]];
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@ %@ %d", self.label, self.repositoryURI, self.sourceID];
}

- (NSURL *)paymentVendorURL {
    if (self->paymentVendorURI && self->paymentVendorURI.host && self->paymentVendorURI.scheme) {
        return self->paymentVendorURI;
    }

    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    self->paymentVendorURI = [databaseManager paymentVendorURLForSource:self];
    return self->paymentVendorURI;
}

- (BOOL)supportsPaymentAPI {
    return self.paymentVendor.supportsPaymentAPI;
}

@end
