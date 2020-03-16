//
//  ZBFilterSettingsTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/12/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SDWebImage;

#import "ZBFilterSettingsTableViewController.h"

#import <UIColor+GlobalColors.h>
#import <Sources/Views/ZBRepoTableViewCell.h>
#import <Sources/Helpers/ZBSource.h>
#import <Sources/Controllers/ZBSourceSelectTableViewController.h>
#import <Sources/Controllers/ZBRepoSectionsListTableViewController.h>

@interface ZBFilterSettingsTableViewController () {
    NSMutableArray <ZBSource *> *sources;
    NSDictionary <NSString *, NSArray *> *filteredSources;
}
@end

@implementation ZBFilterSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshTable];
    
    self.navigationItem.title = NSLocalizedString(@"Filters", @"");
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRepoTableViewCell" bundle:nil] forCellReuseIdentifier:@"repoTableViewCell"];
}

- (void)refreshTable {
    filteredSources = [[ZBSettings filteredSources] mutableCopy];
    NSArray *baseFilenames = [filteredSources allKeys];
    
    sources = [NSMutableArray new];
    for (NSString *baseFilename in baseFilenames) {
        [sources addObject:[ZBSource sourceFromBaseFilename:baseFilename]];
    }
    [sources sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"label" ascending:YES]]];
    
    [[self tableView] reloadData];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
        case 1:
            return [filteredSources count] + 1;
        case 2:
            return 1;
        case 3:
            return 1;
        default:
            return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"filterCell"];
    
    switch (indexPath.section) {
        case 0: {
            break;
        }
        case 1: {
            if (indexPath.row < [filteredSources count]) {
                ZBRepoTableViewCell *repoCell = [tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
                ZBSource *source = sources[indexPath.row];
                
                repoCell.repoLabel.text = [source label];
                repoCell.repoLabel.textColor = [UIColor primaryTextColor];
                
                unsigned long numberOfSections = (unsigned long)[filteredSources[[source baseFilename]] count];
                repoCell.urlLabel.text = numberOfSections == 1 ? NSLocalizedString(@"1 Section Filtered", @"") : [NSString stringWithFormat:NSLocalizedString(@"%lu Sections Hidden", @""), numberOfSections];
                repoCell.urlLabel.textColor = [UIColor secondaryTextColor];
                
                [repoCell.iconImageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
                
                return repoCell;
            }
            break;
        }
        case 2: {
            break;
        }
        case 3: {
            break;
        }
    }
    
    cell.textLabel.text = NSLocalizedString(@"Add Filter", @"");
    cell.textLabel.textColor = [UIColor accentColor];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"Sections", @"");
        case 1:
            return NSLocalizedString(@"Sources", @"");
        case 2:
            return NSLocalizedString(@"Ignored Updates", @"");
        case 3:
            return NSLocalizedString(@"Ignored Authors", @"");
    }
    return NULL;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"Hide packages in these sections.", @"");
        case 1:
            return NSLocalizedString(@"Hide packages in these sections from specific sources.", @"");
        case 2:
            return NSLocalizedString(@"Ignore any future updates from these packages.", @"");
        case 3:
            return NSLocalizedString(@"Hide all packages from these authors.", @"");
    }
    return NULL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    NSUInteger rowCount = [tableView numberOfRowsInSection:indexPath.section];
    BOOL lastRow = indexPath.row == rowCount - 1;
    
    switch (indexPath.section) {
        case 0:
            break;
        case 1: {
            if (!lastRow) {
                ZBRepoSectionsListTableViewController *sections = [[ZBRepoSectionsListTableViewController alloc] init];
                sections.repo = sources[indexPath.row];
                
                [[self navigationController] pushViewController:sections animated:true];
            }
            else {
                ZBSourceSelectTableViewController *sourcePicker = [[ZBSourceSelectTableViewController alloc] initWithSelectionType:ZBSourceSelectionTypeNormal limit:1];
                [sourcePicker setSourcesSelected:^(NSArray<ZBSource *> * _Nonnull selectedSources) {
                    NSMutableDictionary *sources = [self->filteredSources mutableCopy];
                    
                    for (ZBSource *source in selectedSources) {
                        [sources setObject:@[] forKey:[source baseFilename]];
                    }
                    
                    [ZBSettings setFilteredSources:sources];
                    [self refreshTable];
                }];
                
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:sourcePicker];
                
                [self presentViewController:nav animated:true completion:nil];
            }
            break;
        }
        case 2:
            break;
        case 3:
            break;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger rowCount = [tableView numberOfRowsInSection:indexPath.section];
    return indexPath.row != rowCount - 1;
}

@end
