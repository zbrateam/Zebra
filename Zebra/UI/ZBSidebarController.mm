//
//  ZBSidebarController.m
//  Zebra
//
//  Created by Wilson Styres on 3/31/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBSidebarController.h"

#import <UI/Home/ZBHomeViewController.h>
#import <UI/Sources/ZBSourceListViewController.h>
#import <UI/Packages/ZBPackageListViewController.h>
#import <UI/Search/ZBSearchViewController.h>
#import <UI/Queue/ZBQueueViewController.h>

#import <ZBSettings.h>

#import <Plains/Queue/PLQueue.h>
#import <Plains/Managers/PLPackageManager.h>
#import <Plains/Managers/PLSourceManager.h>
#import <Plains/Model/PLPackage.h>

@interface ZBSidebarController () {
    NSArray *titles;
    NSArray *icons;
    UIViewController *sidebar;
    UITableView *sidebarTableView;
    UISearchBar *searchBar;
    NSArray *searchResults;
    UITableView *searchResultsTableView;
    UIViewController *searchResultsController;
    NSUInteger selectedIndex;
    NSUInteger queueCount;
    NSUInteger updates;
    NSLayoutConstraint *resultsTableViewHeightConstraint;
    
#if TARGET_OS_MACCATALYST
    NSToolbar *toolbar;
    NSMutableArray *toolbarButtons;
#endif
}
@end

@implementation ZBSidebarController

