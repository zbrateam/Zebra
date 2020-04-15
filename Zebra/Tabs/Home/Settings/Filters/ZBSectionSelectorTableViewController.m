//
//  ZBSectionSelectorTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/22/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSectionSelectorTableViewController.h"

#import <ZBSettings.h>
#import <Database/ZBDatabaseManager.h>
#import <Extensions/UIImageView+Zebra.h>
#import <Extensions/UIColor+GlobalColors.h>
#import <Sources/Helpers/ZBSource.h>

@interface ZBSectionSelectorTableViewController () {
    NSArray *sections;
    NSMutableArray *selectedSections;
    NSMutableArray *selectedIndexes;
}
@end

@implementation ZBSectionSelectorTableViewController

#pragma mark - View Controller Lifecycle

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        selectedSections = [NSMutableArray new];
        selectedIndexes = [NSMutableArray new];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Select a Section", @"");
    
    NSMutableArray *allSections = [[[ZBDatabaseManager sharedInstance] sectionReadout] mutableCopy];
    NSArray *filteredSections = [ZBSettings filteredSections];
    
    [allSections removeObjectsInArray:filteredSections];
    
    sections = (NSArray *)allSections;
    
    [self layoutNaviationButtons];
}

#pragma mark - Bar Button Actions

- (void)layoutNaviationButtons {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", @"") style:UIBarButtonItemStyleDone target:self action:@selector(addSections)];
    self.navigationItem.rightBarButtonItem.enabled = [selectedIndexes count];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(goodbye)];
}

- (void)addSections {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.sectionsSelected(self->selectedSections);
    });
    
    [self goodbye];
}

- (void)goodbye {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [sections count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sectionSelectorCell"];
    
    cell.textLabel.text = sections[indexPath.row];
    cell.textLabel.textColor = [UIColor primaryTextColor];
    
    cell.imageView.image = [ZBSource imageForSection:sections[indexPath.row]];
    [cell.imageView resize:CGSizeMake(32, 32) applyRadius:YES];
    
    cell.accessoryType = [selectedIndexes containsObject:indexPath] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *section = sections[indexPath.row];
    
    if ([selectedIndexes containsObject:indexPath]) {
        [selectedIndexes removeObject:indexPath];
        [selectedSections removeObject:section];
    }
    else {
        [selectedIndexes addObject:indexPath];
        [selectedSections addObject:section];
    }
    
    [[self tableView] reloadData];
    [self layoutNaviationButtons];
}

- (NSString *)stripSectionName:(NSString *)section {
    NSArray *components = [section componentsSeparatedByString:@"("];
    return [components[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@end
