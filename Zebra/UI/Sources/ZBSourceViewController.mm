//
//  ZBSourceViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSourceViewController.h"

#import <Plains/Plains.h>

@interface ZBSourceViewController () {
    NSMutableDictionary <NSString *, NSNumber *> *sections;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self fetchSections];
}

- (void)fetchSections {
    sections = _source.sections;
    
    [self.tableView reloadData];
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
    
    cell.textLabel.text = sections.allKeys[indexPath.row];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", sections.allValues[indexPath.row].intValue];
    
    return cell;
}

@end
