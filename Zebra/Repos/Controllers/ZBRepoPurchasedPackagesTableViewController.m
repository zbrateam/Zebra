//
//  ZBRepoPurchasedPackagesTableViewController.m
//  Zebra
//
//  Created by midnightchips on 5/11/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "PackageIconDownloader.h"
#import "NSString+UDID.h"
#import "ZBRepoPurchasedPackagesTableViewController.h"
#import <sys/utsname.h>
#import "UIBarButtonItem+blocks.h"
#import "ZBPackageTableViewCell.h"
#import "ZBPackageDepictionViewController.h"
#import <UIColor+GlobalColors.h>
#import <ZBAppDelegate.h>

@interface ZBRepoPurchasedPackagesTableViewController ()
@property (nonatomic, strong) NSMutableDictionary *imageDownloadsInProgress;
@end

@implementation ZBRepoPurchasedPackagesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.databaseManager = [ZBDatabaseManager sharedInstance];
    _keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    self.packages = [NSMutableArray new];
    if (self.repoImage != NULL) {
        UIView *container = [[UIView alloc] initWithFrame:self.navigationItem.titleView.frame];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        imageView.center = self.navigationItem.titleView.center;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.image = self.repoImage;
        imageView.layer.cornerRadius = 5;
        imageView.layer.masksToBounds = YES;
        [container addSubview:imageView];
        
        self.navigationItem.titleView = container;
    }
    self.title = self.repoName;
    self.logOut = [[UIBarButtonItem alloc] initWithTitle:@"Log Out" style:UIBarButtonItemStylePlain actionHandler:^{
        [self logoutRepo];
    }];
    [self.navigationItem setRightBarButtonItem:self.logOut];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil]
         forCellReuseIdentifier:@"packageTableViewCell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self terminateAllDownloads];
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:TRUE];
    [self listPurchasedSileoPackages];
}

-(void)listPurchasedSileoPackages{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    
    NSDictionary *test = @{ @"token": _keychain[self.repoEndpoint],
                            @"udid": NSString.UDID,
                            @"device":[self deviceModelID]};
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:test options:(NSJSONWritingOptions)0 error:nil];
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@user_info", self.repoEndpoint]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        //self.packages = json[@"items"];
        [self.packages removeAllObjects];
        for(NSString *packageID in json[@"items"]){
            @try{
                ZBPackage *package = [self.databaseManager topVersionForPackageID:packageID];
                [self.packages addObject:package];
            }
            @catch (NSException *exception){
                NSLog(@"Package Unavailable %@ %@", exception.reason, packageID);
            }
            
        }
        if(json[@"user"]){
            if([json valueForKeyPath:@"user.name"]){
                self.userName = [json valueForKeyPath:@"user.name"];
            }
            if([json valueForKeyPath:@"user.email"]){
                self.userEmail = [json valueForKeyPath:@"user.email"];
            }
            
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        
    }] resume];
}

-(void)logoutRepo{
    [_keychain removeItemForKey:self.repoEndpoint];
    UINavigationController *navigationController = self.navigationController;
    [navigationController popViewControllerAnimated:YES];
}

- (NSString *)deviceModelID {
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 0;
    }
    else{
        return 25;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        return 65;
    }
    else {
        return 44;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    else {
        return [self.packages count];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) { //Account Cell
        cell.textLabel.text = self.userName;
        cell.detailTextLabel.text = self.userEmail;
    }
    else { //Package Cell
        ZBPackage *package = (ZBPackage *)[_packages objectAtIndex:indexPath.row];
        [(ZBPackageTableViewCell *)cell updateData:package];
        if (!package.iconImage) {
            NSURL *testURL = [NSURL URLWithString:package.iconPath];
            if (testURL && testURL.scheme && testURL.host && !testURL.isFileURL && self.tableView.dragging == NO && self.tableView.decelerating == NO) {
                [self startIconDownload:package atIndexPath:indexPath];
                ((ZBPackageTableViewCell *) cell).iconImageView.image = [UIImage imageNamed:@"Other"];
            } else {
                ((ZBPackageTableViewCell *) cell).iconImageView.image = [UIImage imageNamed:@"Other"];
            }
        }
        else {
            ((ZBPackageTableViewCell *) cell).iconImageView.image = package.iconImage;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountCell"];
        
        return cell;
    }
    else {
        ZBPackageTableViewCell *cell = (ZBPackageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
        
        return cell;
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        [self performSegueWithIdentifier:@"seguePurchasesToPackageDepiction" sender:indexPath];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width - 10, 18)];
    
    [label setFont:[UIFont boldSystemFontOfSize:15]];
    [label setText:@"Purchased Packages"];
    [view addSubview:label];
    
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    // align label from the left and right
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[label]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
    
    // align label from the bottom
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label]-5-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
    
    
    return view;
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


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"seguePurchasesToPackageDepiction"]) {
        ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
        NSIndexPath *indexPath = sender;
        
        destination.package = [_packages objectAtIndex:indexPath.row];
        
        [_databaseManager closeDatabase];
    }
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.tableView
                              indexPathForRowAtPoint:location];
    
    ZBPackageTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    previewingContext.sourceRect = cell.frame;
    
    ZBPackageDepictionViewController *packageDepictionVC = (ZBPackageDepictionViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"packageDepictionVC"];
    
    packageDepictionVC.package = [self.packages objectAtIndex:indexPath.row];
    
    return packageDepictionVC;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}

- (void)startIconDownload:(ZBPackage *)package atIndexPath: (NSIndexPath *)indexPath
{
    if (package.iconImage != NULL) {
        ZBPackageTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.iconImageView.image = package.iconImage;
    }
    else {
        NSURL *testURL = [NSURL URLWithString:package.iconPath];
        if (testURL && testURL.scheme && testURL.host && !testURL.isFileURL) {
            PackageIconDownloader *iconDownloader = (self.imageDownloadsInProgress)[indexPath];
            if (iconDownloader == nil)
            {
                iconDownloader = [[PackageIconDownloader alloc] init];
                iconDownloader.package = package;
                [iconDownloader setCompletionHandler:^{
                    ZBPackageTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                    cell.iconImageView.image = package.iconImage;
                    [self.imageDownloadsInProgress removeObjectForKey:indexPath];
                    
                }];
                (self.imageDownloadsInProgress)[indexPath] = iconDownloader;
                [iconDownloader startDownload];
            }
        }
    }
}

- (void)terminateAllDownloads
{
    // terminate all pending download connections
    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
    
    [self.imageDownloadsInProgress removeAllObjects];
}

- (void)loadImagesForOnscreenRows
{
    if (self.packages.count > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            ZBPackage *package = (self.packages)[indexPath.row];
            
            if (!package.iconImage)
            {
                [self startIconDownload:package atIndexPath:indexPath];
            }
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        [self loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}

- (void)dealloc
{
    [self terminateAllDownloads];
}

@end
