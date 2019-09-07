//
//  ZBHomeTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 8/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@import SafariServices;

#import <ZBSettings.h>
#import "ZBHomeTableViewController.h"
#import <Views/ZBFeaturedTableViewCell.h>
#import <Views/ZBFeaturedCollectionViewCell.h>
#import <Views/ZBCommunityNewsTableViewCell.h>
#import <Views/ZBButtonTableViewCell.h>
#import <Views/ZBIconTableViewCell.h>
#import <Views/ZBFootnotesTableViewCell.h>
#import <Database/ZBDatabaseManager.h>
#import <Sources/Helpers/ZBRepo.h>
#import <Packages/Helpers/ZBPackage.h>
#import <ZBAppDelegate.h>
#import <Changelog/ZBChangelogTableViewController.h>
#import "ZBDevice.h"
#import <Tabs/Packages/Controllers/ZBPackageDepictionViewController.h>

@interface ZBHomeTableViewController () {
    NSMutableArray *featuredPackages;
    NSMutableArray *communityNewsPosts;
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
    
    [self downloadFeaturedPackages:false];
    [self getRedditPosts];
    
    //From: https://stackoverflow.com/a/48837322
    UIVisualEffectView *fxView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    fxView.backgroundColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:0.60];
    [fxView setFrame:CGRectOffset(CGRectInset(self.navigationController.navigationBar.bounds, 0, -12), 0, -60)];
    [self.navigationController.navigationBar setTranslucent:YES];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar insertSubview:fxView atIndex:1];
    
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 0.01f)]; // For removing gap at the top of the table view
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    
    if (@available(iOS 10.0, *)) {
        self.tableView.refreshControl = refreshControl;
    } else {
        [self.tableView addSubview:refreshControl];
    }
}

- (void)refreshTable {
    [self.refreshControl endRefreshing];
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
        
        NSArray<NSDictionary <NSString *, NSDictionary *> *> *children = [[json objectForKey:@"data"] objectForKey:@"children"];
        
        for (NSDictionary *child in children) {
            NSDictionary *post = [child objectForKey:@"data"];
            
            if ([[post objectForKey:@"stickied"] boolValue] == false && [self acceptableFlair:[post objectForKey:@"link_flair_text"]]) {
                [self->communityNewsPosts addObject:post];
            }
            
            if ([self->communityNewsPosts count] == 3) break;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView beginUpdates];
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:1];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        });
    }];
    
    [task resume];
}

- (BOOL)acceptableFlair:(NSString *)flairText {
    if (flairText != NULL && ![flairText isEqual:[NSNull null]]) {
        NSArray *acceptableFlairs = @[@"release", @"update", @"upcoming", @"news", @"tutorial", @"jailbreak release"];
        return [acceptableFlairs containsObject:[flairText lowercaseString]];
    }
    
    return false;
}

