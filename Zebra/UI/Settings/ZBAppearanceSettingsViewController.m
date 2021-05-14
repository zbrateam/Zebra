//
//  ZBAppearanceSettingsViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBAppearanceSettingsViewController.h"

#import <ZBSettings.h>
#import <Extensions/ZBColor.h>

@interface ZBAppearanceSettingsViewController () {
    BOOL usesSystemAppearance;
//    BOOL pureBlackMode;
    ZBAccentColor accentColor;
    ZBInterfaceStyle interfaceStyle;
}
@end

@implementation ZBAppearanceSettingsViewController

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
        [specifiers addObject:@[
            @{
                @"text": @"Use System Appearance",
                @"type": @(ZBPreferencesCellTypeSwitch),
                @"action": @"toggleSystemStyle:"
            }
        ]];
        
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

#pragma mark - Settings

//- (void)toggleSystemStyle:(NSNumber *)newUsesSystemAppearance {
//    usesSystemAppearance = [newUsesSystemAppearance boolValue];
//    [ZBSettings setUsesSystemAppearance:usesSystemAppearance];
//    
//    interfaceStyle = interfaceStyle = [ZBSettings interfaceStyle];
//    
//    if (usesSystemAppearance) { // Delete style picker section
//        [self.tableView deleteSections:[[NSIndexSet alloc] initWithIndex:ZBSectionStyleChooser] withRowAnimation:UITableViewRowAnimationFade];
//    }
//    else { // Insert style picker section
//        [self.tableView insertSections:[[NSIndexSet alloc] initWithIndex:ZBSectionStyleChooser] withRowAnimation:UITableViewRowAnimationFade];
//    }
//    
//    [self updateInterfaceStyle];
//}

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