- (instancetype)init API_AVAILABLE(ios(14.0), macCatalyst(14.0)) {
    self = [super initWithStyle:UISplitViewControllerStyleDoubleColumn];
    
    if (self) {
        self.preferredPrimaryColumnWidthFraction = 0.22;
        self.primaryBackgroundStyle = UISplitViewControllerBackgroundStyleSidebar;
        self.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
        
        sidebar = [[UIViewController alloc] init];
        
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
        searchBar.delegate = self;
        searchBar.placeholder = @"Search";
        searchBar.searchBarStyle = UISearchBarStyleMinimal;
        searchBar.searchTextField.backgroundColor = [[UIColor systemGrayColor] colorWithAlphaComponent:0.2];
        
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor secondarySystemBackgroundColor];
        backgroundView.layer.cornerRadius = 10.0;
        
        searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        searchResultsTableView.delegate = self;
        searchResultsTableView.dataSource = self;
        searchResultsTableView.hidden = YES;
        searchResultsTableView.backgroundView = backgroundView;
        
        sidebarTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        sidebarTableView.delegate = self;
        sidebarTableView.dataSource = self;
        sidebarTableView.scrollEnabled = NO;
        
        [sidebar.view addSubview:searchBar];
        [sidebar.view addSubview:sidebarTableView];
        [sidebar.view addSubview:searchResultsTableView];
        
        [NSLayoutConstraint activateConstraints:@[
            [searchBar.topAnchor constraintEqualToAnchor:sidebar.view.safeAreaLayoutGuide.topAnchor],
            [searchBar.leadingAnchor constraintEqualToAnchor:sidebar.view.safeAreaLayoutGuide.leadingAnchor constant:sidebarTableView.layoutMargins.left],
            [searchBar.trailingAnchor constraintEqualToAnchor:sidebar.view.safeAreaLayoutGuide.trailingAnchor constant:-sidebarTableView.layoutMargins.right],
            [searchBar.heightAnchor constraintEqualToConstant:44.0],
            [sidebarTableView.topAnchor constraintEqualToAnchor:searchBar.bottomAnchor constant:8.0],
            [sidebarTableView.leadingAnchor constraintEqualToAnchor:sidebar.view.safeAreaLayoutGuide.leadingAnchor],
            [sidebarTableView.trailingAnchor constraintEqualToAnchor:sidebar.view.safeAreaLayoutGuide.trailingAnchor],
            [sidebarTableView.bottomAnchor constraintEqualToAnchor:sidebar.view.safeAreaLayoutGuide.bottomAnchor],
            [searchResultsTableView.leadingAnchor constraintEqualToAnchor:searchBar.leadingAnchor],
            [searchResultsTableView.trailingAnchor constraintEqualToAnchor:searchBar.trailingAnchor],
            [searchResultsTableView.topAnchor constraintEqualToAnchor:searchBar.bottomAnchor],
        ]];
        resultsTableViewHeightConstraint = [searchResultsTableView.heightAnchor constraintEqualToConstant:44];
        resultsTableViewHeightConstraint.active = YES;
        
        searchBar.translatesAutoresizingMaskIntoConstraints = NO;
        sidebarTableView.translatesAutoresizingMaskIntoConstraints = NO;
        searchResultsTableView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self setViewController:sidebar forColumn:UISplitViewControllerColumnPrimary];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateQueue:) name:PLQueueUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUpdates:) name:PLDatabaseUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showRefreshIndicator) name:PLStartedSourceRefreshNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideRefreshIndicator) name:PLFinishedSourceRefreshNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PLQueueUpdateNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationController *homeNavController = [[UINavigationController alloc] init];
    [homeNavController setViewControllers:@[[[ZBHomeViewController alloc] init]] animated:NO];
    [homeNavController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Home" image:[UIImage systemImageNamed:@"house"] tag:0]];
    [homeNavController.navigationBar setPrefersLargeTitles:YES];
    
    UINavigationController *sourcesNavController = [[UINavigationController alloc] init];
    [sourcesNavController setViewControllers:@[[[ZBSourceListViewController alloc] init]] animated:NO];
    [sourcesNavController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Sources" image:[UIImage systemImageNamed:@"books.vertical"] tag:1]];
    [sourcesNavController.navigationBar setPrefersLargeTitles:YES];
    
    UINavigationController *packagesNavController = [[UINavigationController alloc] init];
    [packagesNavController setViewControllers:@[[[ZBPackageListViewController alloc] init]] animated:NO];
    [packagesNavController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Installed" image:[UIImage systemImageNamed:@"shippingbox"] tag:2]];
    [packagesNavController.navigationBar setPrefersLargeTitles:YES];
    
    UINavigationController *queueNavController = [[UINavigationController alloc] init];
    [queueNavController setViewControllers:@[[[ZBQueueViewController alloc] init]] animated:NO];
    [queueNavController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Queue" image:[UIImage systemImageNamed:@"text.append"] tag:4]];
    [queueNavController.navigationBar setPrefersLargeTitles:YES];
    
    UINavigationController *settingsNavController = [[UINavigationController alloc] init];
    [settingsNavController setViewControllers:@[[[UIViewController alloc] init]] animated:NO];
    [settingsNavController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage systemImageNamed:@"gearshape"] tag:5]];
    [settingsNavController.navigationBar setPrefersLargeTitles:YES];
    
    self->updates = [[PLPackageManager sharedInstance] updates].count;
    
    NSArray *controllers = @[homeNavController, sourcesNavController, packagesNavController, queueNavController, settingsNavController];
#if TARGET_OS_MACCATALYST
    for (UINavigationController *controller in controllers) {
        [controller setDelegate:self];
        [controller setNavigationBarHidden:YES animated:NO];
    }
#endif
    self.controllers = controllers;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setViewController:_controllers[0] forColumn:UISplitViewControllerColumnSecondary];
    
#if TARGET_OS_MACCATALYST
    [self setTitle:_controllers[0].tabBarItem.title];
    [sidebar.navigationController setNavigationBarHidden:YES animated:animated]; 
#endif
}

#pragma mark - Sidebar Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == sidebarTableView) {
        return _controllers.count;
    } else if (tableView == searchResultsTableView) {
        return searchResults.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == sidebarTableView) {
        return [self sidebarCellForRowAtIndexPath:indexPath];
    } else if (tableView == searchResultsTableView) {
        return [self resultsCellForRowAtIndexPath:indexPath];
    }
    return NULL;
}

