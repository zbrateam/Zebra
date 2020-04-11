//
//  ZBFilterSettingsTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/12/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SDWebImage;

#import "ZBFilterSettingsTableViewController.h"
#import "ZBSectionSelectorTableViewController.h"
#import "ZBAuthorSelectorTableViewController.h"

#import <Database/ZBDatabaseManager.h>
#import <Packages/Views/ZBPackageTableViewCell.h>
#import <Sources/Views/ZBRepoTableViewCell.h>
#import <Sources/Helpers/ZBSource.h>
#import <Sources/Controllers/ZBSourceSelectTableViewController.h>
#import <Sources/Controllers/ZBRepoSectionsListTableViewController.h>

#import <UIColor+GlobalColors.h>
#import <UIImageView+Zebra.h>

@interface ZBFilterSettingsTableViewController () {
    NSMutableArray <ZBSource *> *sources;
    NSMutableDictionary <NSString *, NSArray *> *filteredSources;
    NSMutableArray <NSString *> *filteredSections;
    NSMutableDictionary <NSString *, NSString *> *blockedAuthors;
    NSMutableArray <ZBPackage *> *ignoredUpdates;
}
@end

@implementation ZBFilterSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshTable];
    
    self.navigationItem.title = NSLocalizedString(@"Filters", @"");
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRepoTableViewCell" bundle:nil] forCellReuseIdentifier:@"repoTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
}

