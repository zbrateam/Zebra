//
//  ZBRepoListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/3/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBRepoListTableViewController.h"
#import <Repos/Controllers/ZBRepoSectionsListTableViewController.h>
#import <Database/ZBDatabaseManager.h>
#import <Repos/Helpers/ZBRepoManager.h>
#import <Repos/Helpers/ZBRepo.h>
#import <ZBTabBarController.h>
#import <Database/ZBRefreshViewController.h>
#import <ZBAppDelegate.h>
#import <ZBTabBarController.h>
#import <UIColor+GlobalColors.h>

@interface ZBRepoListTableViewController () {
    NSArray *sources;
    NSMutableArray *bfns;
    ZBDatabaseManager *databaseManager;
    NSMutableArray *errorMessages;
}
@end

@implementation ZBRepoListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    databaseManager = [[ZBDatabaseManager alloc] init];
    sources = [databaseManager sources];
    
    bfns = [NSMutableArray new];
    for (ZBRepo *source in sources) {
        [bfns addObject:[source baseFileName]];
    }
    self.navigationController.navigationBar.tintColor = [UIColor tintColor];
    self.editButtonItem.action = @selector(editMode:);
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    //set up refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshSources:) forControlEvents:UIControlEventValueChanged];
    self.extendedLayoutIncludesOpaqueBars = true;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(delewhoop:) name:@"deleteRepoTouchAction" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self refreshTable];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refreshTable];
}

- (void)setSpinnerVisible:(BOOL)visible forRepo:(NSString *)bfn {
    NSInteger row = [bfns indexOfObject:bfn];
    dispatch_async(dispatch_get_main_queue(), ^{
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        
        if (visible) {
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:12];
            [spinner setColor:[UIColor grayColor]];
            spinner.frame = CGRectMake(0, 0, 24, 24);
            cell.accessoryView = spinner;
            [spinner startAnimating];
        }
        else {
            cell.accessoryView = nil;
        }
    });
}

- (void)clearAllSpinners {
    NSLog(@"Clearning all Spinners");
    ((ZBTabBarController *)self.tabBarController).repoBusyList = [NSMutableDictionary new];
    dispatch_async(dispatch_get_main_queue(), ^{
        for (int i = 0; i < [self.tableView numberOfRowsInSection:0]; i++) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            
            cell.accessoryView = nil;
        }
    });
}

- (void)editMode:(id)sender {
    if (self.editing) {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        self.navigationItem.leftBarButtonItem = nil;
        
        [self setEditing:false animated:true];
    }
    else {
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSource:)];
        self.navigationItem.leftBarButtonItem = addButton;
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editMode:)];
        self.navigationItem.rightBarButtonItem = doneButton;
        
        [self setEditing:true animated:true];
    }
}

- (void)refreshSources:(id)sender {
    [databaseManager setDatabaseDelegate:self];
    
    [self setRepoRefreshIndicatorVisible:true];
    [databaseManager updateDatabaseUsingCaching:true requested:true];
}

- (void)refreshTable {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:false];
    }
    else {
        ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
        sources = [databaseManager sources];
        
        bfns = [NSMutableArray new];
        for (ZBRepo *source in sources) {
            [bfns addObject:[source baseFileName]];
        }
        
        [self.tableView reloadData];
    }
}

- (void)addSource:(id)sender {
    [self showAddRepoAlert:NULL];
}

- (void)showAddRepoAlert:(NSURL *)url {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter URL" message:nil preferredStyle:UIAlertControllerStyleAlert];
    alertController.view.tintColor = [UIColor tintColor];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:true completion:nil];
        
        ZBRepoManager *repoManager = [[ZBRepoManager alloc] init];
        NSString *sourceURL = alertController.textFields[0].text;
        
        UIAlertController *wait = [UIAlertController alertControllerWithTitle:@"Please Wait..." message:@"Verifying Source" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:wait animated:true completion:nil];
        
        [repoManager addSourceWithURL:sourceURL response:^(BOOL success, NSString *error, NSURL *url) {
            if (!success) {
                NSLog(@"[Zebra] Could not add source %@ due to error %@", url.absoluteString, error);
                
                [wait dismissViewControllerAnimated:true completion:^{
                    [self presentVerificationFailedAlert:error url:url];
                }];
            }
            else {
                [wait dismissViewControllerAnimated:true completion:^{
                    NSLog(@"[Zebra] Added source.");
                    NSLog(@"[Zebra] New Repo File: %@", [NSString stringWithContentsOfFile:@"/var/lib/zebra/sources.list" encoding:NSUTF8StringEncoding error:nil]);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                        UIViewController *console = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
                        [self presentViewController:console animated:true completion:nil];
                    });
                }];
            }
        }];
    }]];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        if (url != NULL) {
            textField.text = [url absoluteString];
        }
        else {
            textField.text = @"https://";
        }
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.keyboardType = UIKeyboardTypeURL;
        textField.returnKeyType = UIReturnKeyNext;
    }];
    
    [self presentViewController:alertController animated:true completion:nil];
}

