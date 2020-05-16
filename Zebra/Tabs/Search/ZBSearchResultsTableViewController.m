//
//  ZBSearchResultsTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/23/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSearchResultsTableViewController.h"
#import "ZBLiveSearchResultTableViewCell.h"

#import <ZBAppDelegate.h>
#import <Packages/Helpers/ZBProxyPackage.h>
#import <Packages/Helpers/ZBPackageActions.h>
#import <Packages/Views/ZBPackageTableViewCell.h>
#import <Packages/Controllers/ZBPackageDepictionViewController.h>
#import <Queue/ZBQueue.h>
#import <Extensions/UIColor+GlobalColors.h>

@import LNPopupController;

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

- (BOOL)forceSetColors {
    return YES;
}

- (BOOL)observeQueueBar {
    if (@available(iOS 11.0, *)) {
        return NO;
    }
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] init]; // Hide seperators after last cell
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBDatabaseCompletedUpdate" object:nil];
}

- (void)configureTableContentInsetForQueue {
    ZBTabBarController *tabBarController = (ZBTabBarController *)[ZBAppDelegate tabBarController];
    UISearchController *searchController = (UISearchController *)self.parentViewController;
    UISearchBar *searchBar = searchController.searchBar;
    CGFloat bottomInset = CGRectGetHeight(tabBarController.tabBar.frame);
    if ([ZBQueue count]) {
        LNPopupBar *popup = [tabBarController popupBar];
        bottomInset += CGRectGetHeight(popup.frame);
    }
    self.tableView.contentInset = UIEdgeInsetsMake(CGRectGetHeight(searchBar.superview.frame), 0, bottomInset, 0);
}

#pragma mark - Table view data source

- (void)refreshTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger resultsCount = filteredResults.count;
    
    if (resultsCount == 0) {
        UILabel *noSearchResultsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, tableView.frame.size.height)];
        noSearchResultsLabel.text = [NSLocalizedString(@"No Results Found", @"") stringByAppendingString:@"\n\n\n\n\n\n\n"];
        noSearchResultsLabel.numberOfLines = 0;
        noSearchResultsLabel.textColor = [UIColor secondaryTextColor];
        noSearchResultsLabel.textAlignment = NSTextAlignmentCenter;
        noSearchResultsLabel.font = [UIFont systemFontOfSize:15];
        tableView.backgroundView = noSearchResultsLabel;
    } else {
        tableView.backgroundView = NULL;
    }
    
    return resultsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= filteredResults.count) return nil;
    
    NSObject *quantumPackage = filteredResults[indexPath.row];
    if ([quantumPackage respondsToSelector:@selector(loadPackage)]) {
        ZBProxyPackage *proxyPackage = (ZBProxyPackage *)quantumPackage;
        
        ZBLiveSearchResultTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"liveSearchResultCell" forIndexPath:indexPath];
        [cell updateData:proxyPackage];
        [cell setColors];
        
        return cell;
    }
    else {
        ZBPackage *package = (ZBPackage *)quantumPackage;
        
        ZBPackageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
        [cell updateData:package];
        [cell setColors];
        
        return cell;
    }
}

- (ZBPackageDepictionViewController *)getPackageDepictionVC:(NSIndexPath *)indexPath {
    NSObject *quantumPackage = filteredResults[indexPath.row];
    if ([quantumPackage respondsToSelector:@selector(loadPackage)]) {
        quantumPackage = [(ZBProxyPackage *)quantumPackage loadPackage];
    }
        
    return [[ZBPackageDepictionViewController alloc] initWithPackage:(ZBPackage *)quantumPackage];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [[self navController] pushViewController:[self getPackageDepictionVC:indexPath] animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return ![[ZBAppDelegate tabBarController] isQueueBarAnimating];
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSObject *quantumPackage = filteredResults[indexPath.row];
    if ([quantumPackage respondsToSelector:@selector(loadPackage)]) {
        // This is a proxy package, load it first
        quantumPackage = [(ZBProxyPackage *)quantumPackage loadPackage];
    }
    
    return [ZBPackageActions rowActionsForPackage:(ZBPackage *)quantumPackage inTableView:tableView];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView setEditing:NO animated:YES];
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0)){
    typeof(self) __weak weakSelf = self;
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController * _Nullable{
        return weakSelf.previewPackageDepictionVC;
    } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        weakSelf.previewPackageDepictionVC = [weakSelf getPackageDepictionVC:indexPath];
        weakSelf.previewPackageDepictionVC.parent = weakSelf;
        return [UIMenu menuWithTitle:@"" children:[weakSelf.previewPackageDepictionVC contextMenuActionItemsInTableView:tableView]];
    }];
}

- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator API_AVAILABLE(ios(13.0)){
    typeof(self) __weak weakSelf = self;
    [animator addCompletion:^{
        [[weakSelf navController] pushViewController:weakSelf.previewPackageDepictionVC animated:YES];
    }];
}

- (void)scrollToTop {
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBDatabaseCompletedUpdate" object:nil];
}

@end
