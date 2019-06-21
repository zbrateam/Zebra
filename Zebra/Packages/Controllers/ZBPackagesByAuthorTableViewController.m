//
//  ZBPackagesByAuthorTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/20/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackagesByAuthorTableViewController.h"

@interface ZBPackagesByAuthorTableViewController (){
    NSArray *moreByAuthor;
}

@end

@implementation ZBPackagesByAuthorTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    moreByAuthor = [[ZBDatabaseManager sharedInstance] packagesByAuthor:self.package.author];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.navigationItem.title = self.developerName;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:TRUE];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return moreByAuthor.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackageTableViewCell *cell = (ZBPackageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
    
    if ([ZBDarkModeHelper darkModeEnabled]) {
        cell.packageLabel.textColor = [UIColor whiteColor];//[UIColor cellPrimaryTextColor];
        cell.descriptionLabel.textColor = [UIColor lightGrayColor];//[UIColor cellSecondaryTextColor];
        cell.backgroundContainerView.backgroundColor = [UIColor colorWithRed:0.110 green:0.110 blue:0.114 alpha:1.0];//[UIColor cellBackgroundColor];
    } else {
        cell.packageLabel.textColor = [UIColor cellPrimaryTextColor];
        cell.descriptionLabel.textColor = [UIColor cellSecondaryTextColor];
        cell.backgroundContainerView.backgroundColor = [UIColor cellBackgroundColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackage *package = (ZBPackage *)[[ZBDatabaseManager sharedInstance] topVersionForPackage:[moreByAuthor objectAtIndex:indexPath.row]];
    [(ZBPackageTableViewCell *)cell updateData:package];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"segueMorePackagesToPackageDepiction" sender:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"segueMorePackagesToPackageDepiction"]) {
        ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
        NSIndexPath *indexPath = sender;
        
        destination.package = [[ZBDatabaseManager sharedInstance] topVersionForPackage:[moreByAuthor objectAtIndex:indexPath.row]];
    }
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
