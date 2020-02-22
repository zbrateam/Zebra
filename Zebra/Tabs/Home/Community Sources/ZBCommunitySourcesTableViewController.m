//
//  ZBCommunitySourcesTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBCommunitySourcesTableViewController.h"
#import <Database/ZBRefreshViewController.h>
#import <Sources/Views/ZBRepoTableViewCell.h>
#import <ZBLog.h>
#import <Tabs/Sources/Helpers/ZBSource.h>
#import <ZBDependencyResolver.h>
#import <Tabs/Sources/Controllers/ZBSourceImportTableViewController.h>
#import <ZBSettings.h>

@interface ZBCommunitySourcesTableViewController ()
@end

@implementation ZBCommunitySourcesTableViewController

@synthesize communitySources;
@synthesize repoManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.titleView = spinner;
    [spinner startAnimating];
    
    switch ([ZBSettings interfaceStyle]) {
        case ZBInterfaceStyleLight:
            break;
        case ZBInterfaceStyleDark:
        case ZBInterfaceStylePureBlack:
            spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
            break;
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRepoTableViewCell" bundle:nil] forCellReuseIdentifier:@"repoTableViewCell"];
    repoManager = [ZBSourceManager sharedInstance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    
    [self populateSources];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)populateSources {
    if (!communitySources) {
        communitySources = [NSMutableArray new];
    }
    else {
        [communitySources removeAllObjects];
    }
    
    //Populate package managers
    NSArray *managers = [self packageManagers];
    if ([managers count]) {
        [communitySources addObject:managers];
    }
    
    //Populate utility repo
    NSArray *utilityRepos = [self utilityRepos];
    if ([utilityRepos count]) {
        [communitySources addObject:utilityRepos];
    }
    [self.tableView reloadData];
    
    //Fetch community sources
    [self fetchCommunitySources];
}

- (void)fetchCommunitySources {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:@"https://getzbra.com/api/sources.json"]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSMutableArray *sources = [NSMutableArray new];
        if (data && !error) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            if ([json objectForKey:@"repos"]) {
                NSArray *repos = json[@"repos"];
                for (NSDictionary *repo in repos) {
                    NSString *version = [repo objectForKey:@"appVersion"];
                    NSString *url = [repo objectForKey:@"url"];
                    if ([ZBDependencyResolver doesVersion:PACKAGE_VERSION satisfyComparison:@">=" ofVersion:version] && ![ZBSource exists:url]) {
                        [sources addObject:repo];
                    }
                }
            }
        }
        if (error) {
            ZBLog(@"[Zebra] Error while trying to access community sources: %@", error);
        }
        
        if ([sources count]) {
            [self->communitySources addObject:sources];
        }
        else {
            [self->communitySources addObject:@[@{@"type": @"none"}]]; //None left message
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            self.navigationItem.titleView = NULL;
            self.navigationItem.title = NSLocalizedString(@"Community Sources", @"");
        });
    }];
    
    [task resume];
    
}

- (NSArray *)packageManagers {
    NSMutableArray *result = [NSMutableArray new];
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app/Cydia"]) {
        NSDictionary *dict = @{@"type" : @"transfer",
                               @"name" : @"Cydia",
                               @"label": [NSString stringWithFormat:NSLocalizedString(@"Transfer sources from %@ to Zebra", @""), @"Cydia"],
                               @"url"  : @"file:///var/mobile/Library/Caches/com.saurik.Cydia/sources.list",
                               @"icon" : @"file:///Applications/Cydia.app/Icon-60@2x.png"};
        [result addObject:dict];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Installer.app/Installer"]) {
        NSDictionary *dict = @{@"type" : @"transfer",
                                @"name" : @"Installer",
                                @"label": [NSString stringWithFormat:NSLocalizedString(@"Transfer sources from %@ to Zebra", @""), @"Installer"],
                                @"url"  : @"file:///var/mobile/Library/Application%20Support/Installer/APT/sources.list",
                                @"icon" : @"file:///Applications/Installer.app/AppIcon60x60@2x.png"};
        [result addObject:dict];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Sileo.app/Sileo"]) {
        NSDictionary *dict = @{@"type" : @"transfer",
                                @"name" : @"Sileo",
                                @"label": [NSString stringWithFormat:NSLocalizedString(@"Transfer sources from %@ to Zebra", @""), @"Sileo"],
                                @"url"  : @"file:///etc/apt/sources.list.d/sileo.sources",
                                @"icon" : @"file:///Applications/Sileo.app/AppIcon60x60@2x.png"};
        [result addObject:dict];
    }
    return result;
}

