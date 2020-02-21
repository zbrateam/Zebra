//
//  ZBAdvancedSettingsTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/20/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBAdvancedSettingsTableViewController.h"
#import <UIColor+GlobalColors.h>
#import <ZBDevice.h>

@interface ZBAdvancedSettingsTableViewController ()

@end

@implementation ZBAdvancedSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Advanced";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
        case 1:
            return 2;
        case 2:
            return 2;
        default:
            return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"settingsAdvancedCell"];
    
    NSArray <NSArray <NSString *> *> *titles = @[@[@"Restart SpringBoard", @"Refresh Icon Cache"], @[@"Reset Image Cache", @"Reset Sources Cache"], @[@"Reset All Settings", @"Erase All Sources and Settings"]];
    cell.textLabel.text = titles[indexPath.section][indexPath.row];
    cell.textLabel.textColor = [UIColor accentColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:true];
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    [self restartSpringBoard];
                    break;
                case 1:
                    [self refreshIconCache];
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    [self resetImageCache];
                    break;
                case 1:
                    [self resetSourcesCache];
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    [self resetAllSettings];
                    break;
                case 1:
                    [self eraseSourcesAndSettings];
                    break;
            }
            break;
    }
            
}

#pragma mark - Button Actions

- (void)restartSpringBoard {
    [ZBDevice restartSpringBoard];
}

- (void)refreshIconCache {
    [ZBDevice uicache:nil observer:nil];
}

- (void)resetImageCache {
    
}

- (void)resetSourcesCache {
    
}

- (void)resetAllSettings {
    
}

- (void)eraseSourcesAndSettings {
    
}

@end
