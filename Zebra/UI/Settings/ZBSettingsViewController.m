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
                @"text": NSLocalizedString(@"App Icon", @""),
                @"type": @(ZBPreferencesCellTypeDisclosure),
                @"class": @"ZBAppIconSettingsViewController"
            },
            @{
                @"text": NSLocalizedString(@"Display", @""),
                @"type": @(ZBPreferencesCellTypeDisclosure),
                @"class": @"ZBDisplaySettingsViewController"
            },
            @{
                @"text": NSLocalizedString(@"Filters", @""),
                @"type": @(ZBPreferencesCellTypeDisclosure),
                @"class": @"ZBFilterSettingsViewController"
            },
            @{  // Might not need this one anymore...
                @"text": NSLocalizedString(@"Gestures", @""),
                @"type": @(ZBPreferencesCellTypeDisclosure),
                @"class": @"ZBGestureSettingsViewController"
            },
            @{
                @"text": NSLocalizedString(@"Language", @""),
                @"type": @(ZBPreferencesCellTypeDisclosure),
                @"class": @"ZBLanguageSettingsViewController"
            },
        ],
        @[
            @{
                @"text": NSLocalizedString(@"Home", @""),
                @"type": @(ZBPreferencesCellTypeDisclosure),
                @"class": @"ZBHomeSettingsViewController"
            },
            @{
                @"text": NSLocalizedString(@"Sources", @""),
                @"type": @(ZBPreferencesCellTypeDisclosure),
                @"class": @"ZBSourceSettingsViewController"
            },
            @{
                @"text": NSLocalizedString(@"Packages", @""),
                @"type": @(ZBPreferencesCellTypeDisclosure),
                @"class": @"ZBPackageSettingsViewController"
            },
            @{
                @"text": NSLocalizedString(@"Console", @""),
                @"type": @(ZBPreferencesCellTypeDisclosure),
                @"class": @"ZBConsoleSettingsViewController"
            },
        ],
        @[
            @{
                @"text": NSLocalizedString(@"Reset", @""),
                @"type": @(ZBPreferencesCellTypeDisclosure),
                @"class": @"ZBResetViewController"
            },
        ]
    ];
}

@end