- (NSArray *)utilityRepos {
    NSMutableArray *result = [NSMutableArray new];
    if ([ZBDevice isChimera]) {
        NSDictionary *dict = @{@"type": @"utility",
                               @"name": @"Chimera",
                               @"url" : @"https://repo.chimera.sh/",
                               @"icon": @"https://repo.chimera.sh/CydiaIcon.png"};
        [result addObject:dict];
    }
    else if ([ZBDevice isUncover] || [ZBDevice isCheckrain]) { // unc0ver or checkra1n
        NSDictionary *dict = @{@"type": @"utility",
                               @"name": @"Bingner/Elucubratus",
                               @"url" : @"https://apt.bingner.com/",
                               @"icon": @"https://apt.bingner.com/CydiaIcon.png"};
        [result addObject:dict];
    }
    else if ([ZBDevice isElectra]) { // electra
        NSDictionary *dict = @{@"type": @"utility",
                               @"name": @"Electra's iOS Utilities",
                               @"url" : @"https://electrarepo64.coolstar.org/",
                               @"icon": @"https://electrarepo64.coolstar.org/CydiaIcon.png"};
        [result addObject:dict];
    }
    else { // cydia
        NSDictionary *dict = @{@"type": @"utility",
                               @"name": @"Cydia/Telesphoreo",
                               @"url" : @"http://apt.saurik.com/",
                               @"icon": @"http://apt.saurik.com/dists/ios/CydiaIcon.png"};
        [result addObject:dict];
    }
    return result;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [communitySources count] == 0 ? 1 : [communitySources count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [communitySources count] == 0 ? 1 : [[communitySources objectAtIndex:section] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *info = [[communitySources objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSString *type = [info objectForKey:@"type"];
    
    if ([type isEqualToString:@"none"]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"noneLeftCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noneLeftCell"];
        }
        
        cell.textLabel.text = NSLocalizedString(@"You’ve added all of the community sources", @"");
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor secondaryTextColor];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }
    
    ZBRepoTableViewCell *cell = (ZBRepoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor cellBackgroundColor];
    
    [cell.repoLabel setText:[info objectForKey:@"name"]];
    [cell.repoLabel setTextColor:[UIColor primaryTextColor]];
    
    NSString *subtitle = [info objectForKey:@"label"] ? [info objectForKey:@"label"] : [info objectForKey:@"url"];
    [cell.urlLabel setText:subtitle];
    [cell.urlLabel setTextColor:[UIColor secondaryTextColor]];
    
    NSURL *iconURL = [NSURL URLWithString:[info objectForKey:@"icon"]];
    [cell.iconImageView sd_setImageWithURL:iconURL placeholderImage:[UIImage imageNamed:@"Unknown"]];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([communitySources count]) {
        NSDictionary *info = [[communitySources objectAtIndex:section] objectAtIndex:0];
        NSString *type = [info objectForKey:@"type"];

        NSArray *options = @[@"transfer", @"utility", @"repo", @"none"];
        switch ([options indexOfObject:type]) {
            case 0:
                return NSLocalizedString(@"Transfer Sources", @"");
            case 1:
                return NSLocalizedString(@"Utilities", @"");
            case 2:
                return NSLocalizedString(@"Community Sources", @"");
            default:
                return nil;
        }
    }
    else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *info = [[communitySources objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSString *type = [info objectForKey:@"type"];
    
    NSArray *options = @[@"transfer", @"utility", @"repo"];
    switch ([options indexOfObject:type]) {
        case 0: {
            dispatch_async(dispatch_get_main_queue(), ^{
                ZBSourceImportTableViewController *importController = [[ZBSourceImportTableViewController alloc] initWithSourceFiles:@[[NSURL URLWithString:[info objectForKey:@"url"]]]];
                
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:importController];
                [self presentViewController:navController animated:YES completion:nil];
            });
            break;
        }
        case 1:
        case 2: {
            NSString *url = [info objectForKey:@"url"];
            ZBBaseSource *source = [[ZBBaseSource alloc] initFromURL:[NSURL URLWithString:url]];
            if (source) {
                [[ZBSourceManager sharedInstance] addBaseSources:[NSSet setWithObject:source]];
                ZBRefreshViewController *refresh = [[ZBRefreshViewController alloc] initWithDropTables:false baseSources:[NSSet setWithObject:source]];
                
                [self presentViewController:refresh animated:true completion:nil];
            }
            break;
        }
        default:
            break;
    }
}

- (void)presentConsole {
    ZBRefreshViewController *refreshController = [[ZBRefreshViewController alloc] init];
    [self presentViewController:refreshController animated:YES completion:nil];
}

@end
