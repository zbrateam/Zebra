//
//  ZBSourceSelectTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/14/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SDWebImage;

#import "ZBSourceSelectTableViewController.h"
#import "ZBSourceTableViewCell.h"
#import "ZBSource.h"
#import "ZBSourceManager.h"
#import "UIColor+GlobalColors.h"

@interface ZBSourceSelectTableViewController () {
    NSMutableArray <ZBBaseSource *> *sources;
    NSMutableArray <ZBSource *>     *selectedSources;
    NSArray <ZBSource *>            *preSelectedSources;
    NSMutableArray <NSIndexPath *>  *selectedIndexes;
}
@end

@implementation ZBSourceSelectTableViewController

@synthesize limit;
@synthesize selectionType;

- (id)initWithSelectionType:(ZBSourceSelectionType)type limit:(int)sourceLimit {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        limit = sourceLimit;
        selectionType = type;
        selectedSources = [NSMutableArray new];
        selectedIndexes = [NSMutableArray new];
        
        self.title = NSLocalizedString(@"Select a Source", @"");
        
        sources = [[[ZBSourceManager sharedInstance] sources] mutableCopy];
        
        NSMutableArray *fakeSources = [NSMutableArray new];
        for (NSObject *source in sources) {
            if (![source isKindOfClass:[ZBSource class]]) {
                [fakeSources addObject:source];
            }
        }
        [sources removeObjectsInArray:fakeSources];
        
        filteredSources = [sources mutableCopy];
    }
    
    return self;
}

- (id)initWithSelectionType:(ZBSourceSelectionType)type limit:(int)sourceLimit selectedSources:(NSArray <ZBSource *> *)preSelectedSources {
    self = [self initWithSelectionType:type limit:sourceLimit];
    
    if (self) {
        self->preSelectedSources = [preSelectedSources copy];
        [selectedSources addObjectsFromArray:preSelectedSources];
    }
    
    return self;
}

- (BOOL)supportRefresh {
    return NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (![self presented]) {
        [self addFilters];
    }
}

- (void)baseViewDidLoad {}

- (BOOL)presented {
    return [self.navigationController.viewControllers[0] isEqual:self];
}

- (void)layoutNavigationButtonsNormal {
    if ([self presented]) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(goodbye)];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", @"") style:UIBarButtonItemStyleDone target:self action:@selector(addFilters)];
        [self updateAddButtonAvailability];
    }
}

- (void)checkClipboard {}

- (void)updateAddButtonAvailability {
    self.navigationItem.rightBarButtonItem.enabled = selectedIndexes.count && preSelectedSources.count != selectedIndexes.count;
}

- (void)addFilters {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.sourcesSelected(self->selectedSources);
    });
    
    [self goodbye];
}

- (void)goodbye {
    if ([self.navigationController.viewControllers[0] isEqual:self]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [[self navigationController] popViewControllerAnimated:YES];
    }
}

- (void)refreshTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSourceTableViewCell *cell = (ZBSourceTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"sourceCell" forIndexPath:indexPath];
    ZBSource *source = sources[indexPath.row];
    
    cell.sourceLabel.text = [source label];
    cell.sourceLabel.textColor = [UIColor primaryTextColor];
    
    cell.urlLabel.text = [source repositoryURI];
    cell.urlLabel.textColor = [UIColor secondaryTextColor];
    
    [cell.iconImageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    switch (selectionType) {
        case ZBSourceSelectionTypeNormal:
            if ([selectedIndexes containsObject:indexPath]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else if ([selectedSources containsObject:source]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [selectedIndexes addObject:indexPath];
            }
            break;
        case ZBSourceSelectionTypeInverse:
            if ([selectedSources containsObject:source]) {
                cell.accessoryType = UITableViewCellAccessoryNone;
                [selectedIndexes addObject:indexPath];
            }
            else if (![selectedIndexes containsObject:indexPath]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self addSourceAtIndexPath:indexPath];
}

- (void)addSourceAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = sources[indexPath.row];
    if ([preSelectedSources containsObject:source]) {
        // We will not unselect the sources that have already been added.
        return;
    }
    
    if ([selectedIndexes containsObject:indexPath]) {
        [selectedIndexes removeObject:indexPath];
        [selectedSources removeObject:source];
    }
    else {
        if (limit > 0 && selectedIndexes.count >= limit) {
            // Remove first object selected
            [selectedIndexes removeObjectAtIndex:0];
            [selectedSources removeObjectAtIndex:0];
        }
        
        [selectedIndexes addObject:indexPath];
        [selectedSources addObject:source];
    }
    
    [[self tableView] reloadData];
    [self updateAddButtonAvailability];
}

@end
