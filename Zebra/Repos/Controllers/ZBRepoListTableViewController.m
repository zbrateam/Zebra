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
#import <Repos/Helpers/ZBRepoTableViewCell.h>
#import <ZBTabBarController.h>
#import <Database/ZBRefreshViewController.h>
#import <ZBAppDelegate.h>
#import <ZBTabBarController.h>
#import <UIColor+GlobalColors.h>
#import "ZBAddRepoViewController.h"
#import "ZBAddRepoDelegate.h"
#import <Packages/Helpers/ZBPackage.h>
//#import "UIImageView+Async.h"
//#import "UIImageView+Network.h"
@import SDWebImage;

@interface ZBRepoListTableViewController () <ZBAddRepoDelegate> {
    NSMutableArray *sources;
    NSMutableDictionary <NSString *, NSNumber *> *sourceIndexes;
    NSMutableArray *sectionIndexTitles;
    ZBDatabaseManager *databaseManager;
    NSMutableArray *errorMessages;
    BOOL askedToAddFromClipboard;
    NSString *lastPaste;
}

@property (nonatomic, retain) ZBRepoManager *repoManager;

@end

@implementation ZBRepoListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.defaults = [NSUserDefaults standardUserDefaults];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"lightMode" object:nil];
    databaseManager = [ZBDatabaseManager sharedInstance];
    sources = [[databaseManager repos] mutableCopy];
    sourceIndexes = [NSMutableDictionary new];
    self.repoManager = [[ZBRepoManager alloc] init];
    
    self.navigationController.navigationBar.tintColor = [UIColor tintColor];
    [self layoutNavigationButtons];
    
    //set up refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshSources:) forControlEvents:UIControlEventValueChanged];
    self.extendedLayoutIncludesOpaqueBars = true;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(delewhoop:) name:@"deleteRepoTouchAction" object:nil];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    
    self.tableView.contentInset = UIEdgeInsetsMake(5.0, 0.0, CGRectGetHeight(self.tabBarController.tabBar.frame), 0.0);
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkClipboard) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseCompletedUpdate) name:@"ZBDatabaseCompletedUpdate" object:nil];
    [self refreshTable];
}

- (void)databaseCompletedUpdate {
    [self refreshTable];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBDatabaseCompletedUpdate" object:nil];
}

- (void)layoutNavigationButtons {
    if (self.editing) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editMode:)];
        self.navigationItem.rightBarButtonItem = doneButton;
        
        UIBarButtonItem *exportButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(exportSources)];
        self.navigationItem.leftBarButtonItem = exportButton;
    }
    else {
        self.editButtonItem.action = @selector(editMode:);
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSource:)];
        self.navigationItem.leftBarButtonItems = @[addButton];
    }
}

- (void)checkClipboard {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSURL *url = [NSURL URLWithString:pasteboard.string];
    
    if ((url && url.scheme && url.host)) {
        if ([[url scheme] isEqual:@"https"] || [[url scheme] isEqual:@"http"]) {
            if (!askedToAddFromClipboard || ![lastPaste isEqualToString: pasteboard.string]) {
                [self showAddRepoFromClipboardAlert:url];
            }
            askedToAddFromClipboard = YES;
            lastPaste = pasteboard.string;
        }
    }
}

- (void)exportSources {
    NSURL *sourcesList = [ZBAppDelegate sourcesListURL];
    
    UIActivityViewController *shareSheet = [[UIActivityViewController alloc] initWithActivityItems:@[sourcesList] applicationActivities:nil];
    
    shareSheet.popoverPresentationController.barButtonItem = self.navigationItem.leftBarButtonItems[0];
    
    [self presentViewController:shareSheet animated:true completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self checkClipboard];
}

- (NSIndexPath *)indexPathForPosition:(NSInteger)pos {
    NSInteger section = pos >> 16;
    NSInteger row = pos & 0xFF;
    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (void)setSpinnerVisible:(BOOL)visible forCell:(ZBRepoTableViewCell *)cell {
    if (visible) {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:12];
        [spinner setColor:[UIColor grayColor]];
        spinner.frame = CGRectMake(0, 7, 0, 0);
        [cell clearAccessoryView];
        [cell hideChevron];
        [cell.accessoryZBView addSubview:spinner];
        [spinner startAnimating];
    }
    else {
        [cell clearAccessoryView];
    }
}

