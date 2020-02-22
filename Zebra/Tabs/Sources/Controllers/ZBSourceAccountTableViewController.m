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
#import "ZBRepoTableViewCell.h"
#import "ZBPackageDepictionViewController.h"
#import <UIColor+GlobalColors.h>
#import "ZBUserInfo.h"
#import <Tabs/Sources/Helpers/ZBSource.h>

#import <Packages/Helpers/ZBPackageActionsManager.h>

@import SDWebImage;

@interface ZBSourceAccountTableViewController () {
    ZBDatabaseManager *databaseManager;
    UICKeyChainStore *keychain;
    NSDictionary *accountInfo;
    NSArray <ZBPackage *> *purchases;
    NSString *userName;
    NSString *userEmail;
    BOOL loading;
}
@end

@implementation ZBSourceAccountTableViewController

@synthesize source;

- (id)initWithSource:(ZBSource *)source {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"purchasedController"];
    
    if (self) {
        self.source = source;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self->databaseManager = [ZBDatabaseManager sharedInstance];
    self->keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
    
    self.navigationItem.title = NSLocalizedString(@"Account", @"");
    
    if (self.presentingViewController) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleDone actionHandler:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRepoTableViewCell" bundle:nil] forCellReuseIdentifier:@"repoTableViewCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (purchases == NULL) {
        purchases = [NSMutableArray new];
        [self getPurchases];
    }
    
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
}

- (void)getPurchases {
    loading = YES;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[source paymentVendorURL] URLByAppendingPathComponent:@"user_info"]];
    
    NSDictionary *requestJSON = @{@"token": [keychain stringForKey:[source repositoryURI]], @"udid": [ZBDevice UDID], @"device": [ZBDevice deviceModelID]};
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestJSON options:(NSJSONWritingOptions)0 error:nil];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Zebra/%@ (%@; iOS/%@)", PACKAGE_VERSION, [ZBDevice deviceType], [[UIDevice currentDevice] systemVersion]] forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:requestData];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpReponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = [httpReponse statusCode];
        
        if (statusCode == 200 && !error) {
            NSError *parseError;
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%@", str);
            ZBUserInfo *userInfo = [ZBUserInfo fromData:data error:&parseError];
            
            if (parseError || userInfo.error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"An Error Occurred", @"") message:parseError ? parseError.localizedDescription : userInfo.error preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        if (self.presentingViewController) {
                            [self signOut:self];
                            [self dismissViewControllerAnimated:YES completion:nil];
                        }
                        else {
                            [self signOut:self];
                            [self.navigationController popViewControllerAnimated:YES];
                        }
                    }];
                    [errorAlert addAction:okAction];
                    
                    [self presentViewController:errorAlert animated:YES completion:nil];
                });
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
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->loading = NO;
                    
                    [self.tableView beginUpdates];
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                });
            }
        }
        else if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"An Error Occurred", @"") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    if (self.presentingViewController) {
                        [self signOut:self];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    else {
                        [self signOut:self];
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                }];
                [errorAlert addAction:okAction];
                
                [self presentViewController:errorAlert animated:YES completion:nil];
            });
        }
    }];
    
    [task resume];
}

- (void)signOut:(id)sender {
    [keychain removeItemForKey:[source repositoryURI]];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 || (indexPath.section == 0 && indexPath.row == 0)) {
        return 65;
    }
    else {
        return 44;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 3;
        case 1:
            return (![purchases count] || loading) ? 1 : [purchases count];
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) { // Account Cell
        switch (indexPath.row) {
            case 0: {
                ZBRepoTableViewCell *cell = (ZBRepoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
                
                cell.repoLabel.textColor = [UIColor primaryTextColor];
                cell.repoLabel.text = [source label];
                
                cell.urlLabel.text = [source sourceDescription];
                cell.urlLabel.textColor = [UIColor secondaryTextColor];
                
                [cell.iconImageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
                
                cell.accessoryType = UITableViewCellAccessoryNone;
                
                return cell;
            }
            case 1: {
                if (!loading) {
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountCell"];
                    
                    cell.textLabel.text = userName;
                    cell.detailTextLabel.text = userEmail;
                    
                    return cell;
                }
                else {
                    UITableViewCell *spinnerCell = [tableView dequeueReusableCellWithIdentifier:@"spinnerCell"];
                    
                    return spinnerCell;
                }
            }
            case 2: {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"buttonCell"];
                
                cell.textLabel.text = NSLocalizedString(@"Sign Out", @"");
                cell.textLabel.textColor = [UIColor accentColor];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                
                return cell;
            }
            default:
                return NULL;
        }
    }
    else {
        if (loading) {
            UITableViewCell *spinnerCell = [tableView dequeueReusableCellWithIdentifier:@"spinnerCell"];
            
            return spinnerCell;
        }
        else if (![purchases count]) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"buttonCell"];
            
            cell.textLabel.text = NSLocalizedString(@"No packages purchased", @"");
            
            return cell;
        }
        else {
            ZBPackageTableViewCell *cell = (ZBPackageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
            [cell setColors];
            
            ZBPackage *package = [purchases objectAtIndex:indexPath.row];
            [(ZBPackageTableViewCell *)cell updateData:package];
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            
            return cell;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 2) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        [keychain removeItemForKey:[source repositoryURI]];
        
        if (self.presentingViewController) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else if (indexPath.section == 1 && [purchases count] && !loading) {
        [self performSegueWithIdentifier:@"seguePurchasesToPackageDepiction" sender:indexPath];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 1 ? NSLocalizedString(@"Your Purchases", @"") : NULL;
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
    [self.navigationController.navigationBar setTintColor:[UIColor accentColor]];
}

@end
