//
//  ZBAccentColorTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/5/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBAccentColorTableViewController.h"
#import "UIImageView+Zebra.h"
#import "UIColor+GlobalColors.h"
#import <ZBThemeManager.h>
#import <ZBSettings.h>
#import <ZBAppDelegate.h>

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
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
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"systemColorCell"];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = NSLocalizedString(@"Use System Accent Color", @"");
        cell.textLabel.textColor = [UIColor primaryTextColor];
        
        UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [enableSwitch addTarget:self action:@selector(toggleSystemColor:) forControlEvents:UIControlEventValueChanged];
        [enableSwitch setOnTintColor:[UIColor accentColor]];
        
        enableSwitch.on = usesSystemAccentColor;
        cell.accessoryView = enableSwitch;
        
        return cell;
    }
    else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"colorCell"];
        
        ZBAccentColor color = (ZBAccentColor)[colors[indexPath.row] integerValue];
        if (color == selectedColor) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        cell.tintColor = [UIColor accentColor];
        
        UIColor *leftColor = [ZBThemeManager getAccentColor:color forInterfaceStyle:ZBInterfaceStyleLight];
        UIColor *rightColor = [ZBThemeManager getAccentColor:color forInterfaceStyle:ZBInterfaceStyleDark];
        [[cell imageView] setLeftColor:leftColor rightColor:rightColor];
        [[cell imageView] applyBorder];
        
        cell.textLabel.text = [ZBThemeManager localizedNameForAccentColor:color];
        cell.textLabel.textColor = [UIColor primaryTextColor];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[colors indexOfObject:@(selectedColor)] inSection:1]];
        [oldCell setAccessoryType:UITableViewCellAccessoryNone];
        
        ZBAccentColor newColor = (ZBAccentColor)[colors[indexPath.row] integerValue];
        selectedColor = newColor;
        
        [ZBSettings setAccentColor:newColor];
        [[ZBThemeManager sharedInstance] configureNavigationBar];
        
        self.navigationController.navigationBar.tintColor = [UIColor accentColor];
        [[ZBAppDelegate tabBarController] tabBar].tintColor = [UIColor accentColor];
        
        UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
        [newCell setTintColor:[UIColor accentColor]];
        [newCell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
}

- (void)toggleSystemColor:(UISwitch *)sender {
    BOOL setting = sender.on;
    
    usesSystemAccentColor = setting;
    [ZBSettings setUsesSystemAccentColor:setting];
    
    if (!setting) { //Insert style picker section
        [self.tableView beginUpdates];
        [self.tableView insertSections:[[NSIndexSet alloc] initWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
    else { //Delete style picker section
        [self.tableView beginUpdates];
        [self.tableView deleteSections:[[NSIndexSet alloc] initWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
    
    [[ZBThemeManager sharedInstance] configureNavigationBar];
    
    self.navigationController.navigationBar.tintColor = [UIColor accentColor];
    [[ZBAppDelegate tabBarController] tabBar].tintColor = [UIColor accentColor];
}

@end
