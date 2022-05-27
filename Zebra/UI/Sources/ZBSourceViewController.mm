//
//  ZBSourceViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSourceViewController.h"

#import "ZBSidebarController.h"
#import "ZBPackageListViewController.h"
#import "UIImageView+Zebra.h"

#import "PLPackage+Zebra.h"
#import "PLSource+Zebra.h"
#import <Plains/Plains.h>

@interface ZBSourceViewController () {
    NSArray <NSString *> *sections;
    NSArray <NSNumber *> *counts;
}
@property PLSource *source;
@end

@implementation ZBSourceViewController

- (instancetype)initWithSource:(PLSource *)source {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        _source = source;
        
        self.title = source.origin;
    }
    
    return self;
}

- (instancetype)initWithPackage:(PLPackage *)package {
    return [self initWithSource:package.source];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    [self.tableView setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchSections) name:PLDatabaseRefreshNotification object:nil];
    [self fetchSections];
}

- (void)fetchSections {
    NSDictionary *unsortedSections = _source.sections;
    NSMutableArray *tempSections = [[unsortedSections.allKeys sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]] mutableCopy];
    NSMutableArray *tempCounts = [[unsortedSections objectsForKeys:tempSections notFoundMarker:@""] mutableCopy];
    
    NSNumber *sum = [tempCounts valueForKeyPath:@"@sum.self"];
    [tempSections insertObject:@"All Packages" atIndex:0];
    [tempCounts insertObject:sum atIndex:0];
    
    sections = tempSections;
    counts = tempCounts;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return sections.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"sectionCell"];
    
    NSString *section = sections[indexPath.row];
    cell.textLabel.text = section;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", counts[indexPath.row].intValue];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (indexPath.row == 0) {
        cell.textLabel.font = [UIFont systemFontOfSize:cell.textLabel.font.pointSize weight:UIFontWeightMedium];
        cell.imageView.image = nil;
    } else {
        cell.imageView.image = [PLSource imageForSection:section];
        [cell.imageView resize:CGSizeMake(32, 32) applyRadius:YES];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *section = indexPath.row == 0 ? NULL : sections[indexPath.row];
    ZBPackageListViewController *packageList = [[ZBPackageListViewController alloc] initWithSource:self.source section:section];
    [self.navigationController pushViewController:packageList animated:YES];
}

@end