- (void)setSpinnerVisible:(BOOL)visible forRepo:(NSString *)bfn {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger pos = [self->sourceIndexes[bfn] integerValue];
        ZBRepoTableViewCell *cell = (ZBRepoTableViewCell *)[self.tableView cellForRowAtIndexPath:[self indexPathForPosition:pos]];
        [self setSpinnerVisible:visible forCell:cell];
    });
}

- (void)clearAllSpinners {
    ((ZBTabBarController *)self.tabBarController).repoBusyList = [NSMutableDictionary new];
    for (NSString *bfn in sourceIndexes) {
        NSInteger pos = [sourceIndexes[bfn] integerValue];
        ZBRepoTableViewCell *cell = (ZBRepoTableViewCell *)[self.tableView cellForRowAtIndexPath:[self indexPathForPosition:pos]];
        [self setSpinnerVisible:NO forCell:cell];
    }
}

- (void)editMode:(id)sender {
    [self setEditing:!self.editing animated:true];
    [self layoutNavigationButtons];
}

- (void)refreshSources:(id)sender {
    [databaseManager setDatabaseDelegate:self];
    [self setRepoRefreshIndicatorVisible:true];
    [databaseManager updateDatabaseUsingCaching:true userRequested:true];
}

- (void)refreshTable {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:false];
    }
    else {
        ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
        sources = [[databaseManager repos] mutableCopy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateCollation];
            [self.tableView reloadData];
        });
    }
}

- (void)updateCollation {
    self.tableData = [self partitionObjects:sources collationStringSelector:@selector(origin)];
}

- (void)handleURL:(NSURL *)url {
    NSString *path = [url path];
    
    if (![path isEqualToString:@""]) {
        NSArray *components = [path pathComponents];
        if ([components count] == 2) {
            [self showAddRepoAlert:NULL];
        }
        else if ([components count] >= 4) {
            NSString *urlString = [path componentsSeparatedByString:@"/add/"][1];
            
            NSURL *url;
            if ([urlString containsString:@"https://"] || [urlString containsString:@"http://"]) {
                url = [NSURL URLWithString:urlString];
            }
            else {
                url = [NSURL URLWithString:[@"https://" stringByAppendingString:urlString]];
            }
            
            if (url && url.scheme && url.host) {
                [self showAddRepoAlert:url];
            }
            else {
                [self showAddRepoAlert:NULL];
            }
        }
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
        NSString *sourceURL = alertController.textFields[0].text;
        
        [self addReposWithText:sourceURL];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Add Multiple" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSegueWithIdentifier:@"showAddSources" sender:self];
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

- (void)showAddRepoFromClipboardAlert:(NSURL *)url {
//    NSString *message = [NSString stringWithFormat:@"Would you like to add %@?", url.absoluteString];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Would you like to add the URL from your clipboard?" message:url.absoluteString preferredStyle:UIAlertControllerStyleAlert];
    alertController.view.tintColor = [UIColor tintColor];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        ZBRepoManager *repoManager = [[ZBRepoManager alloc] init];
        NSString *sourceURL = url.absoluteString;
        
        UIAlertController *wait = [UIAlertController alertControllerWithTitle:@"Please Wait..." message:@"Verifying Source" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:wait animated:true completion:nil];
        
        [repoManager addSourceWithString:sourceURL response:^(BOOL success, NSString *error, NSURL *url) {
            if (!success) {
                NSLog(@"[Zebra] Could not add source %@ due to error %@", url.absoluteString, error);
                [wait dismissViewControllerAnimated:true completion:^{
                    [self presentVerificationFailedAlert:error url:url present:NO];
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
    
    [self presentViewController:alertController animated:true completion:nil];
}

- (void)presentVerificationFailedAlert:(NSString *)message url:(NSURL *)url present:(BOOL)present {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Unable to verify Repo" message:message preferredStyle:UIAlertControllerStyleAlert];
        alertController.view.tintColor = [UIColor tintColor];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (present) {
                [self showAddRepoAlert:url];
            }
        }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:true completion:nil];
    });
}

- (void)addReposWithText:(NSString *)text {
    UIAlertController *wait = [UIAlertController alertControllerWithTitle:@"Please Wait..." message:@"Verifying Source(s)" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:wait animated:true completion:nil];
    
    __weak typeof(self) weakSelf = self;
    
    [self.repoManager addSourcesFromString:text response:^(BOOL success, NSString * _Nonnull error, NSArray<NSURL *> * _Nonnull failedURLs) {
        [weakSelf dismissViewControllerAnimated:YES completion:^{
            if (!success) {
                UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:error preferredStyle:UIAlertControllerStyleAlert];
                
                if (failedURLs.count) {
                    UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [weakSelf addReposWithText:text];
                    }];
                    
                    [errorAlert addAction:retryAction];
                    
                    UIAlertAction *editAction = [UIAlertAction actionWithTitle:@"Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        if ([failedURLs count] > 1) {
                            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                            ZBAddRepoViewController *addRepo = [storyboard instantiateViewControllerWithIdentifier:@"addSourcesController"];
                            addRepo.delegate = weakSelf;
                            addRepo.text = text;
                            
                            UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:addRepo];
                            
                            [weakSelf presentViewController:navCon animated:true completion:nil];
                        }
                        else {
                            NSURL *failedURL = [failedURLs[0] URLByDeletingLastPathComponent];
                            [weakSelf showAddRepoAlert:failedURL];
                        }
                    }];
                    
                    [errorAlert addAction:editAction];
                }
                
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                
                [errorAlert addAction:cancelAction];
                
                [weakSelf presentViewController:errorAlert animated:true completion:nil];
            }
            else {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                UIViewController *console = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
                [weakSelf presentViewController:console animated:true completion:nil];
            }
        }];
    }];
}

