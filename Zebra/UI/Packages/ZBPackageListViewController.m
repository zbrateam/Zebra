//
//  ZBPackageListViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBPackageListViewController.h"

#import <Managers/ZBPackageManager.h>
#import <Model/ZBPackage.h>
#import <Model/ZBSource.h>
#import <UI/Packages/Views/Cells/ZBPackageTableViewCell.h>

@interface ZBPackageListViewController () {
    ZBPackageManager *packageManager;
    UIActivityIndicatorView *spinner;
}
@end

@implementation ZBPackageListViewController

#pragma mark - Initializers

- (instancetype)initWithSource:(ZBSource *)source {
    return [self initWithSource:source section:NULL];
}

- (instancetype)initWithSource:(ZBSource *)source section:(NSString *_Nullable)section {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        packageManager = [ZBPackageManager sharedInstance];
        
        self.source = source;
        self.section = [section isEqualToString:@"ALL_PACKAGES"] ? NULL : section;
        
        if (self.source.remote) {
            if (self.section) {
                self.title = NSLocalizedString(self.section, @"");
            } else {
                self.title = NSLocalizedString(@"All Packages", @"");
            }
        } else {
            self.title = NSLocalizedString(@"Installed", @"");
        }
    }
    
    return self;
}

- (instancetype)initWithPackages:(NSArray <ZBPackage *> *)packages {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        self.packages = packages;
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    
    if (!self.packages && self.source) {
        self.packages = [packageManager packagesFromSource:self.source inSection:self.section];
        
        [self.tableView reloadData];
    }
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1; // For now
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.packages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(ZBPackageTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell updateData:self.packages[indexPath.row]];
}

#pragma mark - Table View Delegate

@end
