//
//  ZBSourceListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 9/7/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSourcesListTableViewController.h"

#import <Tabs/ZBTabBarController.h>
#import <Tabs/Sources/Cells/ZBSourceTableViewCell.h>

#import <Tabs/Sources/Helpers/ZBSource.h>

@interface ZBSourcesListTableViewController ()

@end

@implementation ZBSourcesListTableViewController

@synthesize sources;

#pragma mark - Controller Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    sources = [[self.databaseManager repos] mutableCopy];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //From: https://stackoverflow.com/a/48837322
    UIVisualEffectView *fxView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    fxView.backgroundColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:0.60];
    [fxView setFrame:CGRectOffset(CGRectInset(self.navigationController.navigationBar.bounds, 0, -12), 0, -60)];
    [self.navigationController.navigationBar setTranslucent:YES];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar insertSubview:fxView atIndex:1];
    
    [self layoutNavigationButtons];
}

#pragma mark - Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [sources count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSourceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sourceTableCell" forIndexPath:indexPath];
    ZBSource *source = [sources objectAtIndex:indexPath.row];
    
    [cell updateData:source];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = [sources objectAtIndex:indexPath.row];
    
    return ![[source origin] isEqualToString:@"xTM3x Repo"];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [sources removeObjectAtIndex:indexPath.row];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Table View Layout

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 69;
}

#pragma mark - Navigation Buttons

- (void)layoutNavigationButtons {
    if (self.refreshControl.refreshing) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelRefresh:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        self.navigationItem.rightBarButtonItem = nil;
    }
    else {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        if (self.isEditing) {
            UIBarButtonItem *exportButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(exportSources:)];
            self.navigationItem.leftBarButtonItem = exportButton;
        }
        else {
            UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSource:)];
            self.navigationItem.leftBarButtonItems = @[addButton];
        }
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self layoutNavigationButtons];
}

- (void)cancelRefresh:(id)sender {
    
}

- (void)exportSources:(id)sender {

}

- (void)addSource:(id)sender {

}

#pragma mark - UI Updates

- (BOOL)setSpinnerVisible:(BOOL)visible forBaseFileName:(NSString *)baseFileName {

    return false;
}

- (void)clearAllSpinners {
    
}

#pragma mark - URL Handling

- (void)handleURL:(NSURL *)url {

}

- (void)handleImportOf:(NSURL *)url {
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
