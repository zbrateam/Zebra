//
//  ZBSettingsSelectionTableViewController.m
//  Zebra
//
//  Created by Louis on 02/11/2019.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSettingsSelectionTableViewController.h"
#import <ZBSettings.h>
#import "ZBDevice.h"
#import <Extensions/UIColor+GlobalColors.h>

@interface ZBSettingsSelectionTableViewController () {
    NSMutableArray <NSString *>    *selectedOptions;
    NSMutableArray <NSIndexPath *> *selectedIndexes;
}
@end

@implementation ZBSettingsSelectionTableViewController

@synthesize selectionType;
@synthesize limit;

@synthesize settingsKey;
@synthesize footerText;
@synthesize options;

- (id)initWithSettingsKey:(NSString *)key selectionType:(ZBSettingsSelectionType)type limit:(int)optionLimit options:(NSArray *)selectionOptions {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        settingsKey = key;
        selectionType = type;
        limit = optionLimit;
        options = selectionOptions;
        selectedOptions = [NSMutableArray new];
        selectedIndexes = [NSMutableArray new];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(self.title, @"");
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
}

- (void)viewDidDisappear:(BOOL)animated {
    self.selectionChanged(options, selectedOptions);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [options count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"settingsOptionCell"];
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.text = NSLocalizedString(options[indexPath.row], @"");
    cell.tintColor = [UIColor accentColor];
    cell.textLabel.textColor = [UIColor primaryTextColor];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    switch (selectionType) {
        case ZBSettingsSelectionTypeNormal:
            if ([selectedIndexes containsObject:indexPath]) cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
        case ZBSettingsSelectionTypeInverse:
            if (![selectedIndexes containsObject:indexPath]) cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSMutableArray *localize = [NSMutableArray new];
    for (NSString *string in footerText) {
        [localize addObject:NSLocalizedString(string, @"")];
    }
    return [localize componentsJoinedByString:@"\n\n"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self addOptionAtIndexPath:indexPath];
}

- (void)addOptionAtIndexPath:(NSIndexPath *)indexPath {
    NSString *option = options[indexPath.row];
    
    if ([selectedIndexes containsObject:indexPath]) {
        [selectedIndexes removeObject:indexPath];
        [selectedOptions removeObject:option];
    }
    else {
        if (limit > 0 && [selectedIndexes count] >= limit) {
            // Remove the first object selected
            [selectedIndexes removeObjectAtIndex:0];
            [selectedOptions removeObjectAtIndex:0];
        }
        
        [selectedIndexes addObject:indexPath];
        [selectedOptions addObject:option];
    }
    
    [[self tableView] reloadData];
}

@end
