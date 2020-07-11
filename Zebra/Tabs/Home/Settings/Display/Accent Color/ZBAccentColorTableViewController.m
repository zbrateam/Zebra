//
//  ZBAccentColorTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/5/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBAccentColorTableViewController.h"
#import "UITableView+Settings.h"
#import "UIImageView+Zebra.h"
#import "ZBSwitchSettingsTableViewCell.h"
#import "ZBOptionSettingsTableViewCell.h"

#import <ZBThemeManager.h>
#import <ZBSettings.h>
#import <ZBAppDelegate.h>
#import <Extensions/UIColor+GlobalColors.h>

@interface ZBAccentColorTableViewController () {
    NSArray *colors;
    ZBAccentColor selectedColor;
    BOOL usesSystemAccentColor;
}
@end

@implementation ZBAccentColorTableViewController

- (id)init {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"accentColorPicker"];
    
    if (self) {
        colors = [ZBThemeManager colors];
        selectedColor = [ZBSettings accentColor];
        usesSystemAccentColor = [ZBSettings usesSystemAccentColor];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Accent Color", @"");

    [self.tableView registerCellTypes:@[@(ZBSwitchSettingsCell), @(ZBOptionSettingsCell)]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return usesSystemAccentColor ? 1 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : colors.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        ZBSwitchSettingsTableViewCell *cell = [tableView dequeueSwitchSettingsCellForIndexPath:indexPath];
        
        cell.textLabel.text = NSLocalizedString(@"Use System Accent Color", @"");
        
        [cell setOn:usesSystemAccentColor];
        [cell setTarget:self action:@selector(toggleSystemColor:)];
        [cell applyStyling];
        
        return cell;
    }
    else {
        ZBOptionSettingsTableViewCell *cell = [tableView dequeueOptionSettingsCellForIndexPath:indexPath];
        
        ZBAccentColor color = (ZBAccentColor)[colors[indexPath.row] integerValue];
        [cell setChosen:color == selectedColor];
        
        UIColor *leftColor = [ZBThemeManager getAccentColor:color forInterfaceStyle:ZBInterfaceStyleLight];
        UIColor *rightColor = [ZBThemeManager getAccentColor:color forInterfaceStyle:ZBInterfaceStyleDark];
        [[cell imageView] setLeftColor:leftColor rightColor:rightColor];
        [[cell imageView] applyBorder];
        
        cell.textLabel.text = [ZBThemeManager localizedNameForAccentColor:color];
        
        [cell applyStyling];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        [self toggleSwitchAtIndexPath:indexPath];
    }
    else {
        NSInteger newRow = [colors indexOfObject:@(selectedColor)];
        
        if (newRow != indexPath.row) {
            NSIndexPath *previousChoice = [NSIndexPath indexPathForRow:newRow inSection:1];
            
            ZBAccentColor newColor = (ZBAccentColor)[colors[indexPath.row] integerValue];
            selectedColor = newColor;
            
            [ZBSettings setAccentColor:newColor];
            [[ZBThemeManager sharedInstance] configureNavigationBar];
            
            self.navigationController.navigationBar.tintColor = [UIColor accentColor] ?: [UIColor systemBlueColor];
            [[ZBAppDelegate tabBarController] tabBar].tintColor = [UIColor accentColor] ?: [UIColor systemBlueColor];
            ((ZBAppDelegate *)[[UIApplication sharedApplication] delegate]).window.tintColor = [UIColor accentColor];
            
            ZBOptionSettingsTableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
            [newCell applyStyling];
            
            [self chooseOptionAtIndexPath:indexPath previousIndexPath:previousChoice animated:YES];
        }
    }
}

- (void)toggleSystemColor:(NSNumber *)newUseSystemColor {
    usesSystemAccentColor = [newUseSystemColor boolValue];
    [ZBSettings setUsesSystemAccentColor:usesSystemAccentColor];
    
    if (usesSystemAccentColor) { //Delete style picker section
        [self.tableView deleteSections:[[NSIndexSet alloc] initWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }
    else { //Insert style picker section
        [self.tableView insertSections:[[NSIndexSet alloc] initWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [(ZBSwitchSettingsTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] applyStyling];
    
    [[ZBThemeManager sharedInstance] configureNavigationBar];
    
    self.navigationController.navigationBar.tintColor = [UIColor accentColor] ?: [UIColor systemBlueColor];
    [[ZBAppDelegate tabBarController] tabBar].tintColor = [UIColor accentColor] ?: [UIColor systemBlueColor];
    ((ZBAppDelegate *)[[UIApplication sharedApplication] delegate]).window.tintColor = [UIColor accentColor];
}

@end
