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
    }
    
    return self;
}

- (NSArray <NSArray <NSDictionary *> *> *)specifiers {
    NSMutableArray *specifiers = [NSMutableArray new];
    
    if (@available(iOS 13.0, *)) {
        NSMutableArray *appearanceSpecifiers = [NSMutableArray new];
        [appearanceSpecifiers addObject:@{
            @"text": @"Use System Appearance",
            @"type": @(ZBPreferencesCellTypeSwitch),
            @"enabled": @(usesSystemAppearance),
            @"action": @"toggleSystemStyle:"
        }];
        
        if (!usesSystemAppearance) {
            [appearanceSpecifiers addObject:@{
                @"text": @"Light",
                @"type": @(ZBPreferencesCellTypeSelection),
                @"action": @"selectStyle:"
            }];
            [appearanceSpecifiers addObject:@{
                @"text": @"Dark",
                @"type": @(ZBPreferencesCellTypeSelection),
                @"action": @"selectStyle:"
            }];
        }
        [specifiers addObject:appearanceSpecifiers];
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
    return @[
        @"Appearance",
        @"Accent Color"
    ];
}

#pragma mark - Settings

- (void)toggleSystemStyle:(UISwitch *)toggleSwitch {
    usesSystemAppearance = toggleSwitch.isOn;
    [ZBSettings setUsesSystemAppearance:usesSystemAppearance];
    
    interfaceStyle = [ZBSettings interfaceStyle];
    
    if (usesSystemAppearance) { // Delete style picker section
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else { // Insert style picker section
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
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