- (void)refreshTable {
    filteredSections = [[ZBSettings filteredSections] mutableCopy];
    
    filteredSources = [[ZBSettings filteredSources] mutableCopy];
    NSArray *baseFilenames = [filteredSources allKeys];
    
    sources = [NSMutableArray new];
    for (NSString *baseFilename in baseFilenames) {
        ZBSource *source = [ZBSource sourceFromBaseFilename:baseFilename];
        if (source == nil) continue;
        [sources addObject:source];
    }
    [sources sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"label" ascending:YES]]];
    
    blockedAuthors = [[ZBSettings blockedAuthors] mutableCopy];
    
    ignoredUpdates = [[ZBDatabaseManager sharedInstance] packagesWithIgnoredUpdates];
    
    [[self tableView] reloadData];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [ignoredUpdates count] ? 4 : 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [filteredSections count] + 1;
        case 1:
            return [filteredSources count] + 1;
        case 2:
            return [blockedAuthors count] + 1;
        case 3:
            return [ignoredUpdates count];
        default:
            return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"filterCell"];
    
    switch (indexPath.section) {
        case 0: {
            if (indexPath.row < [filteredSections count]) {
                cell.textLabel.text = filteredSections[indexPath.row];
                cell.textLabel.textColor = [UIColor primaryTextColor];
                
                cell.imageView.image = [UIImage imageNamed:[self stripSectionName:filteredSections[indexPath.row]]] ?: [UIImage imageNamed:@"Other"];
                [cell.imageView resize:CGSizeMake(32, 32) applyRadius:YES];
                
                return cell;
            }
            break;
        }
        case 1: {
            if (indexPath.row < [filteredSources count]) {
                ZBRepoTableViewCell *repoCell = [tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
                ZBSource *source = sources[indexPath.row];
                
                repoCell.repoLabel.text = [source label];
                repoCell.repoLabel.textColor = [UIColor primaryTextColor];
                
                unsigned long numberOfSections = (unsigned long)[filteredSources[[source baseFilename]] count];
                repoCell.urlLabel.text = numberOfSections == 1 ? NSLocalizedString(@"1 Section Hidden", @"") : [NSString stringWithFormat:NSLocalizedString(@"%lu Sections Hidden", @""), numberOfSections];
                repoCell.urlLabel.textColor = [UIColor secondaryTextColor];
                
                [repoCell.iconImageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
                
                return repoCell;
            }
            break;
        }
        case 2: {
            if (indexPath.row < [blockedAuthors count]) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"authorCell"];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.accessoryType = UITableViewCellAccessoryDetailButton;
                
                cell.textLabel.text = [blockedAuthors objectForKey:[blockedAuthors allKeys][indexPath.row]];
                cell.textLabel.textColor = [UIColor primaryTextColor];
                
                NSString *email = [blockedAuthors allKeys][indexPath.row];
                if (![email isEqualToString:cell.textLabel.text]) {
                    cell.detailTextLabel.text = email;
                    cell.detailTextLabel.textColor = [UIColor secondaryTextColor];
                }
                
                cell.tintColor = [UIColor accentColor];
                return cell;
            }
            break;
        }
        case 3: {
            ZBPackageTableViewCell *packageCell = [tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
            ZBPackage *package = ignoredUpdates[indexPath.row];
            
            [packageCell updateData:package];
            
            return packageCell;
            break;
        }
    }
    
    cell.textLabel.text = NSLocalizedString(@"Add Filter", @"");
    cell.textLabel.textColor = [UIColor accentColor] ?: [UIColor systemBlueColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) {
        NSMutableString *message = [NSLocalizedString(@"This author also goes by the following names:", @"") mutableCopy];
        
        ZBDatabaseManager *database = [ZBDatabaseManager sharedInstance];
        NSString *email = [blockedAuthors allKeys][indexPath.row];
        NSString *name = blockedAuthors[email];
        NSArray *aliases = [database searchForAuthorFromEmail:email fullSearch:YES];
        for (NSArray *alias in aliases) {
            if (![alias[0] isEqual:name]) [message appendFormat:@"\n%@", alias[0]];
        }
        
        UIAlertController *aliasList = [UIAlertController alertControllerWithTitle:blockedAuthors[email] message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil];
        [aliasList addAction:ok];
        
        [self presentViewController:aliasList animated:YES completion:nil];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"Sections", @"");
        case 1:
            return NSLocalizedString(@"Sources", @"");
        case 2:
            return NSLocalizedString(@"Authors", @"");
        case 3:
            return NSLocalizedString(@"Updates", @"");
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
            return NSLocalizedString(@"Hide packages from these authors.", @"");
        case 3:
            return NSLocalizedString(@"Hide future updates from these packages.", @"");
    }
    return NULL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSUInteger rowCount = [tableView numberOfRowsInSection:indexPath.section];
    BOOL lastRow = indexPath.row == rowCount - 1;
    
    switch (indexPath.section) {
        case 0: {
            if (lastRow) {
                ZBSectionSelectorTableViewController *sectionPicker = [[ZBSectionSelectorTableViewController alloc] init];
                [sectionPicker setSectionsSelected:^(NSArray * _Nonnull selectedSections) {
                    [self->filteredSections addObjectsFromArray:selectedSections];
                    [ZBSettings setFilteredSections:self->filteredSections];
                    
                    [self refreshTable];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
                }];
                
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:sectionPicker];
                
                [self presentViewController:nav animated:YES completion:nil];
            }
            break;
        }
        case 1: {
            if (!lastRow) {
                ZBRepoSectionsListTableViewController *sections = [[ZBRepoSectionsListTableViewController alloc] initWithSource:sources[indexPath.row]];
                
                [[self navigationController] pushViewController:sections animated:YES];
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
                
                [self presentViewController:nav animated:YES completion:nil];
            }
            break;
        }
        case 2:
            if (lastRow) {
                ZBAuthorSelectorTableViewController *authorPicker = [[ZBAuthorSelectorTableViewController alloc] init];
                [authorPicker setAuthorsSelected:^(NSDictionary * _Nonnull selectedAuthors) {
                    [self->blockedAuthors addEntriesFromDictionary:selectedAuthors];
                    [ZBSettings setBlockedAuthors:self->blockedAuthors];
                    
                    [self refreshTable];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
                }];
                
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:authorPicker];
                
                [self presentViewController:nav animated:YES completion:nil];
            }
            break;
            break;
        case 3:
            break;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger rowCount = [tableView numberOfRowsInSection:indexPath.section];
    return indexPath.row != rowCount - 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            NSString *section = filteredSections[indexPath.row];
            [filteredSections removeObject:section];
            
            [ZBSettings setFilteredSections:filteredSections];
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        case 1: {
            ZBSource *source = sources[indexPath.row];
            [filteredSources removeObjectForKey:[source baseFilename]];
            [sources removeObjectAtIndex:indexPath.row];
            
            [ZBSettings setFilteredSources:filteredSources];
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        case 2: {
            NSString *author = [blockedAuthors allKeys][indexPath.row];
            [blockedAuthors removeObjectForKey:author];

            [ZBSettings setBlockedAuthors:blockedAuthors];
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
    }
}

- (NSString *)stripSectionName:(NSString *)section {
    NSArray *components = [section componentsSeparatedByString:@"("];
    return [components[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@end
