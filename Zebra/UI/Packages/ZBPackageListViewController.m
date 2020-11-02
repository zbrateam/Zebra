//
//  ZBPackageListViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBPackageListViewController.h"

@import FirebaseAnalytics;

@interface ZBPackageListViewController () {
    ZBPackageManager *packageManager;
    ZBSource *source;
    NSString *section;
}
@end

@implementation ZBPackageListViewController

#pragma mark - Initializers

- (instancetype)initWithSource:(ZBSource *)source {
    return [self initWithSource:source section:NULL];
}

- (instancetype)initWithSource:(ZBSource *)source section:(NSString *_Nullable)section {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        self->source = source;
        self->section = [section isEqualToString:@"ALL_PACKAGES"] ? NULL : section;
        
        if (self->source.remote) {
            if (self->section) {
                self.title = NSLocalizedString(self->section, @"");
            } else {
                self.title = NSLocalizedString(@"All Packages", @"");
            }
        } else {
            self.title = NSLocalizedString(@"Installed", @"");
        }
    }
    
    return self;
}

@end
