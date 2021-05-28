//
//  ZBPreferencesViewController.m
//  Zebra
//
//  Created by absidue on 20-06-22.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBPreferencesViewController.h"

#import <Extensions/ZBColor.h>

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
    
    if (!self.headers.firstObject) {
        [self.tableView setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 35)]];
    } else {
        [self.tableView setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 15)]];
    }
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"preferencesCell"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.specifiers.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.specifiers[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"preferencesCell" forIndexPath:indexPath];
    
    UIColor *accentColor = [ZBColor accentColor];
    cell.tintColor = accentColor;
    
    NSDictionary *specifier = self.specifiers[indexPath.section][indexPath.row];
    cell.textLabel.text = specifier[@"text"];
    cell.imageView.image = specifier[@"icon"];
    
    ZBPreferencesCellType cellType = [specifier[@"type"] unsignedIntValue];
    switch (cellType) {
        case ZBPreferencesCellTypeText: {
            cell.textLabel.textColor = [ZBColor labelColor];
            cell.accessoryView = NULL;
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }
        case ZBPreferencesCellTypeDisclosure: {
            cell.textLabel.textColor = [ZBColor labelColor];
            cell.accessoryView = NULL;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case ZBPreferencesCellTypeButton: {
            cell.textLabel.textColor = [ZBColor accentColor];
            cell.accessoryView = NULL;
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }
        case ZBPreferencesCellTypeSwitch: {
            cell.textLabel.textColor = [ZBColor labelColor];
            
            UISwitch *nx = [[UISwitch alloc] initWithFrame:CGRectZero];
            nx.on = [specifier[@"enabled"] boolValue];
            nx.onTintColor = accentColor;
            
            SEL selector = NSSelectorFromString(specifier[@"action"]);
            [nx addTarget:self action:selector forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = nx;
            break;
        }
        case ZBPreferencesCellTypeSelection: {
            cell.textLabel.textColor = [ZBColor labelColor];
            cell.accessoryView = NULL;
            cell.accessoryType = [[self.selectedRows objectForKey:@(indexPath.section)] integerValue] == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        }
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
        NSObject *object;
        ZBPreferencesCellType cellType = [specifier[@"type"] unsignedIntValue];
        if (cellType == ZBPreferencesCellTypeButton) {
            object = [tableView cellForRowAtIndexPath:indexPath];
        } else if (cellType == ZBPreferencesCellTypeSwitch) {
            UISwitch *toggleSwitch = (UISwitch *)[tableView cellForRowAtIndexPath:indexPath].accessoryView;
            [toggleSwitch setOn:!toggleSwitch.isOn animated:YES];
            object = toggleSwitch;
        } else if (cellType == ZBPreferencesCellTypeSelection) {
            NSIndexPath *oldIndexPath;
            NSNumber *oldRow = [self.selectedRows objectForKey:@(indexPath.section)];
            if (oldRow) {
                oldIndexPath = [NSIndexPath indexPathForRow:oldRow.integerValue inSection:indexPath.section];
            }
            
            if (!self.selectedRows) self.selectedRows = [NSMutableDictionary new];
            [self.selectedRows setObject:@(indexPath.row) forKey:@(indexPath.section)];
            
            NSMutableArray *rows = [NSMutableArray arrayWithObject:indexPath];
            if (oldIndexPath) [rows addObject:oldIndexPath];
            [self.tableView reloadRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationAutomatic];
            
            object = indexPath;
        }
        
        SEL selector = NSSelectorFromString(specifier[@"action"]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector withObject:object];
#pragma clang diagnostic pop
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section < self.headers.count && ![self.headers[section] isEqualToString:@""]) {
        return self.headers[section];
    }
    return NULL;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section < self.footers.count && ![self.footers[section] isEqualToString:@""]) {
        return self.footers[section];
    }
    return NULL;
}

@end
