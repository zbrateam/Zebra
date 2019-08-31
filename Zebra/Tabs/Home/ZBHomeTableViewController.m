//
//  ZBHomeTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 8/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <ZBSettings.h>
#import "ZBHomeTableViewController.h"
#import <Views/ZBFeaturedTableViewCell.h>
#import <Views/ZBFeaturedCollectionViewCell.h>
#import <Database/ZBDatabaseManager.h>
#import <Repos/Helpers/ZBRepo.h>
#import <ZBAppDelegate.h>

@interface ZBHomeTableViewController () {
    NSMutableArray *featuredPackages;
}

@end

@implementation ZBHomeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (![[NSFileManager defaultManager] fileExistsAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"cache/featured.plist"]]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self cacheFeaturedPackages];
        });
    } else {
        [self loadFeaturedFromCache];
    }
    
    // From: https://stackoverflow.com/a/48837322
    UIVisualEffectView *fxView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    [fxView setFrame:CGRectOffset(CGRectInset(self.navigationController.navigationBar.bounds, 0, -12), 0, -60)];
    [self.navigationController.navigationBar setTranslucent:YES];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar insertSubview:fxView atIndex:1];
}

- (void)cacheFeaturedPackages {
    NSMutableArray <ZBRepo *>*featuredRepos = [[[ZBDatabaseManager sharedInstance] repos] mutableCopy];
    NSMutableArray *saveArray = [NSMutableArray new];
    dispatch_group_t group = dispatch_group_create();
    for (ZBRepo *repo in featuredRepos) {
        NSString *basePlusHttp;
        if (repo.isSecure) {
            basePlusHttp = [NSString stringWithFormat:@"https://%@", repo.baseURL];
        } else {
            basePlusHttp = [NSString stringWithFormat:@"http://%@", repo.baseURL];
        }
        dispatch_group_enter(group);
        NSURL *requestURL = [NSURL URLWithString:@"sileo-featured.json" relativeToURL:[NSURL URLWithString:basePlusHttp]];
        NSLog(@"[Zebra] Cached JSON request URL: %@", requestURL.absoluteString);
        NSURL *checkingURL = requestURL;
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithURL:checkingURL
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                    if (data != nil && (long)[httpResponse statusCode] != 404) {
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                        NSLog(@"[Zebra] JSON response data: %@", json);
                        if (!repo.supportsFeaturedPackages) {
                            repo.supportsFeaturedPackages = YES;
                        }
                        if ([json objectForKey:@"banners"]) {
                            NSArray *banners = [json objectForKey:@"banners"];
                            if (banners.count) {
                                [saveArray addObjectsFromArray:banners];
                            }
                        }
                    }
                    dispatch_group_leave(group);
                }] resume];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = TRUE;
        if (![fileManager fileExistsAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"cache"] isDirectory:&isDir]) {
            [fileManager createDirectoryAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"cache"] withIntermediateDirectories:NO attributes:nil error:nil];
        }
        [saveArray writeToFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"cache/featured.plist"] atomically:YES];
        [self loadFeaturedFromCache];
    });
}

- (void)loadFeaturedFromCache {

    if (featuredPackages == NULL) {
        featuredPackages = [NSMutableArray new];
    }

    NSArray *featuredCache = [NSArray arrayWithContentsOfFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"cache/featured.plist"]];

    for (NSDictionary *cache in featuredCache) {
        [featuredPackages addObject:[[ZBDatabaseManager sharedInstance] topVersionForPackageID:cache[@"package"]]];
    }

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 0)] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [featuredPackages count] == 0 ? 0 : 1; //Don't show featured packages if they haven't loaded yet
        case 1:
            return 3;
        case 2:
            return 1;
        case 3:
            return 3;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: { //Featured Packages
            ZBFeaturedTableViewCell *cell = (ZBFeaturedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"featuredPackageTableCell" forIndexPath:indexPath];

            [cell updatePackages:featuredPackages];

            return cell;
        }
        case 1: { //Community News
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"newsTableCell" forIndexPath:indexPath];
            
            return cell;
        }
        case 2: { //Changelog
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"iconTableCell" forIndexPath:indexPath];
            
            return cell;
        }
        case 3: { //Links
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"buttonTableCell" forIndexPath:indexPath];
            
            return cell;
        }
//        case 4: { //Credits and Device information
//            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"newsTableCell" forIndexPath:indexPath];
//        }
        default: {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"somethingWrongIHoldMyHead"];

            cell.textLabel.text = @"Something is very wrong here...";

            return cell;
        }
    }
}

#pragma mark - Table view layout

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"headerTableCell"];
        
        cell.textLabel.text = @"Community News";
        
        return cell;
    }
    
    return NULL;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return 38;
    }
    else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 246;
        case 1:
        case 2:
            return 61;
        case 3:
            return 52;
        default:
            return 0;
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
