//
//  ZBSettingsSelectionTableViewController.m
//  Zebra
//
//  Created by Louis on 02/11/2019.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSettingsSelectionTableViewController.h"
#import "ZBOptionSettingsTableViewCell.h"
#import <ZBSettings.h>
#import "ZBDevice.h"
#import <Extensions/UIColor+GlobalColors.h>

@interface ZBSettingsSelectionTableViewController () {
    NSString *selectedOption;
    NSIndexPath *selectedIndex;
    SEL settingsGetter;
    SEL settingsSetter;
    NSInteger selectedValue;
}
@end

@implementation ZBSettingsSelectionTableViewController

@synthesize settingChanged;

@synthesize settingsKey;
@synthesize footerText;
@synthesize options;

- (id)initWithOptions:(NSArray *)selectionOptions getter:(SEL)getter setter:(SEL)setter settingChangedCallback:(void (^)(void))callback {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        options = selectionOptions;
        
        settingsGetter = getter;
        settingsSetter = setter;
        
        settingChanged = callback;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(self.title, @"");
    
    selectedValue = (NSInteger)[ZBSettings performSelector:settingsGetter];
    
    NSIndexPath *selectedIndex = [NSIndexPath indexPathForRow:selectedValue inSection:0];
    NSString *selectedOption = [options objectAtIndex:selectedValue];
    
    self->selectedIndex = selectedIndex;
    self->selectedOption = selectedOption;
    
    [self.tableView registerClass:[ZBOptionSettingsTableViewCell class] forCellReuseIdentifier:@"settingsOptionCell"];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (selectedIndex.row != selectedValue && settingChanged) self.settingChanged();
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBOptionSettingsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"settingsOptionCell" forIndexPath:indexPath];
    
    cell.textLabel.text = NSLocalizedString(options[indexPath.row], @"");
    
    [cell setChosen:[selectedIndex isEqual:indexPath]];
    [cell applyStyling];

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
    
    if (![selectedIndex isEqual:indexPath]) {
        NSIndexPath *previousChoice = selectedIndex;
        
        self->selectedIndex = indexPath;
        self->selectedOption = options[indexPath.row];
        
        [self.tableView reloadRowsAtIndexPaths:@[previousChoice, indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [ZBSettings performSelector:settingsSetter withObject:@(selectedIndex.row)];
    }
}

@end
