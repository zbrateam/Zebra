//
//  ZBSidebarController.m
//  Zebra
//
//  Created by Wilson Styres on 3/31/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBSidebarController.h"

@interface ZBSidebarController () {
    NSArray *titles;
    NSArray *icons;
    UIViewController *sidebar;
}
@end

@implementation ZBSidebarController

- (instancetype)init {
    self = [super initWithStyle:UISplitViewControllerStyleDoubleColumn];
    
    if (self) {
        self.preferredPrimaryColumnWidthFraction = 0.22;
        self.primaryBackgroundStyle = UISplitViewControllerBackgroundStyleSidebar;
        self.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
        
        titles = @[@"Home", @"Sources", @"Installed", @"Updates", @"Settings"];
        icons = @[@"house", @"books.vertical", @"shippingbox", @"square.and.arrow.down", @"gearshape"];
        
        sidebar = [[UIViewController alloc] init];
        
        UITableView *tableView = [[UITableView alloc] initWithFrame:sidebar.view.frame];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.delegate = self;
        tableView.dataSource = self;
        
        [sidebar.view addSubview:tableView];
        
        [self setViewController:sidebar forColumn:UISplitViewControllerColumnPrimary];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
#if TARGET_OS_MACCATALYST
    [sidebar.navigationController setNavigationBarHidden:YES animated:animated];
#endif
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return titles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"yowadup"];
    
    cell.textLabel.text = titles[indexPath.row];
    cell.imageView.image = [UIImage systemImageNamed:icons[indexPath.row]];
    
    return cell;
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
