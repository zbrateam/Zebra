//
//  ZBSourceAccountTableViewController.m
//  Zebra
//
//  Created by midnightchips on 5/11/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <ZBDevice.h>
#import <ZBAppDelegate.h>
#import "ZBSourceAccountTableViewController.h"
#import "UIBarButtonItem+blocks.h"
#import "ZBPackageTableViewCell.h"
#import "ZBPackageDepictionViewController.h"
#import <UIColor+GlobalColors.h>
#import "ZBUserInfo.h"
#import <Tabs/Sources/Helpers/ZBSource.h>

#import <Packages/Helpers/ZBPackageActionsManager.h>

@interface ZBSourceAccountTableViewController () {
    ZBDatabaseManager *databaseManager;
    UICKeyChainStore *keychain;
    NSDictionary *accountInfo;
    NSArray <ZBPackage *> *purchases;
    NSString *userName;
    NSString *userEmail;
}
@end

@implementation ZBSourceAccountTableViewController

@synthesize source;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self->databaseManager = [ZBDatabaseManager sharedInstance];
    self->keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.titleView = spinner;
    
    switch ([ZBSettings interfaceStyle]) {
        case ZBInterfaceStyleLight:
            break;
        case ZBInterfaceStyleDark:
        case ZBInterfaceStylePureBlack:
            spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
            break;
    }
    
    [spinner startAnimating];
    
    UIBarButtonItem *signOutButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Sign Out", @"") style:UIBarButtonItemStylePlain target:self action:@selector(signOut:)];
    self.navigationItem.rightBarButtonItem = signOutButton;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (purchases == NULL) {
        purchases = [NSMutableArray new];
        [self getPurchases];
    }
    
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
}

- (void)getPurchases {
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[source paymentVendorURL] URLByAppendingPathComponent:@"user_info"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:[keychain stringForKey:[source repositoryURI]] forHTTPHeaderField:@"token"];
    [request setValue:[NSString stringWithFormat:@"Zebra/%@ (%@; iOS/%@)", PACKAGE_VERSION, [ZBDevice deviceType], [[UIDevice currentDevice] systemVersion]] forHTTPHeaderField:@"User-Agent"];
    
    NSLog(@"URL: %@", request.URL);
    NSLog(@"Token: %@", [keychain stringForKey:[source repositoryURI]]);
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpReponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = [httpReponse statusCode];
        
        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Data: %@", result);
        
        if (statusCode == 200 && !error) {
            NSError *parseError;
            ZBUserInfo *userInfo = [ZBUserInfo fromData:data error:&parseError];
            
            if (parseError) {
                NSLog(@"[Zebra] Error: %@", error.localizedDescription);
            }
            else {
                NSMutableArray *purchasedPackageIdentifiers = [NSMutableArray new];
                for (NSString *packageIdentifier in userInfo.items) {
                    [purchasedPackageIdentifiers addObject:[packageIdentifier lowercaseString]];
                }
                
                self->purchases = [self->databaseManager packagesFromIdentifiers:purchasedPackageIdentifiers];
                if (userInfo.user.name) {
                    self->userName = userInfo.user.name;
                }
                if (userInfo.user.email) {
                    self->userEmail = userInfo.user.email;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        else if (error) {
            NSLog(@"[Zebra] Error: %@", error.localizedDescription);
        }
    }];
    
    [task resume];
}

- (void)signOut:(id)sender {
    [keychain removeItemForKey:[source repositoryURI]];
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 0;
    } else {
        return 25;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 10;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    view.tintColor = [UIColor clearColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        return 65;
    } else {
        return 44;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return [purchases count];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) { // Account Cell
        cell.textLabel.text = userName;
        cell.detailTextLabel.text = userEmail;
    } else { // Package Cell
        ZBPackage *package = [purchases objectAtIndex:indexPath.row];
        [(ZBPackageTableViewCell *)cell updateData:package];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountCell"];
        return cell;
    } else {
        ZBPackageTableViewCell *cell = (ZBPackageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
        [cell setColors];
        return cell;
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        [self performSegueWithIdentifier:@"seguePurchasesToPackageDepiction" sender:indexPath];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"alphabeticalReuse"];
    view.textLabel.font = [UIFont boldSystemFontOfSize:15];
    view.textLabel.textColor = [UIColor primaryTextColor];
    view.contentView.backgroundColor = [UIColor tableViewBackgroundColor];
        
    return view;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Purchased Packages", @"");
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1 && ![[ZBAppDelegate tabBarController] isQueueBarAnimating];;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView setEditing:NO animated:YES];
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return nil;
    }
    ZBPackage *package = purchases[indexPath.row];
    return [ZBPackageActionsManager rowActionsForPackage:package indexPath:indexPath viewController:self parent:nil completion:^(void) {
        [tableView reloadData];
    }];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"seguePurchasesToPackageDepiction"]) {
        ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
        NSIndexPath *indexPath = sender;
        destination.package = [purchases objectAtIndex:indexPath.row];
        destination.view.backgroundColor = [UIColor tableViewBackgroundColor];
    }
}

- (void)darkMode:(NSNotification *)notif {
    [self.tableView reloadData];
    self.tableView.sectionIndexColor = [UIColor accentColor];
    [self.navigationController.navigationBar setTintColor:[UIColor accentColor]];
}

@end