- (ZBRepo *)sourceAtIndexPath:(NSIndexPath *)indexPath {
    if (![self hasDataInSection:indexPath.section])
        return nil;
    return self.tableData[indexPath.section][indexPath.row];
}

#pragma mark - Table view data source

- (NSArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector {
    [sourceIndexes removeAllObjects];
    sectionIndexTitles = [NSMutableArray arrayWithArray:[[UILocalizedIndexedCollation currentCollation] sectionIndexTitles]];
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    NSInteger sectionCount = [[collation sectionTitles] count];
    NSMutableArray *unsortedSections = [NSMutableArray arrayWithCapacity:sectionCount];
    for (int i = 0; i < sectionCount; ++i) {
        [unsortedSections addObject:[NSMutableArray array]];
    }
    for (ZBRepo *object in array) {
        NSUInteger index = [collation sectionForObject:object collationStringSelector:selector];
        NSMutableArray *section = [unsortedSections objectAtIndex:index];
        [section addObject:object];
        sourceIndexes[[object baseFileName]] = @((index << 16) | (section.count - 1));
    }
    NSUInteger lastIndex = 0;
    NSMutableIndexSet *sectionsToRemove = [NSMutableIndexSet indexSet];
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];
    for (NSMutableArray *section in unsortedSections) {
        if ([section count] == 0) {
            NSRange range = NSMakeRange(lastIndex, [unsortedSections count] - lastIndex);
            [sectionsToRemove addIndex:[unsortedSections indexOfObject:section inRange:range]];
            lastIndex = [sectionsToRemove lastIndex] + 1;
        }
        else {
            NSArray *data = [collation sortedArrayFromArray:section collationStringSelector:selector];
            [sections addObject:data];
        }
    }
    [sectionIndexTitles removeObjectsAtIndexes:sectionsToRemove];
    return sections;
}

