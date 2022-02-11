//
//  ZBDisplaySettingsViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/11/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBDisplaySettingsViewController.h"

#import "Zebra-Swift.h"
#import "UIImageView+Zebra.h"

@interface ZBDisplaySettingsViewController () {
    BOOL usesSystemAppearance;
//    BOOL pureBlackMode;
    ZBAccentColor accentColor;
    ZBInterfaceStyle interfaceStyle;
    NSArray *images;
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
        
        NSMutableArray *tempImages = [NSMutableArray new];
			UITraitCollection *lightTraitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
			UITraitCollection *darkTraitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
        for (ZBAccentColor color = ZBAccentColorAquaVelvet; color <= ZBAccentColorStorm; color++) {
//            UIColor *leftColor = [UIColor getAccentColor:color forInterfaceStyle:UIUserInterfaceStyleLight];
//            UIColor *rightColor = [UIColor getAccentColor:color forInterfaceStyle:UIUserInterfaceStyleDark];
//            [tempImages addObject:[self imageWithLeftColor:leftColor rightColor:rightColor]];
        }
        images = tempImages;
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
            @"text": @"",//TODO: [UIColor localizedNameForAccentColor:color],
            @"type": @(ZBPreferencesCellTypeSelection),
            @"action": @"selectAccentColor:",
            @"icon": images[color]
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.imageView.image) {
        CGSize size = CGSizeMake(30, 30);
        [cell.imageView resize:size applyRadius:NO];
        
        cell.imageView.layer.cornerRadius = size.width / 2;
        cell.imageView.clipsToBounds = YES;
    }
    
    return cell;
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

	ZBSettings.interfaceStyle = newIndexPath.row;
}

- (void)selectAccentColor:(NSIndexPath *)newIndexPath {
    accentColor = newIndexPath.row;
    
    [ZBSettings setAccentColor:newIndexPath.row];
}

- (UIImage *)imageWithLeftColor:(UIColor *)leftColor rightColor:(UIColor *)rightColor {
    CGSize size = CGSizeMake(30, 30);
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size.width, size.height), NO, 0.0);
    
    UIBezierPath *leftTriangle = [[UIBezierPath alloc] init];
    [leftTriangle moveToPoint:CGPointMake(0, 0)];
    [leftTriangle addLineToPoint:CGPointMake(0, size.height)];
    [leftTriangle addLineToPoint:CGPointMake(size.width, 0)];
    [leftTriangle closePath];
    
    [leftColor setFill];
    [leftTriangle fill];
    
    UIBezierPath *rightTriangle = [[UIBezierPath alloc] init];
    [rightTriangle moveToPoint:CGPointMake(size.width, size.height)];
    [rightTriangle addLineToPoint:CGPointMake(0, size.height)];
    [rightTriangle addLineToPoint:CGPointMake(size.width, 0)];
    [rightTriangle closePath];
    
    [rightColor setFill];
    [rightTriangle fill];

    UIImage *colorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return colorImage;
}

@end