- (void)downloadFeaturedPackages:(BOOL)ignoreCaching {
    NSMutableArray <ZBRepo *> *repos = [[[ZBDatabaseManager sharedInstance] repos] mutableCopy];
    dispatch_group_t downloadGroup = dispatch_group_create();
    
    for (ZBRepo *repo in repos) {
        dispatch_group_enter(downloadGroup);
        
        NSURLSession *session;
        NSString *filePath = [[ZBAppDelegate listsLocation] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_Featured", [repo baseFileName]]];
        if (!ignoreCaching && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSError *fileError;
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&fileError];
            NSDate *date = fileError != nil ? [NSDate distantPast] : [attributes fileModificationDate];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            [formatter setTimeZone:gmt];
            [formatter setDateFormat:@"E, d MMM yyyy HH:mm:ss"];
            
            NSString *modificationDate = [NSString stringWithFormat:@"%@ GMT", [formatter stringFromDate:date]];
            
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            configuration.HTTPAdditionalHeaders = @{@"If-Modified-Since": modificationDate};;
            
            session = [NSURLSession sessionWithConfiguration:configuration];
        }
        else {
            session = [NSURLSession sharedSession];
        }
        
        NSMutableArray *featuredPackages = [NSMutableArray new];
        
        NSString *featuredURLString = repo.isSecure ? [NSString stringWithFormat:@"https://%@", repo.baseURL] : [NSString stringWithFormat:@"http://%@", repo.baseURL];

        NSURL *featuredURL = [NSURL URLWithString:@"sileo-featured.json" relativeToURL:[NSURL URLWithString:featuredURLString]];
        NSURLSessionDataTask *task = [session dataTaskWithURL:featuredURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            if (error != NULL) {
                NSLog(@"[Zebra] Error while downloading featured JSON for %@: %@", repo, error);
                dispatch_group_leave(downloadGroup);
                return;
            }
            
            if (data != NULL && [httpResponse statusCode] != 404) {
                NSError *jsonReadError;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonReadError];
                if (jsonReadError != NULL) {
                    NSLog(@"[Zebra] Error while parsing featured JSON for %@: %@", repo, jsonReadError);
                    dispatch_group_leave(downloadGroup);
                    return;
                }
                
                if ([json objectForKey:@"banners"]) {
                    NSArray *banners = [json objectForKey:@"banners"];
                    if (banners.count) {
                        [featuredPackages addObjectsFromArray:banners];
                    }
                }
            }
            
            NSString *filename = [NSString stringWithFormat:@"%@_Featured", [repo baseFileName]];
            if ([featuredPackages count] > 0) {
                [featuredPackages writeToFile:[[ZBAppDelegate listsLocation] stringByAppendingPathComponent:filename] atomically:true];
            }
            
            dispatch_group_leave(downloadGroup);
        }];
        
        [task resume];
    }
    
    dispatch_group_notify(downloadGroup, dispatch_get_main_queue(), ^{
        [self loadFeaturedPackagesFromCache];
    });
}

