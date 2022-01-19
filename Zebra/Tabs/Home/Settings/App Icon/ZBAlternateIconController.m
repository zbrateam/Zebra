//
//  ZBAlternateIconController.m
//  Zebra
//
//  Created by midnightchips on 6/1/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBAlternateIconController.h"
#import "ZBAlternateIconCell.h"

#import "ZBDevice.h"
#import "UIColor+GlobalColors.h"

@interface ZBAlternateIconController () <ZBAlternateIconCellDelegate>

@end

@implementation ZBAlternateIconController

+ (NSArray <NSDictionary <NSString *, id> *> *)icons {
    return @[
        @{
            @"name": @"Default Icon",
            @"author": @"Zebra Team",
            @"icons": @[
                    @{
                        @"name": @"Light",
                        @"iconName": @"AppIcon",
                        @"border": @YES
                    },
                    @{
                        @"name": @"Dark",
                        @"iconName": @"originalBlack",
                        @"border": @NO
                    }
            ]
        },
        @{
            @"name": @"Retro",
            @"author": @"Zebra Team",
            @"icons": @[
                    @{
                        @"name": @"Light",
                        @"iconName": @"AUPM",
                        @"border": @YES
                    }
            ]
        },
        @{
            @"name": @"Z with Stripes",
            @"author": @"Alpha_Stream",
            @"icons": @[
                    @{
                        @"name": @"Light",
                        @"iconName": @"alphastream-light",
                        @"border": @NO
                    },
                    @{
                        @"name": @"Dark",
                        @"iconName": @"alphastream-dark",
                        @"border": @NO
                    }
            ]
        },
        @{
            @"name": @"Zebra Pattern",
            @"author": @"xerus (@xerusdesign)",
            @"icons": @[
                    @{
                        @"name": @"Light",
                        @"iconName": @"lightZebraSkin",
                        @"border": @NO
                    },
                    @{
                        @"name": @"Dark",
                        @"iconName": @"darkZebraSkin",
                        @"border": @NO
                    }
            ]
        },
        @{
            @"name": @"Embossed Zebra Pattern",
            @"author": @"xerus (@xerusdesign)",
            @"icons": @[
                    @{
                        @"name": @"Light",
                        @"iconName": @"zWhite",
                        @"border": @NO
                    },
                    @{
                        @"name": @"Dark",
                        @"iconName": @"zBlack",
                        @"border": @NO
                    }
            ]
        }
    ];
}

+ (NSDictionary *)iconForName:(NSString *)name {
    if (!name) return [self icons][0][@"icons"][0];

    for (NSDictionary *iconSet in [self icons]) {
        for (NSDictionary *icon in iconSet[@"icons"]) {
            if ([icon[@"iconName"] isEqualToString:name]) {
                return icon;
            }
        }
    }

    return NULL;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"App Icon", @"");
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }

    [self.tableView registerClass:[ZBAlternateIconCell class] forCellReuseIdentifier:@"alternateIconCell"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.class icons].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *iconSet = [self.class icons][indexPath.section];

    ZBAlternateIconCell *cell = (ZBAlternateIconCell *)[tableView dequeueReusableCellWithIdentifier:@"alternateIconCell" forIndexPath:indexPath];
    cell.delegate = self;
    cell.iconSet = iconSet;
    cell.tintColor = [UIColor accentColor];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *iconSet = [self.class icons][section];
    return iconSet[@"name"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSDictionary *iconSet = [self.class icons][section];
    return [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Author", @""), iconSet[@"author"]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90;
}

#pragma mark - Alternate icon button callback

- (void)setAlternateIconFromSet:(NSDictionary <NSString *, id> *)iconSet atIndex:(NSInteger)index {
    NSDictionary <NSString *, id> *icon = iconSet[@"icons"][index];
    [ZBDevice hapticButton];
    [self setIconWithName:icon[@"iconName"]];
}

- (void)setIconWithName:(NSString *)name {
    if (@available(iOS 10.3, *)) {
        if ([[UIApplication sharedApplication] supportsAlternateIcons]) {
            NSString *currentIcon = [UIApplication sharedApplication].alternateIconName ?: @"AppIcon";
            if ([currentIcon isEqualToString:name]) {
                return;
            }

            if ([name isEqualToString:@"AppIcon"]) name = nil;

            [[UIApplication sharedApplication] setAlternateIconName:name completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Unable to set application icon" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil];

                    [alert addAction:ok];
                    [self.navigationController presentViewController:alert animated:YES completion:nil];
                }
            }];

            [self.tableView reloadData];
        }
    }
}

@end

