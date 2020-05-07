//
//  ZBSourceAccountTableViewController.m
//  Zebra
//
//  Created by midnightchips on 5/11/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "UICKeyChainStore.h"
#import "UIBarButtonItem+blocks.h"
#import "ZBPackageTableViewCell.h"
#import "ZBSourceTableViewCell.h"
#import "ZBSourceAccountTableViewController.h"
#import "ZBPackageDepictionViewController.h"
#import "ZBUserInfo.h"

#import <ZBDevice.h>
#import <ZBAppDelegate.h>
#import <UIColor+GlobalColors.h>
#import <Tabs/Sources/Helpers/ZBSource.h>
#import <Database/ZBDatabaseManager.h>
#import <Packages/Helpers/ZBPackageActions.h>

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
@property (nonatomic, weak) ZBPackageDepictionViewController *previewPackageDepictionVC;
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
    
    self.navigationItem.title = NSLocalizedString(@"My Account", @"");
    
    if (self.presentingViewController) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleDone actionHandler:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBSourceTableViewCell" bundle:nil] forCellReuseIdentifier:@"sourceTableViewCell"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBDatabaseCompletedUpdate" object:nil];
    
    if (@available(iOS 13.0, *)) {
    } else {
        if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)) {
            [self registerForPreviewingWithDelegate:self sourceView:self.view];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (purchases == NULL) {
        purchases = [NSMutableArray new];
        [self getPurchases];
    }
        
    [self.tableView reloadData];
}

- (void)getPurchases {
    loading = YES;
    
    if (@available(iOS 11.0, *)) {
        [source getUserInfo:^(ZBUserInfo * _Nonnull info, NSError * _Nonnull error) {
            if (error) {
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
            else if (info) {
                NSMutableArray *purchasedPackageIdentifiers = [NSMutableArray new];
                for (NSString *packageIdentifier in info.items) {
                    [purchasedPackageIdentifiers addObject:[packageIdentifier lowercaseString]];
                }
                
                self->purchases = [self->databaseManager packagesFromIdentifiers:purchasedPackageIdentifiers];
                if (info.user.name) {
                    self->userName = info.user.name;
                }
                if (info.user.email) {
                    self->userEmail = info.user.email;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->loading = NO;
                    
                    [self.tableView beginUpdates];
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                });
            }
        }];
    } else {
        self->loading = NO;
        self->userName = NSLocalizedString(@"Unknown", @"");
        self->userEmail = NSLocalizedString(@"Unknown", @"");
        
        [self.tableView reloadData];
    }
}

- (void)signOut:(id)sender {
    [keychain removeItemForKey:[source repositoryURI]];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (void)refreshTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 3;
        case 1:
            return (!purchases.count || loading) ? 1 : purchases.count;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) { // Account Cell
        switch (indexPath.row) {
            case 0: {
                ZBSourceTableViewCell *cell = (ZBSourceTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"sourceTableViewCell" forIndexPath:indexPath];
                
                cell.sourceLabel.textColor = [UIColor primaryTextColor];
                cell.sourceLabel.text = [source label];
                
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
                cell.textLabel.textColor = [UIColor accentColor] ?: [UIColor systemBlueColor];
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
            
            ZBPackage *package = purchases[indexPath.row];
            [(ZBPackageTableViewCell *)cell updateData:package];
            
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            
            return cell;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 2) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        [keychain removeItemForKey:[source repositoryURI]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBSourcesAccountBannerNeedsUpdate" object:nil];

        if (self.presentingViewController) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else if (indexPath.section == 1 && purchases.count && !loading) {
        [self performSegueWithIdentifier:@"seguePurchasesToPackageDepiction" sender:indexPath];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 1 ? NSLocalizedString(@"Your Purchases", @"") : NULL;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1 && purchases.count && ![[ZBAppDelegate tabBarController] isQueueBarAnimating];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView setEditing:NO animated:YES];
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 || !purchases.count) {
        return nil;
    }
    ZBPackage *package = purchases[indexPath.row];
    return [ZBPackageActions rowActionsForPackage:package inTableView:tableView];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"seguePurchasesToPackageDepiction"]) {
        ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
        NSIndexPath *indexPath = sender;
        destination.package = [purchases objectAtIndex:indexPath.row];
        destination.view.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0)){
    if (indexPath.section == 0 || !purchases.count) {
        return nil;
    }
    typeof(self) __weak weakSelf = self;
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController * _Nullable{
        return weakSelf.previewPackageDepictionVC;
    } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        weakSelf.previewPackageDepictionVC = (ZBPackageDepictionViewController*)[weakSelf.storyboard instantiateViewControllerWithIdentifier:@"packageDepictionVC"];
        weakSelf.previewPackageDepictionVC.package = self->purchases[indexPath.row];
//        [weakSelf setDestinationVC:indexPath destination:weakSelf.previewPackageListVC];
        return [UIMenu menuWithTitle:@"" children:[weakSelf.previewPackageDepictionVC contextMenuActionItemsInTableView:tableView]];
    }];
}

- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator API_AVAILABLE(ios(13.0)){
    typeof(self) __weak weakSelf = self;
    [animator addCompletion:^{
        [weakSelf.navigationController pushViewController:weakSelf.previewPackageDepictionVC animated:YES];
    }];
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

    if (indexPath.section == 0 || !purchases.count) {
        return nil;
    }

    ZBPackageTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    previewingContext.sourceRect = cell.frame;
    ZBPackageDepictionViewController *packageDepictionVC = (ZBPackageDepictionViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"packageDepictionVC"];
    packageDepictionVC.package = purchases[indexPath.row];
//    [self setDestinationVC:indexPath destination:packageDepictionVC];
    return packageDepictionVC;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}


@end
