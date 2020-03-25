//
//  ZBSourceSelectTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/14/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SDWebImage;

#import "ZBSourceSelectTableViewController.h"
#import "ZBRepoTableViewCell.h"
#import "ZBSource.h"
#import "UIColor+GlobalColors.h"

@interface ZBSourceSelectTableViewController () {
    NSMutableArray <ZBSource *>    *selectedSources;
    NSMutableArray <NSIndexPath *> *selectedIndexes;
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
    }
    
    return self;
}

+ (BOOL)supportRefresh {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Select a Source";
}

- (void)baseViewDidLoad {}

- (void)layoutNavigationButtonsNormal {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(goodbye)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleDone target:self action:@selector(addFilters)];
    self.navigationItem.rightBarButtonItem.enabled = [selectedSources count];
}

- (void)checkClipboard {}

- (void)addFilters {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.sourcesSelected(self->selectedSources);
    });
    
    [self goodbye];
}

- (void)goodbye {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)refreshTable {
    self->sources = [[[ZBDatabaseManager sharedInstance] sources] mutableCopy];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateCollation];
        [self.tableView reloadData];
    });
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBRepoTableViewCell *cell = (ZBRepoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
    ZBSource *source = [self sourceAtIndexPath:indexPath];
    
    cell.repoLabel.text = [source label];
    cell.repoLabel.textColor = [UIColor primaryTextColor];
    
    cell.urlLabel.text = [source repositoryURI];
    cell.urlLabel.textColor = [UIColor secondaryTextColor];
    
    [cell.iconImageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    switch (selectionType) {
        case ZBSourceSelectionTypeNormal:
            if ([selectedIndexes containsObject:indexPath]) cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
        case ZBSourceSelectionTypeInverse:
            if (![selectedIndexes containsObject:indexPath]) cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    [self addSourceAtIndexPath:indexPath];
}

- (void)addSourceAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = [self sourceAtIndexPath:indexPath];
    
    if ([selectedIndexes containsObject:indexPath]) {
        [selectedIndexes removeObject:indexPath];
        [selectedSources removeObject:source];
    }
    else {
        if (limit > 0 && [selectedIndexes count] >= limit) {
            // Remove first object selected
            [selectedIndexes removeObjectAtIndex:0];
            [selectedSources removeObjectAtIndex:0];
        }
        
        [selectedIndexes addObject:indexPath];
        [selectedSources addObject:source];
    }
    
    [[self tableView] reloadData];
    [self layoutNavigationButtonsNormal];
}

@end