- (UITableViewCell *)sidebarCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"sidebarCell"];
    
    UITabBarItem *tabItem = _controllers[indexPath.row].tabBarItem;
    cell.textLabel.text = tabItem.title;
    cell.imageView.image = tabItem.image;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
    if (indexPath.row == 1) {
        
    } else if (indexPath.row == 2) {
        if (self->updates) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self->updates];
        } else {
            cell.detailTextLabel.text = nil;
        }
    } else if (indexPath.row == 3) {
        if (self->queueCount) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self->queueCount];
        } else {
            cell.detailTextLabel.text = nil;
        }
    }
    
    return cell;
}

- (UITableViewCell *)resultsCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"resultsCell"];
    
    NSString *searchTerm = searchBar.text;
    PLPackage *package = searchResults[indexPath.row];
    
    cell.textLabel.textColor = [UIColor secondaryLabelColor];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:package.name];
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor labelColor] range:NSMakeRange(0, searchTerm.length)];
    cell.textLabel.attributedText = text;
    
    cell.imageView.image = [UIImage systemImageNamed:@"magnifyingglass"];
    cell.imageView.tintColor = [UIColor secondaryLabelColor];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == searchResultsTableView) {
        return 33;
    } else {
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == searchResultsTableView) {
        
    } else if (tableView == sidebarTableView) {
        searchBar.text = @"";
        [self setViewController:_controllers[indexPath.row] forColumn:UISplitViewControllerColumnSecondary];
        
    #if TARGET_OS_MACCATALYST
        [self setTitle:_controllers[indexPath.row].tabBarItem.title];
    #endif
    }
}

#if TARGET_OS_MACCATALYST

-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    self->toolbar = toolbar;
    
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    if ([itemIdentifier isEqualToString:@"backButton"]) {
        [toolbarItem setImage:[UIImage systemImageNamed:@"chevron.left"]];
        [toolbarItem setNavigational:YES];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(backButton:)];
    } else if ([itemIdentifier isEqualToString:@"addButton"]) {
        [toolbarItem setImage:[UIImage systemImageNamed:@"plus"]];
        
        UINavigationController *navController = self.viewControllers[1];
        [toolbarItem setTarget:navController.topViewController];
        [toolbarItem setAction:@selector(addButton:)];
    } else if ([itemIdentifier isEqualToString:@"refreshButton"]) {
        [toolbarItem setImage:[UIImage systemImageNamed:@"arrow.clockwise"]];
        
        UINavigationController *navController = self.viewControllers[1];
        [toolbarItem setTarget:navController.topViewController];
        [toolbarItem setAction:@selector(refreshButton:)];
    } else if ([itemIdentifier isEqualToString:@"confirmButton"]) {
        [toolbarItem setImage:[UIImage systemImageNamed:@"esim"]];
        
        UINavigationController *navController = self.viewControllers[1];
        [toolbarItem setTarget:navController.topViewController];
        [toolbarItem setAction:@selector(confirmButton:)];
    }
    
    return toolbarItem;
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    self->toolbar = toolbar;
    
    return @[];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    self->toolbar = toolbar;
    
    return @[@"backButton", @"addButton", @"refreshButton", @"confirmButton"];
}

- (void)backButton:(id)sender {
    UINavigationController *controller = self.viewControllers[1];
    [controller popViewControllerAnimated:YES];
}

- (void)addToolbarItem:(NSString *)identifier {
    if (!toolbarButtons) toolbarButtons = [NSMutableArray new];
    NSUInteger index = toolbarButtons.count;
    [toolbarButtons insertObject:identifier atIndex:index];
    [toolbar insertItemWithItemIdentifier:identifier atIndex:index];
}

- (void)removeToolbarItem:(NSString *)identifier {
    NSUInteger index = [toolbarButtons indexOfObject:identifier];
    if (index != NSNotFound) {
        [toolbarButtons removeObjectAtIndex:index];
        [toolbar removeItemAtIndex:index];
    }
}