- (void)loadFeaturedPackagesFromCache {
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[ZBAppDelegate listsLocation] error:nil];
    NSArray *featuredCacheFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '_Featured'"]];

    for (NSString *path in featuredCacheFiles) {
        NSArray *contents = [NSArray arrayWithContentsOfFile:[[ZBAppDelegate listsLocation] stringByAppendingPathComponent:path]];
        for (NSDictionary *cache in contents) {
            ZBPackage *package = [[ZBDatabaseManager sharedInstance] topVersionForPackageID:cache[@"package"]];
            if (package != NULL) {
                package.bannerImageURL = [NSURL URLWithString:cache[@"url"]];
                
                [featuredPackages addObject:package];
            }
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [featuredPackages count] == 0 ? 0 : 1; //Don't show featured packages if they haven't loaded yet
        case 1:
            return [communityNewsPosts count] == 0 ? 0 : ([communityNewsPosts count] > 3 ? 3 : [communityNewsPosts count]); //Show at most 3 news posts, otherwise show nothing or show as many we got.
        case 2:
            return 1;
        case 3:
            return 3;
        case 4:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: { //Featured Packages
            ZBFeaturedTableViewCell *cell = (ZBFeaturedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"featuredPackageTableCell" forIndexPath:indexPath];

            cell.father = self;
            [cell updatePackages:featuredPackages];

            return cell;
        }
        case 1: { //Community News
            ZBCommunityNewsTableViewCell *cell = (ZBCommunityNewsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"newsTableCell" forIndexPath:indexPath];
            
            NSDictionary *post = [communityNewsPosts objectAtIndex:indexPath.row];
            NSMutableArray *components = [[[post objectForKey:@"title"] componentsSeparatedByString:@"] "] mutableCopy];
            
            NSString *title = @"Could not load post";
            if ([components count] > 2) {
                [components removeObjectAtIndex:0];
                title = [components componentsJoinedByString:@"] "];
            }
            else if ([components count] > 1) {
                title = components[1];
            }
            else {
                title = components[0];
            }
            
            cell.titleLabel.text = title;
            cell.tagLabel.text = [[post objectForKey:@"link_flair_text"] uppercaseString];
            cell.permalink = [post objectForKey:@"permalink"];
            
            return cell;
        }
        case 2: { //Changelog
            ZBIconTableViewCell *cell = (ZBIconTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"iconTableCell" forIndexPath:indexPath];
            
            cell.titleLabel.text = @"Changelog";
            cell.iconImageView.image = [UIImage imageNamed:@"Changelog"];
            cell.storyboardID = @"changelogController";
            
            return cell;
        }
        case 3: { //Links
            ZBButtonTableViewCell *cell = (ZBButtonTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"buttonTableCell" forIndexPath:indexPath];
            
            switch (indexPath.row) {
                case 0:
                    cell.actionLabel.text = @"Join Our Discord";
                    cell.actionLink = @"https://discordapp.com/invite/6CPtHBU";
                    break;
                case 1:
                    cell.actionLabel.text = @"Follow @getZebra on Twitter";
                    cell.actionLink = @"https://twitter.com/getZebra";
                    break;
                case 2:
                    cell.actionLabel.text = @"Buy the Team Coffee";
                    cell.actionLink = @"https://paypal.me/wstyres";
                    break;
            }
            
            return cell;
        }
        case 4: { //Credits and Device information
            ZBFootnotesTableViewCell *cell = (ZBFootnotesTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"footnotesTableCell" forIndexPath:indexPath];
            
            [cell.deviceInfoLabel setText:[NSString stringWithFormat:@"%@ - iOS %@ - Zebra %@ \n%@", [ZBDevice deviceModelID], [[UIDevice currentDevice] systemVersion], PACKAGE_VERSION, [ZBDevice UDID]]];
            
            return cell;
        }
        default: {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"somethingWrongIHoldMyHead"];

            cell.textLabel.text = @"Something is very wrong here...";

            return cell;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    switch (indexPath.section) {
        case 1: { //Community News
            if ([cell isKindOfClass:[ZBCommunityNewsTableViewCell class]]) {
                ZBCommunityNewsTableViewCell *newsCell = (ZBCommunityNewsTableViewCell *)cell;
                
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://reddit.com/%@", newsCell.permalink]];
                SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
                if (@available(iOS 10.0, *)) {
                    safariViewController.preferredControlTintColor = [UIColor tintColor];
                }
                
                [self presentViewController:safariViewController animated:true completion:nil];
            }
        }
        case 2: { //Changelog
            if ([cell isKindOfClass:[ZBIconTableViewCell class]]) {
                ZBIconTableViewCell *iconCell = (ZBIconTableViewCell *)cell;
                
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Home" bundle:nil];
                ZBChangelogTableViewController *changelogController = [storyboard instantiateViewControllerWithIdentifier:iconCell.storyboardID];
                
                [[self navigationController] pushViewController:changelogController animated:true];
            }
        }
        case 3: { //Links
            if ([cell isKindOfClass:[ZBButtonTableViewCell class]]) {
                ZBButtonTableViewCell *buttonCell = (ZBButtonTableViewCell *)cell;
                
                NSURL *url = [NSURL URLWithString:buttonCell.actionLink];
                SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
                if (@available(iOS 10.0, *)) {
                    safariViewController.preferredControlTintColor = [UIColor tintColor];
                }
                
                [self presentViewController:safariViewController animated:true completion:nil];
            }
        }
    }
}

#pragma mark - Table view layout

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1 && [communityNewsPosts count] != 0) {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 38)];
        
        UILabel *sectionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        UIFont *currentFont = sectionLabel.font;
        UIFont *newFont = [UIFont fontWithName:[NSString stringWithFormat:@"%@-Bold",currentFont.fontName] size:22];
        sectionLabel.font = newFont;
        
        [view addSubview:sectionLabel];
                
        [sectionLabel setTranslatesAutoresizingMaskIntoConstraints: NO];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[sectionLabel]-16-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(sectionLabel)]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-16-[sectionLabel]-5-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(sectionLabel)]];

        
        sectionLabel.text = @"Community News";
        
        return view;
    }
    
    return NULL;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1 && [communityNewsPosts count] != 0) {
        return 48;
    }
    else if (section == 3) {
        return 16;
    }
    else if (section == 4) {
        return 8;
    }
    else {
        return CGFLOAT_MIN;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 4) {
        return 16;
    }
    else {
        return CGFLOAT_MIN;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 252;
        case 1:
        case 2:
            return 60;
        case 3:
            return 44;
        case 4:
            return 70;
        default:
            return 0;
    }
}

- (void)showPackageDepiction:(ZBPackage *)package {
    NSLog(@"Ok son ill show %@", package);
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBPackageDepictionViewController *depiction = [storyboard instantiateViewControllerWithIdentifier:@"packageDepictionVC"];
    depiction.package = package;
    
    [[self navigationController] pushViewController:depiction animated:true];
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
@end
