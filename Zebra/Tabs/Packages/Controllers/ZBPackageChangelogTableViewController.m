//
//  ZBPackageChangelogTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 5/17/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBPackageChangelogTableViewController.h"
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Views/ZBChangelogTableViewCell.h>
#import "UIColor+GlobalColors.h"

@interface ZBPackageChangelogTableViewController ()
@property (nonatomic, strong) NSArray <ZBPackage *> *allVersions;
@end

@implementation ZBPackageChangelogTableViewController

#pragma mark - Initializers

- (id)initWithPackage:(ZBPackage *)package {
    self = [super init];
    
    if (self) {
        self.allVersions = [package allVersions]; // Could probably simplify this to a method that gets all of the changelog notes instead of every single package instance that way we don't get packages that
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerTableViewCells];
    [self applyCustomizations];
    [self setData];
}

#pragma mark - View Setup

- (void)applyCustomizations {
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 16, 0, 16)];
    [self.tableView setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
}

- (void)registerTableViewCells {
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([ZBChangelogTableViewCell class]) bundle:nil] forCellReuseIdentifier:@"ChangelogTableViewCell"];
}

- (void)setData {
    [self setTitle:@"Version History"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.allVersions.count;
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBChangelogTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChangelogTableViewCell" forIndexPath:indexPath];
    
    ZBPackage *package = self.allVersions[indexPath.row];
    
    cell.changelogTitleLabel.text = package.changelogTitle;
    cell.changelogNotesLabel.text = package.changelogNotes;
    
    return cell;
}

@end
