//
//  ZBAppIconSettingsViewController.m
//  Zebra
//
//  Created by Wilson Styres on 5/14/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBAppIconSettingsViewController.h"

#import "UIImageView+Zebra.h"

#if !TARGET_OS_MACCATALYST

@implementation ZBAppIconSettingsViewController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.title = @"App Icon";
//        self.selectedRows = @{@0: };
    }
    
    return self;
}

- (NSArray <NSArray <NSDictionary *> *> *)specifiers {
    return @[
        @[
//            @{
//                @"icon": [UIImage imageNamed:@"AppIcon60x60"],
//                @"text": @"Classic",
//                @"border": @YES
//            },
            @{
                @"icon": [UIImage imageNamed:@"originalBlack"],
                @"text": @"Classic (Dark)",
                @"border": @NO,
                @"type": @(ZBPreferencesCellTypeSelection),
                @"action": @"setAppIcon:",
                @"iconName": @"originalBlack"
            },
            @{
                @"icon": [UIImage imageNamed:@"AUPM"],
                @"text": @"Retro",
                @"border": @YES,
                @"type": @(ZBPreferencesCellTypeSelection),
                @"action": @"setAppIcon:",
                @"iconName": @"AUPM"
            },
            @{
                @"icon": [UIImage imageNamed:@"lightZebraSkin"],
                @"subtext": @"xerus (@xerusdesign)",
                @"text": @"Zebra Skin",
                @"iconBorder": @NO,
                @"type": @(ZBPreferencesCellTypeSelection),
                @"action": @"setAppIcon:",
                @"iconName": @"lightZebraSkin"
            },
            @{
                @"icon": [UIImage imageNamed:@"darkZebraSkin"],
                @"subtext": @"xerus (@xerusdesign)",
                @"text": @"Zebra Skin (Dark)",
                @"iconBorder": @NO,
                @"type": @(ZBPreferencesCellTypeSelection),
                @"action": @"setAppIcon:",
                @"iconName": @"darkZebraSkin"
            },
            @{
                @"icon": [UIImage imageNamed:@"zWhite"],
                @"subtext": @"xerus (@xerusdesign)",
                @"text": @"Felicity Pro",
                @"iconBorder": @NO,
                @"type": @(ZBPreferencesCellTypeSelection),
                @"action": @"setAppIcon:",
                @"iconName": @"zWhite"
            },
            @{
                @"icon": [UIImage imageNamed:@"zBlack"],
                @"subtext": @"xerus (@xerusdesign)",
                @"text": @"Felicity Pro (Dark)",
                @"iconBorder": @NO,
                @"type": @(ZBPreferencesCellTypeSelection),
                @"action": @"setAppIcon:",
                @"iconName": @"zBlack"
            },
            @{
                @"icon": [UIImage imageNamed:@"viola"],
                @"subtext": @"Bossgfx (@bossgfx_)",
                @"text": @"Viola",
                @"iconBorder": @NO,
                @"type": @(ZBPreferencesCellTypeSelection),
                @"action": @"setAppIcon:",
                @"iconName": @"viola"
            },
            @{
                @"icon": [UIImage imageNamed:@"quda"],
                @"subtext": @"heysyemeh (@heysyemeh)",
                @"text": @"Quda",
                @"iconBorder": @NO,
                @"type": @(ZBPreferencesCellTypeSelection),
                @"action": @"setAppIcon:",
                @"iconName": @"quda"
            },
            @{
                @"icon": [UIImage imageNamed:@"zebrine"],
                @"subtext": @"Ciprian Ciocoiu (@qiuChuck)",
                @"text": @"Zebrine",
                @"iconBorder": @YES,
                @"type": @(ZBPreferencesCellTypeSelection),
                @"action": @"setAppIcon:",
                @"iconName": @"zebrine"
            }
        ]
    ];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    [cell.imageView resize:CGSizeMake(60, 60) applyRadius:YES];
    if ([self.specifiers[indexPath.section][indexPath.row][@"iconBorder"] boolValue]) {
        [cell.imageView applyBorder];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 75.0;
}

- (void)setAppIcon:(NSIndexPath *)indexPath {
    NSDictionary *specifier = self.specifiers[indexPath.section][indexPath.row];
    
    [[UIApplication sharedApplication] setAlternateIconName:specifier[@"iconName"] completionHandler:^(NSError * _Nullable error) {
        if (error) {
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Could not set alternate icon" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
            [errorAlert addAction:action];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:errorAlert animated:YES completion:nil];
            });
        }
    }];
}

@end

#endif
