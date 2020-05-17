//
//  ZBPackageVersionHistoryTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 5/17/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBPackageVersionHistoryTableViewController.h"
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Views/ZBChangelogTableViewCell.h>

@interface ZBPackageVersionHistoryTableViewController ()
@property (nonatomic, strong) NSArray <ZBPackage *> *allVersions;
@end

@implementation ZBPackageVersionHistoryTableViewController

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
}

#pragma mark - View Setup

- (void)registerTableViewCells {
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([ZBChangelogTableViewCell class]) bundle:nil] forCellReuseIdentifier:@"ChangelogTableViewCell"];
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
    NSMutableString *changelogTitleString = [NSMutableString stringWithFormat:@"Version %@", package.version];
    if (package.changelogTitle != nil) {
        [changelogTitleString appendString:[NSString stringWithFormat:@" — %@", package.changelogTitle]];
    }
    cell.changelogTitleLabel.text = changelogTitleString;
    cell.changelogNotesLabel.text = package.changelogNotes ?: @"No Release Notes Available";
    cell.dateLabel.text = @"Today";
    
    return cell;
}

@end
