//
//  ZBQueueViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBQueueViewController.h"

#import <UI/Packages/Views/Cells/ZBPackageTableViewCell.h>

#import <Plains/PLPackage.h>
#import <Plains/PLQueue.h>

@interface ZBQueueViewController () {
    PLQueue *queue;
    NSArray <NSArray <PLPackage *> *> *packages;
}
@end

@implementation ZBQueueViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        queue = [PLQueue sharedInstance];
        self.title = @"Queue";
        
        [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self->packages = queue.packages;
    [self.tableView reloadData];
    
#if TARGET_OS_MACCATALYST
    [self.navigationController setNavigationBarHidden:YES animated:NO];
#endif
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return packages.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return packages[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
    
    PLPackage *package = packages[indexPath.section][indexPath.row];
    [cell setPackage:package];
    
    return cell;
}

#pragma mark - Table View Delegate

@end
