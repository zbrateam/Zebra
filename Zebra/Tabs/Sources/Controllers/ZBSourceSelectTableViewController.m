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
#import "UIColor+GlobalColors.h"
#import "ZBDevice.h"
#import "UIImageView+Zebra.h"

@interface ZBSourceSelectTableViewController () {
    NSMutableArray <ZBSource *>    *selectedSources;
    NSMutableArray <NSIndexPath *> *selectedIndexes;
}
@end

@implementation ZBSourceSelectTableViewController

@synthesize limit;
@synthesize selectionType;

- (id)initWithSelectionType:(ZBSourceSelectionType)type limit:(int)sourceLimit {
    self = [super initWithStyle:[ZBDevice tableViewStyle]];

    if (self) {
        limit = sourceLimit;
        selectionType = type;
        selectedSources = [NSMutableArray new];
        selectedIndexes = [NSMutableArray new];
    }

    return self;
}

- (id)initWithSelectionType:(ZBSourceSelectionType)type limit:(int)sourceLimit selectedSources:(NSArray *)preSelectedSources {
    self = [self initWithSelectionType:type limit:sourceLimit];

    if (self) {
        [selectedSources addObjectsFromArray:preSelectedSources];
    }

    return self;
}

- (BOOL)supportRefresh {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Select a Source", @"");
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
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(goodbye)];

        if (@available(iOS 26, *)) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(addFilters)];
        } else {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", @"") style:UIBarButtonItemStyleDone target:self action:@selector(addFilters)];
        }

        if (limit > 0) self.navigationItem.rightBarButtonItem.enabled = [selectedSources count];
    }
}

- (void)checkClipboard {}

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
    self->sources = [[[ZBDatabaseManager sharedInstance] sources] mutableCopy];

    NSMutableArray *fakeSources = [NSMutableArray new];
    for (NSObject *source in sources) {
        if (![source isKindOfClass:[ZBSource class]]) {
            [fakeSources addObject:source];
        }
    }
    [sources removeObjectsInArray:fakeSources];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateCollation];
        [self.tableView reloadData];
    });
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSourceTableViewCell *cell = (ZBSourceTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"sourceTableViewCell" forIndexPath:indexPath];
    ZBSource *source = [self sourceAtIndexPath:indexPath];

    cell.sourceLabel.text = [source label];
    cell.sourceLabel.textColor = [UIColor primaryTextColor];

    cell.urlLabel.text = [source repositoryURI];
    cell.urlLabel.textColor = [UIColor secondaryTextColor];

    [cell.iconImageView setRetinaImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"] completed:^(UIImage *image, __unused NSError *error, __unused SDImageCacheType cacheType, __unused NSURL *imageURL) {
        [cell.iconImageView setIconImage:image variant:MIIconVariantSettings];
    }];

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
