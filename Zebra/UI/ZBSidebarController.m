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

#import <Plains/PLQueue.h>

@interface ZBSidebarController () {
    NSArray *titles;
    NSArray *icons;
    UIViewController *sidebar;
    UITableView *tableView;
    NSUInteger selectedIndex;
    NSToolbar *toolbar;
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
        
        tableView = [[UITableView alloc] initWithFrame:sidebar.view.frame style:UITableViewStyleGrouped];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.delegate = self;
        tableView.dataSource = self;
        
//        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"sidebarCell"];
        
        [sidebar.view addSubview:tableView];
        
        [self setViewController:sidebar forColumn:UISplitViewControllerColumnPrimary];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateQueue:) name:PLQueueUpdateNotification object:nil];
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
    
    UINavigationController *updatesNavController = [[UINavigationController alloc] init];
    [updatesNavController setViewControllers:@[[[UIViewController alloc] init]] animated:NO];
    [updatesNavController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Updates" image:[UIImage systemImageNamed:@"square.and.arrow.down"] tag:3]];
    [updatesNavController.navigationBar setPrefersLargeTitles:YES];
    
    UINavigationController *queueNavController = [[UINavigationController alloc] init];
    [queueNavController setViewControllers:@[[[ZBQueueViewController alloc] init]] animated:NO];
    [queueNavController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Queue" image:[UIImage systemImageNamed:@"text.append"] tag:4]];
    [queueNavController.navigationBar setPrefersLargeTitles:YES];
    
    UINavigationController *settingsNavController = [[UINavigationController alloc] init];
    [settingsNavController setViewControllers:@[[[UIViewController alloc] init]] animated:NO];
    [settingsNavController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage systemImageNamed:@"gearshape"] tag:5]];
    [settingsNavController.navigationBar setPrefersLargeTitles:YES];
    
    self.controllers = @[homeNavController, sourcesNavController, packagesNavController, updatesNavController, queueNavController, settingsNavController];
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
    return _controllers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sidebarCell" forIndexPath:indexPath];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"sidebarCell"];
    
    UITabBarItem *tabItem = _controllers[indexPath.row].tabBarItem;
    cell.textLabel.text = tabItem.title;
    cell.imageView.image = tabItem.image;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setViewController:_controllers[indexPath.row] forColumn:UISplitViewControllerColumnSecondary];
    
#if TARGET_OS_MACCATALYST
    [self setTitle:_controllers[indexPath.row].tabBarItem.title];
#endif
}

#if TARGET_OS_MACCATALYST

-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    self->toolbar = toolbar;
    
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    [toolbarItem setImage:[UIImage systemImageNamed:@"chevron.left"]];
    [toolbarItem setNavigational:YES];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(backButton:)];
    
    return toolbarItem;
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    self->toolbar = toolbar;
    
    return @[];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    self->toolbar = toolbar;
    
    return @[@"backButton"];
}

- (void)backButton:(id)sender {
    UINavigationController *controller = self.viewControllers[1];
    [controller popViewControllerAnimated:YES];
}

- (void)setShowBackButton:(BOOL)showBackButton {
    if (!_showBackButton && showBackButton) {
        [toolbar insertItemWithItemIdentifier:@"backButton" atIndex:0];
    } else if (_showBackButton && !showBackButton) {
        [toolbar removeItemAtIndex:0];
    }
    
    _showBackButton = showBackButton;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    
    [[[[[UIApplication sharedApplication] delegate] window] windowScene] setTitle:title];
}

#endif

#pragma mark - Properties

- (void)setControllers:(NSArray <UIViewController *> *)controllers {
    _controllers = controllers;
    
    [tableView reloadData];
}

#pragma mark - Queue

- (void)updateQueue:(NSNotification *)notification {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    NSUInteger queueCount = [notification.userInfo[@"count"] unsignedIntValue];
    if (queueCount) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)queueCount];
    } else {
        cell.detailTextLabel.text = nil;
    }
}

@end