- (void)setShowBackButton:(BOOL)showBackButton {
    if (!_showBackButton && showBackButton) {
        [self addToolbarItem:@"backButton"];
    } else if (_showBackButton && !showBackButton) {
        [self removeToolbarItem:@"backButton"];
    }
    
    _showBackButton = showBackButton;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    
    [[[[[UIApplication sharedApplication] delegate] window] windowScene] setTitle:title];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self setShowBackButton:viewController != navigationController.viewControllers[0]]; // Show the back button if the view controller is the first one in the stack
    [self setTitle:viewController.title];
    
    for (NSString *button in [toolbarButtons copy]) {
        if ([button isEqual:@"backButton"]) continue;
        
        [self removeToolbarItem:button];
    }
    
    if ([viewController respondsToSelector:@selector(toolbarItems)]) {
        NSArray *toolbarItems = [viewController performSelector:@selector(toolbarItems)];
        
        for (NSString *button in toolbarItems) {
            [self addToolbarItem:button];
        }
    }
}

#endif

#pragma mark - Properties

- (void)setControllers:(NSArray <UIViewController *> *)controllers {
    _controllers = controllers;
    
    [sidebarTableView reloadData];
}

#pragma mark - Queue

- (void)updateQueue:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->queueCount = [notification.userInfo[@"count"] unsignedIntValue];
        [self->sidebarTableView reloadData];
    });
}

- (void)updateUpdates:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->updates = [notification.userInfo[@"count"] unsignedIntValue];
        [self->sidebarTableView reloadData];
    });
}

- (void)showRefreshIndicator {
    dispatch_async(dispatch_get_main_queue(), ^{
        UITableViewCell *cell = [self->sidebarTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        UIActivityIndicatorView *sourceRefreshIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyle)12];
        sourceRefreshIndicator.color = [UIColor secondaryLabelColor];
        [sourceRefreshIndicator startAnimating];
        cell.accessoryView = sourceRefreshIndicator;
    });
}

- (void)hideRefreshIndicator {
    dispatch_async(dispatch_get_main_queue(), ^{
        UITableViewCell *cell = [self->sidebarTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        cell.accessoryView = NULL;
    });
}

#pragma mark - Search Bar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        searchResultsTableView.hidden = YES;
        searchResults = nil;
        return;
    }
    
    searchResultsTableView.hidden = NO;
    [[PLPackageManager sharedInstance] searchForPackagesWithNamePrefix:searchText completion:^(NSArray<PLPackage *> * _Nonnull packages) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->searchResults = packages;
            
            CGFloat height = 33;
            height *= packages.count;
            height = MIN(height, 33 * 10);
            self->resultsTableViewHeightConstraint.constant = height;
            
            [self->searchResultsTableView reloadData];
            [self->searchResultsTableView setNeedsDisplay];
            
            if (self->searchResults.count == 0) {
                self->searchResultsTableView.hidden = YES;
                self->searchResults = nil;
                return;
            }
        });
    }];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searchResultsTableView.hidden = searchBar.text.length < 1;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    searchResultsTableView.hidden = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if (searchResults.count == 1) {
        
    } else {
        ZBPackageListViewController *results = [[ZBPackageListViewController alloc] initWithPackages:searchResults];
        results.title = [NSString stringWithFormat:@"Results for \"%@\"", searchBar.text];
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:results];
#if TARGET_OS_MACCATALYST
        [navController setDelegate:self];
        [navController setNavigationBarHidden:YES animated:NO];
#endif
        
        [self setViewController:navController forColumn:UISplitViewControllerColumnSecondary];
        
        [searchBar resignFirstResponder];
    }
}


// dry!!!!
- (void)requestSourceRefresh {
    [self refreshSources:NO];
}

- (void)refreshSources:(BOOL)userRequested {
    BOOL needsUpdate = NO;
    if (!userRequested && [ZBSettings wantsAutoRefresh]) {
        NSDate *currentDate = [NSDate date];
        NSDate *lastUpdatedDate = [ZBSettings lastSourceUpdate];

        if (lastUpdatedDate != NULL) {
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSUInteger unitFlags = NSCalendarUnitMinute;
            NSDateComponents *components = [gregorian components:unitFlags fromDate:lastUpdatedDate toDate:currentDate options:0];

            needsUpdate = ([components minute] >= 30);
        } else {
            needsUpdate = YES;
        }
    }
    
    if (userRequested || needsUpdate) {
        [[PLSourceManager sharedInstance] refreshSources];
    }
}

@end
