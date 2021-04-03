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

@interface ZBSidebarController () {
    NSArray *titles;
    NSArray *icons;
    UIViewController *sidebar;
    UITableView *tableView;
    NSUInteger selectedIndex;
}
@end

@implementation ZBSidebarController

- (instancetype)init {
    self = [super initWithStyle:UISplitViewControllerStyleDoubleColumn];
    
    if (self) {
        self.preferredPrimaryColumnWidthFraction = 0.22;
        self.primaryBackgroundStyle = UISplitViewControllerBackgroundStyleSidebar;
        self.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
        
        sidebar = [[UIViewController alloc] init];
        
        tableView = [[UITableView alloc] initWithFrame:sidebar.view.frame];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.delegate = self;
        tableView.dataSource = self;
        
        [sidebar.view addSubview:tableView];
        
//        secondaryController = [[UINavigationController alloc] init];
//        secondaryController.navigationBar.hidden = YES;
        
        [self setViewController:sidebar forColumn:UISplitViewControllerColumnPrimary];
//        [self setViewController:secondaryController forColumn:UISplitViewControllerColumnSecondary];
    }
    
    return self;
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
    
    UINavigationController *settingsNavController = [[UINavigationController alloc] init];
    [settingsNavController setViewControllers:@[[[UIViewController alloc] init]] animated:NO];
    [settingsNavController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage systemImageNamed:@"gearshape"] tag:4]];
    [settingsNavController.navigationBar setPrefersLargeTitles:YES];
    
    self.controllers = @[homeNavController, sourcesNavController, packagesNavController, updatesNavController, settingsNavController];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setViewController:_controllers[0] forColumn:UISplitViewControllerColumnSecondary];
    
#if TARGET_OS_MACCATALYST
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
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"yowadup"];
    
    UITabBarItem *tabItem = _controllers[indexPath.row].tabBarItem;
    cell.textLabel.text = tabItem.title;
    cell.imageView.image = tabItem.image;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self setViewController:_controllers[indexPath.row] forColumn:UISplitViewControllerColumnSecondary];
}

#if TARGET_OS_MACCATALYST

-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    [toolbarItem setTitle:@"Sidebar"];
    [toolbarItem setImage:[UIImage systemImageNamed:@"sidebar.left"]];
    
    return toolbarItem;
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return @[NSToolbarToggleSidebarItemIdentifier];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

#endif

#pragma mark - Properties

- (void)setControllers:(NSArray <UIViewController *> *)controllers {
    _controllers = controllers;
    
    [tableView reloadData];
}

- (void)setViewController:(UIViewController *)vc forColumn:(UISplitViewControllerColumn)column {
    [super setViewController:vc forColumn:column];
}

@end
