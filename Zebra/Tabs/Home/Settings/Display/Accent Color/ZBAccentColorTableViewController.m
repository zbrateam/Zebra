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
}
@end

@implementation ZBAccentColorTableViewController

- (id)init {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"accentColorPicker"];
    
    if (self) {
        colors = [ZBThemeManager colors];
        selectedColor = [ZBSettings accentColor];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return colors.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"colorCell"];
    
    ZBAccentColor color = (ZBAccentColor)[colors[indexPath.row] integerValue];
    if (color == selectedColor) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    UIColor *leftColor = [ZBThemeManager getAccentColor:color forInterfaceStyle:ZBInterfaceStyleLight];
    UIColor *rightColor = [ZBThemeManager getAccentColor:color forInterfaceStyle:ZBInterfaceStyleDark];
    [[cell imageView] setLeftColor:leftColor rightColor:rightColor];
    [[cell imageView] applyBorder];
    
    cell.textLabel.text = [ZBThemeManager localizedNameForAccentColor:color];
    cell.textLabel.textColor = [UIColor primaryTextColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[colors indexOfObject:@(selectedColor)] inSection:0]];
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

@end
