//
//  ZBSearchResultsTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/23/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSearchResultsTableViewController.h"
#import <Packages/Helpers/ZBProxyPackage.h>
#import <Packages/Controllers/ZBPackageDepictionViewController.h>
#import "ZBLiveSearchResultTableViewCell.h"

@interface ZBSearchResultsTableViewController ()
@property (nonatomic, weak) ZBPackageDepictionViewController *previewPackageDepictionVC;
@end

@implementation ZBSearchResultsTableViewController

@synthesize filteredResults;

- (id)initWithNavigationController:(UINavigationController *)controller {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"searchResultsController"];
    
    if (self) {
        self.navController = controller;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] init]; // Hide seperators after last cell
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[self tableView] setBackgroundColor:[UIColor groupedTableViewBackgroundColor]];
}

#pragma mark - Table view data source

- (void)refreshTable {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return filteredResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= filteredResults.count) return NULL;
    if (_live) {
        ZBLiveSearchResultTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"liveSearchResultCell" forIndexPath:indexPath];
        ZBProxyPackage *proxyPackage = filteredResults[indexPath.row];
        [cell updateData:proxyPackage];
        
        return cell;
    }
    else {
        ZBPackageTableViewCell *packageCell = [tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
        
        [packageCell updateData:filteredResults[indexPath.row]];
        
        return packageCell;
    }
}

- (ZBPackageDepictionViewController *)getPackageDepictionVC:(NSIndexPath *)indexPath {
    if (_live) {
        ZBProxyPackage *proxyPackage = filteredResults[indexPath.row];
        ZBPackageDepictionViewController *depiction = [[ZBPackageDepictionViewController alloc] initWithPackage:[proxyPackage loadPackage]];
        
        return depiction;
    } else {
        ZBPackage *package = filteredResults[indexPath.row];
        
        ZBPackageDepictionViewController *depiction = [[ZBPackageDepictionViewController alloc] initWithPackage:package];
        
        return depiction;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    [[self navController] pushViewController:[self getPackageDepictionVC:indexPath] animated:true];
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0)){
    typeof(self) __weak weakSelf = self;
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController * _Nullable{
        return weakSelf.previewPackageDepictionVC;
    } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        weakSelf.previewPackageDepictionVC = [weakSelf getPackageDepictionVC:indexPath];
        weakSelf.previewPackageDepictionVC.parent = weakSelf;
        return [UIMenu menuWithTitle:@"" children:[weakSelf.previewPackageDepictionVC contextMenuActionItemsForIndexPath:indexPath]];
    }];
}

- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator API_AVAILABLE(ios(13.0)){
    typeof(self) __weak weakSelf = self;
    [animator addCompletion:^{
        [[weakSelf navController] pushViewController:weakSelf.previewPackageDepictionVC animated:YES];
    }];
}

@end
