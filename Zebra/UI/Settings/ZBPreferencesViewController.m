//
//  ZBPreferencesViewController.m
//  Zebra
//
//  Created by absidue on 20-06-22.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBPreferencesViewController.h"
#import "ZBSwitchSettingsTableViewCell.h"
#import "ZBOptionSettingsTableViewCell.h"
#import "ZBDevice.h"

@implementation ZBPreferencesViewController;

#pragma mark - Table view methods

- (instancetype)init {
    if (@available(iOS 13.0, *)) {
        self = [super initWithStyle:UITableViewStyleInsetGrouped];
    } else {
        self = [super initWithStyle:UITableViewStyleGrouped];
    }
    return self;
}

- (NSArray <NSArray <NSDictionary *> *> *)specifiers {
    return @[];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 35)]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.specifiers.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.specifiers[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    NSDictionary *specifier = self.specifiers[indexPath.section][indexPath.row];
    cell.textLabel.text = specifier[@"text"];
    cell.imageView.image = specifier[@"icon"];
    
    if (specifier[@"class"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if (specifier[@"action"]) {
        cell.textLabel.textColor = [UIColor systemBlueColor];
    } else {
        cell.textLabel.textColor = [UIColor labelColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *specifier = self.specifiers[indexPath.section][indexPath.row];
    if (specifier[@"class"]) {
        Class pushClass = NSClassFromString(specifier[@"class"]);
        UIViewController *viewController = [[pushClass alloc] init];
        
        [[self navigationController] pushViewController:viewController animated:YES];
    } else if (specifier[@"action"]) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        SEL selector = NSSelectorFromString(specifier[@"action"]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector withObject:cell];
#pragma clang diagnostic pop
    }
}

#pragma mark - Settings cell action helpers

- (void)toggleSwitchAtIndexPath:(NSIndexPath *)indexPath {
    ZBSwitchSettingsTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [cell toggle];
}

- (void)chooseOptionAtIndexPath:(NSIndexPath *)indexPath previousIndexPath:(NSIndexPath *)previousIndexPath animated:(BOOL)animated {
    if (animated) {
        [self.tableView reloadRowsAtIndexPaths:@[previousIndexPath, indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else {
        ZBOptionSettingsTableViewCell *cell = [self.tableView cellForRowAtIndexPath:previousIndexPath];
        [cell setChosen:NO];
        
        cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [cell setChosen:NO];
    }
    [ZBDevice hapticButton];
}

- (void)chooseUnchooseOptionAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [ZBDevice hapticButton];
}

@end
