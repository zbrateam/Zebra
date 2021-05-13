//
//  MainSettingsTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/22/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSettingsViewController.h"

@interface ZBSettingsViewController ()
@end

@implementation ZBSettingsViewController

- (instancetype)init {
    if (@available(iOS 13.0, *)) {
        self = [super initWithStyle:UITableViewStyleInsetGrouped];
    } else {
        self = [super initWithStyle:UITableViewStyleGrouped];
    }
    
    if (self) {
        self.title = NSLocalizedString(@"Settings", @"");
    }
    
    return self;
}

// This needs to be statically allocated somehow so that we don't keep re-allocating it.
- (NSArray <NSArray <NSDictionary *> *> *)specifiers {
    return @[
        @[
            @{
                @"text": NSLocalizedString(@"Appearance", @""),
                @"class": @"ZBAppearanceSettingsViewController"
            },
            @{
                @"text": NSLocalizedString(@"App Icon", @""),
                @"class": @"ZBAppIconSettingsViewController"
            },
            @{
                @"text": NSLocalizedString(@"Filters", @""),
                @"class": @"ZBFilterSettingsViewController"
            },
            @{  // Might not need this one anymore...
                @"text": NSLocalizedString(@"Gestures", @""),
                @"class": @"ZBGestureSettingsViewController"
            },
            @{
                @"text": NSLocalizedString(@"Language", @""),
                @"class": @"ZBLanguageSettingsViewController"
            },
        ],
        @[
            @{
                @"text": NSLocalizedString(@"Home", @""),
                @"class": @"ZBHomeSettingsViewController"
            },
            @{
                @"text": NSLocalizedString(@"Sources", @""),
                @"class": @"ZBSourceSettingsViewController"
            },
            @{
                @"text": NSLocalizedString(@"Packages", @""),
                @"class": @"ZBPackageSettingsViewController"
            },
            @{
                @"text": NSLocalizedString(@"Console", @""),
                @"class": @"ZBConsoleSettingsViewController"
            },
        ],
        @[
            @{
                @"text": NSLocalizedString(@"Reset", @""),
                @"class": @"ZBResetViewController"
            },
        ]
    ];
}

@end
