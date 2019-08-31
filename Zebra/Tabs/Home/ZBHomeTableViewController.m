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
#import <Views/ZBCommunityNewsTableViewCell.h>
#import <Views/ZBButtonTableViewCell.h>
#import <Views/ZBIconTableViewCell.h>
#import <Database/ZBDatabaseManager.h>
#import <Repos/Helpers/ZBRepo.h>
#import <ZBAppDelegate.h>

@interface ZBHomeTableViewController () {
    NSMutableArray *featuredPackages;
    NSArray<NSDictionary <NSString *, NSDictionary *> *> *communityNewsPosts;
}

@end

@implementation ZBHomeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (featuredPackages == NULL) {
        featuredPackages = [NSMutableArray new];
    }
    
    if (communityNewsPosts == NULL) {
        communityNewsPosts = [NSMutableArray new];
    }
    
    // From: https://stackoverflow.com/a/48837322
    UIVisualEffectView *fxView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    [fxView setFrame:CGRectOffset(CGRectInset(self.navigationController.navigationBar.bounds, 0, -12), 0, -60)];
    [self.navigationController.navigationBar setTranslucent:YES];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar insertSubview:fxView atIndex:1];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"cache/featured.plist"]]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self cacheFeaturedPackages];
        });
    } else {
        [self loadFeaturedFromCache];
    }
    
    [self getRedditPosts];
}

- (void)getRedditPosts {
    NSDate *creationDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"redditCheck"];
    if (!creationDate) {
        [self getRedditToken];
    }
    else {
        double seconds = [[NSDate date] timeIntervalSinceDate:creationDate];
        if (seconds > 3500) {
            [self getRedditToken];
        } else {
            [self getCommunityNewsPosts];
        }
    }
}

- (void)getRedditToken {
    NSURL *tokenURL = [NSURL URLWithString:@"https://ssl.reddit.com/api/v1/access_token"];
    NSString *grantType = @"grant_type=https://oauth.reddit.com/grants/installed_client&device_id=DO_NOT_TRACK_THIS_DEVICE";
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:tokenURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Zebra %@ iOS:%@", PACKAGE_VERSION, [[UIDevice currentDevice] systemVersion]] forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"Basic ZGZmVWtsVG9WY19ZV1E6IA==" forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:[grantType dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable dataTaskError) {
        if (dataTaskError != NULL) {
            NSLog(@"[Zebra] Error while getting reddit token: %@", dataTaskError);
            return;
        }
        
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        if (jsonError != NULL) {
            NSLog(@"[Zebra] Error while parsing reddit token JSON: %@", jsonError);
            return;
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[json objectForKey:@"access_token"] forKey:@"redditToken"];
        [defaults setObject:[NSDate date] forKey:@"redditCheck"];
        [defaults synchronize];
        [self getCommunityNewsPosts];
    }];
    
    [task resume];
}

- (void)getCommunityNewsPosts {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://oauth.reddit.com/r/jailbreak"]];
    [request setHTTPMethod:@"GET"];
    [request setValue:[NSString stringWithFormat:@"Zebra %@, iOS %@", PACKAGE_VERSION, [[UIDevice currentDevice] systemVersion]] forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", [[NSUserDefaults standardUserDefaults] valueForKey:@"redditToken"]] forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable dataTaskError) {
        if (dataTaskError != NULL) {
            NSLog(@"[Zebra] Error while getting reddit token: %@", dataTaskError);
            return;
        }
        
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        if (jsonError != NULL) {
            NSLog(@"[Zebra] Error while parsing reddit token JSON: %@", jsonError);
            return;
        }
        
        self->communityNewsPosts = [[json objectForKey:@"data"] objectForKey:@"children"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 1)] withRowAnimation:UITableViewRowAnimationFade];
        });
    }];
    
    [task resume];
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
    NSArray *featuredCache = [NSArray arrayWithContentsOfFile:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"cache/featured.plist"]];

    for (NSDictionary *cache in featuredCache) {
        [featuredPackages addObject:[[ZBDatabaseManager sharedInstance] topVersionForPackageID:cache[@"package"]]];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 0)] withRowAnimation:UITableViewRowAnimationFade];
    });
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
            return [communityNewsPosts count] == 0 ? 0 : ([communityNewsPosts count] > 3 ? 3 : [communityNewsPosts count]); //Show at most 3 news posts, otherwise show nothing or show as many as we got.
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
            ZBCommunityNewsTableViewCell *cell = (ZBCommunityNewsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"newsTableCell" forIndexPath:indexPath];
            
            NSDictionary *post = [[communityNewsPosts objectAtIndex:indexPath.row] objectForKey:@"data"];
            
            cell.titleLabel.text = [post objectForKey:@"title"];
            
            return cell;
        }
        case 2: { //Changelog
            ZBIconTableViewCell *cell = (ZBIconTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"iconTableCell" forIndexPath:indexPath];
            
            cell.titleLabel.text = @"Changelog";
            
            return cell;
        }
        case 3: { //Links
            ZBButtonTableViewCell *cell = (ZBButtonTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"buttonTableCell" forIndexPath:indexPath];
            
            switch (indexPath.row) {
                case 0:
                    cell.actionLabel.text = @"Join the Discord";
                    break;
                case 1:
                    cell.actionLabel.text = @"Follow @getZebra on Twitter";
                    break;
                case 2:
                    cell.actionLabel.text = @"Buy the Team a Coffee";
                    break;
            }
            
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

//#pragma mark - Navigation
//
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//
//}

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
@end
