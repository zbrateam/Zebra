//
//  ZBDisplaySettingsViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBDisplaySettingsViewController.h"

#import <ZBSettings.h>
#import <Extensions/ZBColor.h>

@interface ZBDisplaySettingsViewController () {
    BOOL usesSystemAppearance;
//    BOOL pureBlackMode;
    ZBAccentColor accentColor;
    ZBInterfaceStyle interfaceStyle;
}
@end

@implementation ZBDisplaySettingsViewController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.title = @"Display";
        
        accentColor = [ZBSettings accentColor];
        usesSystemAppearance = [ZBSettings usesSystemAppearance];
        interfaceStyle = [ZBSettings interfaceStyle];
        
        if (usesSystemAppearance) {
            self.selectedRows = [[NSMutableDictionary alloc] initWithDictionary:@{@1: @(accentColor)}];
        } else {
            self.selectedRows = [[NSMutableDictionary alloc] initWithDictionary:@{@1: @(interfaceStyle), @2: @(accentColor)}];
        }
    }
    
    return self;
}

- (NSArray <NSArray <NSDictionary *> *> *)specifiers {
    NSMutableArray *specifiers = [NSMutableArray new];
    
    if (@available(iOS 13.0, *)) {
        [specifiers addObject:@[@{
            @"text": @"Use System Appearance",
            @"type": @(ZBPreferencesCellTypeSwitch),
            @"enabled": @(usesSystemAppearance),
            @"action": @"toggleSystemStyle:"
        }]];
        
        if (!usesSystemAppearance) {
            [specifiers addObject:@[
                @{
                    @"text": @"Light",
                    @"type": @(ZBPreferencesCellTypeSelection),
                    @"action": @"selectStyle:"
                },
                @{
                    @"text": @"Dark",
                    @"type": @(ZBPreferencesCellTypeSelection),
                    @"action": @"selectStyle:"
                }
            ]];
        }
    }
    
    NSMutableArray *colors = [NSMutableArray new];
    for (ZBAccentColor color = ZBAccentColorAquaVelvet; color <= ZBAccentColorStorm; color++) {
        [colors addObject:@{
            @"text": [ZBColor localizedNameForAccentColor:color],
            @"type": @(ZBPreferencesCellTypeSelection),
            @"action": @"selectAccentColor:"
        }];
    }
    [specifiers addObject:colors];
    
    return specifiers;
}

- (NSArray <NSString *> *)headers {
    if (usesSystemAppearance) {
        return @[
            @"Appearance",
            @"Accent Color"
        ];
    } else {
        return @[
            @"Appearance",
            @"",
            @"Accent Color"
        ];
    }
}

#pragma mark - Settings

- (void)toggleSystemStyle:(UISwitch *)toggleSwitch {
    usesSystemAppearance = toggleSwitch.isOn;
    [ZBSettings setUsesSystemAppearance:usesSystemAppearance];
    
    interfaceStyle = [ZBSettings interfaceStyle];
    
    if (usesSystemAppearance) { // Delete style picker section
        [self.selectedRows setObject:@(accentColor) forKey:@(1)];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else { // Insert style picker section
        [self.selectedRows setObject:@(interfaceStyle) forKey:@(1)];
        [self.selectedRows setObject:@(accentColor) forKey:@(2)];
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)selectStyle:(NSIndexPath *)newIndexPath {
    interfaceStyle = newIndexPath.row;
    
    [ZBSettings setInterfaceStyle:newIndexPath.row];
}

- (void)selectAccentColor:(NSIndexPath *)newIndexPath {
    accentColor = newIndexPath.row;
    
    [ZBSettings setAccentColor:newIndexPath.row];
}

//- (void)togglePureBlack:(NSNumber *)newPureBlackMode {
//    pureBlackMode = [newPureBlackMode boolValue];
//    [ZBSettings setPureBlackMode:pureBlackMode];
//    [self updateInterfaceStyle];
//}

//- (void)updateInterfaceStyle {
//    usesSystemAppearance = [ZBSettings usesSystemAppearance];
//    interfaceStyle = [ZBSettings interfaceStyle];
//    
////    [[ZBThemeManager sharedInstance] updateInterfaceStyle];
//    
//    [UIView animateWithDuration:0.5 animations:^{
//        self.tableView.backgroundColor = [ZBColor systemGroupedBackgroundColor];
//        
//        for (ZBSettingsTableViewCell *cell in self.tableView.visibleCells) {
//            [cell applyStyling];
//        }
//    }];
//}

@end
