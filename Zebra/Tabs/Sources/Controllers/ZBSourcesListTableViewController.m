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
    
    sources = [self.databaseManager repos];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 69;
}

#pragma mark - Navigation Buttons

- (void)layoutNavigationButtons {
    if (self.refreshControl.refreshing) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelRefresh:)];
        self.navigationItem.leftBarButtonItems = @[cancelButton];
        self.navigationItem.rightBarButtonItem = nil;
    }
    else {
        if (self.editing) {
            UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(toggleEditing:)];
            self.navigationItem.rightBarButtonItem = doneButton;
            
            UIBarButtonItem *exportButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(exportSources:)];
            self.navigationItem.leftBarButtonItem = exportButton;
        } else {
            self.editButtonItem.action = @selector(toggleEditing:);
            self.navigationItem.rightBarButtonItem = self.editButtonItem;
            
            UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSource:)];
            self.navigationItem.leftBarButtonItems = @[addButton];
        }
    }
}

- (void)cancelRefresh:(id)sender {
    
}

- (void)toggleEditing:(id)sender {
    
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
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