- (NSInteger)hasDataInSection:(NSInteger)section {
    if ([self.tableData count] == 0)
        return 0;
    return [[self.tableData objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sectionIndexTitles count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self hasDataInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBRepoTableViewCell *cell = (ZBRepoTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
    
    ZBRepo *source = [self sourceAtIndexPath:indexPath];
    
    cell.repoLabel.text = [source origin];
    
    NSDictionary *busyList = ((ZBTabBarController *)self.tabBarController).repoBusyList;
    [self setSpinnerVisible:[busyList[[source baseFileName]] boolValue] forCell:cell];
    
    if ([source isSecure]) {
        cell.urlLabel.text = [NSString stringWithFormat:@"https://%@", [source shortURL]];
    }
    else {
        cell.urlLabel.text = [NSString stringWithFormat:@"http://%@", [source shortURL]];
    }
    [cell.iconImageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    
    
//    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
//    UIImage *icon = [databaseManager iconForRepo:source];
    
//    if (icon != NULL) {
//        cell.iconImageView.image = icon;
//        CGSize itemSize = CGSizeMake(35, 35);
//        UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
//        CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
//        [cell.iconImageView.image drawInRect:imageRect];
//        cell.iconImageView.image = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//    }
//    else { //Download the image
//        NSLog(@"[Zebra] Downloading image for repoID %d", [source repoID]);
//
//        NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[source iconURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//            if (data) {
//                UIImage *image = [UIImage imageWithData:data];
//                ZBRepoTableViewCell *updateCell = (ZBRepoTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
//                if (image) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        if (updateCell) {
//                            updateCell.iconImageView.image = image;
//                            CGSize itemSize = CGSizeMake(35, 35);
//                            UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
//                            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
//                            [cell.iconImageView.image drawInRect:imageRect];
//                            cell.iconImageView.image = UIGraphicsGetImageFromCurrentImageContext();
//                            UIGraphicsEndImageContext();
//                            [updateCell setNeedsDisplay];
//                            [updateCell setNeedsLayout];
//                        }
//                    });
//                    [databaseManager saveIcon:image forRepo:source];
//                }
//                else {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        if (updateCell) {
//                            updateCell.iconImageView.image = [UIImage imageNamed:@"Unknown"];
//                            CGSize itemSize = CGSizeMake(35, 35);
//                            UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
//                            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
//                            [cell.iconImageView.image drawInRect:imageRect];
//                            cell.iconImageView.image = UIGraphicsGetImageFromCurrentImageContext();
//                            UIGraphicsEndImageContext();
//                            [updateCell setNeedsDisplay];
//                            [updateCell setNeedsLayout];
//                        }
//                    });
//                }
//            }
//            if (error) {
//                NSLog(@"[Zebra] Error while getting icon URL: %@", error);
//            }
//        }];
//        [task resume];
//    }
    if ([self.defaults boolForKey:@"darkMode"]) {
        cell.repoLabel.textColor = [UIColor whiteColor];//[UIColor cellPrimaryTextColor];
        cell.urlLabel.textColor = [UIColor lightGrayColor];//[UIColor cellSecondaryTextColor];
        cell.backgroundContainerView.backgroundColor = [UIColor colorWithRed:0.110 green:0.110 blue:0.114 alpha:1.0];//[UIColor cellBackgroundColor];
    } else {
        cell.repoLabel.textColor = [UIColor cellPrimaryTextColor];
        cell.urlLabel.textColor = [UIColor cellSecondaryTextColor];
        cell.backgroundContainerView.backgroundColor = [UIColor cellBackgroundColor];
    }
    return cell;
}

 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
     return [[self sourceAtIndexPath:indexPath] canDelete];
 }

 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        ZBRepo *delRepo = [self sourceAtIndexPath:indexPath];
        [sources removeObject:delRepo];
        
        [tableView beginUpdates];
        if ([tableView numberOfRowsInSection:indexPath.section] == 1) {
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        }
        else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        [self updateCollation];
        [tableView endUpdates];
        
        [self.repoManager deleteSource:delRepo];
        ZBTabBarController *tabController = (ZBTabBarController *)[[[UIApplication sharedApplication] delegate] window].rootViewController;
        [tabController setPackageUpdateBadgeValue:(int)[databaseManager packagesWithUpdates].count];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self hasDataInSection:section] ? 30 : 0;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return sectionIndexTitles;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (![self hasDataInSection:section])
        return nil;
    return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self hasDataInSection:section]) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0)];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.frame.size.width - 10, 18)];
        [label setFont:[UIFont boldSystemFontOfSize:15]];
        [label setText:[self sectionIndexTitlesForTableView:tableView][section]];
        if ([self.defaults boolForKey:@"darkMode"]) {
            [label setTextColor:[UIColor whiteColor]];
        } else {
            [label setTextColor:[UIColor cellPrimaryTextColor]];
        }
        [view addSubview:label];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[label]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label]-5-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
        return view;
    }
    else {
        return nil;
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *destination = [segue destinationViewController];
    
    if ([destination isKindOfClass:[ZBRepoSectionsListTableViewController class]]) {
        UITableViewCell *cell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        ((ZBRepoSectionsListTableViewController *)destination).repo = [self sourceAtIndexPath:indexPath];
    } else if ([destination isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navCon = (UINavigationController *)destination;
        UIViewController *firstVC = navCon.viewControllers.firstObject;
        if ([firstVC isKindOfClass:[ZBAddRepoViewController class]]) {
            ((ZBAddRepoViewController *)firstVC).delegate = self;
        }
    }
}

- (void)delewhoop:(NSNotification *)notification {
    ZBRepo *repo = (ZBRepo *)[[notification userInfo] objectForKey:@"repo"];
    NSInteger pos = [sourceIndexes[[repo baseFileName]] integerValue];
    [self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:[self indexPathForPosition:pos]];
}

- (void)setRepoRefreshIndicatorVisible:(BOOL)visible {
    [(ZBTabBarController *)self.tabBarController setRepoRefreshIndicatorVisible:visible];
}

#pragma mark - ZBAddRepoDelegate

- (void)didAddReposWithText:(NSString *)text {
    [self addReposWithText:text];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
        if (self->errorMessages) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ZBRefreshViewController *refreshController = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
            refreshController.messages = self->errorMessages;
            
            self->errorMessages = NULL;
            
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

- (void)handleImportOf:(NSURL *)url {
    if ([[url pathExtension] isEqualToString:@"list"]) {
        NSMutableString *urls = [@"Would you like to import the following repos?\n" mutableCopy];
        
        NSError *readError;
        NSArray *contents = [[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&readError] componentsSeparatedByString:@"\n"];
        if (readError != NULL) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:readError.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:NULL];
            
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:true completion:nil];
        }
        
        for (NSString *line in contents) {
            NSArray *components = [line componentsSeparatedByString:@" "];
            if ([components count] == 3) {
                [urls appendString:[components[1] stringByAppendingString:@"\n"]];
            }
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Import Sources" message:urls preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ZBRepoManager *repoManager = [[ZBRepoManager alloc] init];
            
            [repoManager mergeSourcesFrom:url into:[ZBAppDelegate sourcesListURL] completion:^(NSError * _Nonnull error) {
                if (error != NULL) {
                    NSLog(@"[Zebra] Error when merging sources from %@ into %@: %@", url, [ZBAppDelegate sourcesListURL], error);
                }
                else {
                    NSLog(@"[Zebra] Successfully merged sources");
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    UIViewController *console = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
                    [self presentViewController:console animated:true completion:nil];
                }
            }];
        }];
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:NULL];
        
        [alertController addAction:yesAction];
        [alertController addAction:noAction];
        
        [self presentViewController:alertController animated:true completion:nil];
    }
    else {
        NSMutableString *urls = [@"Would you like to import the following repos?\n" mutableCopy];
        
        NSError *readError;
        NSArray *contents = [[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&readError] componentsSeparatedByString:@"\n"];
        if (readError != NULL) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:readError.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:NULL];
            
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:true completion:nil];
        }
        
        for (NSString *line in contents) {
            NSArray *components = [line componentsSeparatedByString:@" "];
            if ([components count] == 2 && [components[0] isEqualToString:@"URIs:"]) {
                [urls appendString:[components[1] stringByAppendingString:@"\n"]];
            }
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Import Sources" message:urls preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ZBRepoManager *repoManager = [[ZBRepoManager alloc] init];
            
            [repoManager mergeSourcesFrom:url into:[ZBAppDelegate sourcesListURL] completion:^(NSError * _Nonnull error) {
                if (error != NULL) {
                    NSLog(@"[Zebra] Error when merging sources from %@ into %@: %@", url, [ZBAppDelegate sourcesListURL], error);
                }
                else {
                    NSLog(@"[Zebra] Successfully merged sources");
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    UIViewController *console = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
                    [self presentViewController:console animated:true completion:nil];
                }
            }];
        }];
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:NULL];
        
        [alertController addAction:yesAction];
        [alertController addAction:noAction];
        
        [self presentViewController:alertController animated:true completion:nil];
    }
}

-(void)darkMode:(NSNotification *) notification{
    [ZBAppDelegate refreshViews];
    [self.tableView reloadData];
    self.tableView.sectionIndexColor = [UIColor tintColor];
    [self.navigationController.navigationBar setTintColor:[UIColor tintColor]];
}


@end