- (void)presentVerificationFailedAlert:(NSString *)message url:(NSURL *)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Unable to verify Repo" message:message preferredStyle:UIAlertControllerStyleAlert];
        alertController.view.tintColor = [UIColor tintColor];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alertController dismissViewControllerAnimated:true completion:nil];
            [self showAddRepoAlert:url];
        }];
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:true completion:nil];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return sources.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
    
    ZBRepo *source = [sources objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [source origin];
    
    NSDictionary *busyList = ((ZBTabBarController *)self.tabBarController).repoBusyList;
    NSString *bfn = bfns[indexPath.row];
    if ([busyList[bfn] boolValue]) {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:12];
        spinner.frame = CGRectMake(0, 0, 24, 24);
        [spinner setColor:[UIColor grayColor]];
        cell.accessoryView = spinner;
        [spinner startAnimating];
    }
    else {
        cell.accessoryView = nil;
    }
    
    if ([source isSecure]) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"https://%@", [source shortURL]];
    }
    else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"http://%@", [source shortURL]];
    }
    
    ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
    UIImage *icon = [databaseManager iconForRepo:source];
    
    if (icon != NULL) {
        cell.imageView.image = icon;
        CGSize itemSize = CGSizeMake(35, 35);
        UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
        CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
        [cell.imageView.image drawInRect:imageRect];
        cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    else { //Download the image
        NSLog(@"[Zebra] Downloading image for repoID %d", [source repoID]);
        
        NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[source iconURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (data) {
                UIImage *image = [UIImage imageWithData:data];
                UITableViewCell *updateCell = [tableView cellForRowAtIndexPath:indexPath];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (updateCell) {
                            updateCell.imageView.image = image;
                            CGSize itemSize = CGSizeMake(35, 35);
                            UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
                            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                            [cell.imageView.image drawInRect:imageRect];
                            cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
                            UIGraphicsEndImageContext();
                            [updateCell setNeedsDisplay];
                            [updateCell setNeedsLayout];
                        }
                    });
                    [databaseManager saveIcon:image forRepo:source];
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (updateCell) {
                            updateCell.imageView.image = [UIImage imageNamed:@"Unknown"];
                            CGSize itemSize = CGSizeMake(35, 35);
                            UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
                            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                            [cell.imageView.image drawInRect:imageRect];
                            cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
                            UIGraphicsEndImageContext();
                            [updateCell setNeedsDisplay];
                            [updateCell setNeedsLayout];
                        }
                    });
                }
            }
            if (error) {
                NSLog(@"[Zebra] Error while getting icon URL: %@", error);
            }
        }];
        [task resume];
    }
    
    return cell;
}

 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
     return !([[[sources objectAtIndex:indexPath.row] origin] isEqualToString:@"xTM3x Repo"]);
 }

 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        ZBRepo *delRepo = [sources objectAtIndex:indexPath.row];
        NSMutableArray *mutableSources = [sources mutableCopy];
        [mutableSources removeObjectAtIndex:indexPath.row];
        sources = (NSArray *)mutableSources;
        
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
        
        ZBRepoManager *repoManager = [[ZBRepoManager alloc] init];
        [repoManager deleteSource:delRepo];
    }
 }

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ZBRepoSectionsListTableViewController *destination = (ZBRepoSectionsListTableViewController *)[segue destinationViewController];
    UITableViewCell *cell = (UITableViewCell *)sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    destination.repo = [sources objectAtIndex:indexPath.row];
}

- (void)delewhoop:(NSNotification *)notification {
    ZBRepo *repo = (ZBRepo *)[[notification userInfo] objectForKey:@"repo"];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[sources indexOfObject:repo] inSection:0];
    [self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
}

- (void)setRepoRefreshIndicatorVisible:(BOOL)visible {
    [(ZBTabBarController *)self.tabBarController setRepoRefreshIndicatorVisible:visible];
}

#pragma mark - Database Delegate

- (void)setRepo:(NSString *)bfn busy:(BOOL)busy {
    [self setSpinnerVisible:busy forRepo:bfn];
}

- (void)databaseStartedUpdate {
    [self setRepoRefreshIndicatorVisible:true];
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    [(ZBTabBarController *)self.tabBarController setPackageUpdateBadgeValue:packageUpdates];
    [self setRepoRefreshIndicatorVisible:false];
    [self clearAllSpinners];
    [self refreshTable];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
        if (self->errorMessages) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ZBRefreshViewController *refreshController = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
            refreshController.messages = self->errorMessages;
            
            self->errorMessages = [NSMutableArray new];
            
            [self presentViewController:refreshController animated:true completion:nil];
        }
    });
}

- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level {
    if (level == ZBLogLevelError) {
        if (!errorMessages) errorMessages = [NSMutableArray new];
        [errorMessages addObject:status];
    }
}

@end
