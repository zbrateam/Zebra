//
//  ZBStoresListTableViewController.m
//  Zebra
//
//  Created by va2ron1 on 6/2/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <UIColor+GlobalColors.h>
#import "ZBStoresListTableViewController.h"
#import <Sources/Helpers/ZBSource.h>
#import <Sources/Views/ZBRepoTableViewCell.h>
#import <Database/ZBDatabaseManager.h>
#import <Sources/Helpers/ZBSourceManager.h>
#import <Sources/Controllers/ZBSourceAccountTableViewController.h>

@import SDWebImage;

@interface ZBStoresListTableViewController () {
    NSArray <ZBSource *> *sources;
    UICKeyChainStore *keychain;
    NSString *callbackURI;
}
@end

@implementation ZBStoresListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"label" ascending:YES];
    sources = [[[ZBDatabaseManager sharedInstance] sourcesWithPaymentEndpoint] sortedArrayUsingDescriptors:@[descriptor]];
    
    self.title = NSLocalizedString(@"Stores", @"");
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRepoTableViewCell" bundle:nil] forCellReuseIdentifier:@"repoTableViewCell"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationCallBack:) name:@"AuthenticationCallBack" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return sources.count ? 65 : 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX(sources.count, 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (sources.count) {
           ZBRepoTableViewCell *cell = (ZBRepoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
           
           ZBSource *source = [sources objectAtIndex:indexPath.row];
           
           cell.repoLabel.text = [source label];
           cell.repoLabel.textColor = [UIColor primaryTextColor];
           
           cell.urlLabel.text = [source repositoryURI];
           cell.urlLabel.textColor = [UIColor secondaryTextColor];
           
           [cell.iconImageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
        
           return cell;
    }
    else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noStoresCell"];
        cell.textLabel.text = NSLocalizedString(@"No Storefronts Available", @"");
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor secondaryTextColor];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ZBSource *source = [sources objectAtIndex:indexPath.row];
    
    [source authenticate:^(BOOL success, NSError * _Nullable error) {
        if (!success || error) {
            if (error) {
                [ZBAppDelegate sendAlertFrom:self message:[NSString stringWithFormat:@"Could not authenticate: %@", error.localizedDescription]];
            }
            else {
                [ZBAppDelegate sendAlertFrom:self message:@"Could not authenticate"];
            }
        }
        else {
            ZBSourceAccountTableViewController *accountController = [[ZBSourceAccountTableViewController alloc] initWithSource:source];
            
            [self.navigationController pushViewController:accountController animated:YES];
        }
    }];
}

- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully {}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [self.tableView reloadData];
}

- (void)authenticationCallBack:(NSNotification *)notif {
    [self dismissViewControllerAnimated:YES completion:nil];

    NSURL *callbackURL = [notif.userInfo objectForKey:@"callBack"];
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:callbackURL resolvingAgainstBaseURL:NO];
    NSArray *queryItems = urlComponents.queryItems;
    NSMutableDictionary *queryByKeys = [NSMutableDictionary new];
    
    for (NSURLQueryItem *q in queryItems) {
        [queryByKeys setValue:[q value] forKey:[q name]];
    }
    
    NSString *token = queryByKeys[@"token"];
    NSString *payment = queryByKeys[@"payment_secret"];
    
    [keychain setString:token forKey:callbackURI];
    UICKeyChainStore *securedKeychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    securedKeychain[[callbackURI stringByAppendingString:@"payment"]] = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [securedKeychain setAccessibility:UICKeyChainStoreAccessibilityWhenPasscodeSetThisDeviceOnly
                     authenticationPolicy:UICKeyChainStoreAuthenticationPolicyUserPresence];
        securedKeychain[[self->callbackURI stringByAppendingString:@"payment"]] = payment;
    });
    
    [self.tableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return sources.count ? NSLocalizedString(@"Signing in to sources allows for the purchase of paid packages.", @"") : NULL;
}

@end
