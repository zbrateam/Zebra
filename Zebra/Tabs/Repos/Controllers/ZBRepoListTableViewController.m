//
//  ZBRepoListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/3/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <ZBDevice.h>
#import <ZBAppDelegate.h>
#import <ZBTabBarController.h>
#import <UIColor+GlobalColors.h>
#import "ZBRepoListTableViewController.h"
#import "ZBAddRepoViewController.h"
#import "ZBAddRepoDelegate.h"
#import <Database/ZBDatabaseManager.h>
#import <Database/ZBRefreshViewController.h>
#import <Repos/Helpers/ZBRepoManager.h>
#import <Repos/Helpers/ZBRepo.h>
#import <Repos/Helpers/ZBRepoTableViewCell.h>
#import <Repos/Controllers/ZBRepoSectionsListTableViewController.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Queue/ZBQueue.h>

@import SDWebImage;

@interface ZBRepoListTableViewController () <ZBAddRepoDelegate> {
    NSMutableArray *errorMessages;
    BOOL askedToAddFromClipboard;
    BOOL isRefreshingTable;
    NSString *lastPaste;
    ZBRepoManager *repoManager;
    ZBQueue *queue;
}
@end

@implementation ZBRepoListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
    sources = [[self.databaseManager repos] mutableCopy];
    sourceIndexes = [NSMutableDictionary new];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRepoTableViewCell" bundle:nil] forCellReuseIdentifier:@"repoTableViewCell"];
    [self baseViewDidLoad];
}

- (void)baseViewDidLoad {
    queue = [ZBQueue sharedInstance];
    repoManager = [ZBRepoManager sharedInstance];
    
    self.navigationController.navigationBar.tintColor = [UIColor tintColor];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(delewhoop:) name:@"deleteRepoTouchAction" object:nil];
    
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    
    self.tableView.contentInset = UIEdgeInsetsMake(5.0, 0.0, CGRectGetHeight(self.tabBarController.tabBar.frame), 0.0);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkClipboard) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBDatabaseCompletedUpdate" object:nil];
    [self refreshTable];
    [self layoutNavigationButtons];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBDatabaseCompletedUpdate" object:nil];
}

- (void)layoutNavigationButtons {
    if (self.refreshControl.refreshing) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItems = @[cancelButton];
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        if (self.editing) {
            UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editMode:)];
            self.navigationItem.rightBarButtonItem = doneButton;
            
            UIBarButtonItem *exportButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(exportSources)];
            self.navigationItem.leftBarButtonItem = exportButton;
        } else {
            self.editButtonItem.action = @selector(editMode:);
            self.navigationItem.rightBarButtonItem = self.editButtonItem;
            
            UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSource:)];
            self.navigationItem.leftBarButtonItems = @[addButton];
        }
    }
}

- (void)checkClipboard {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSURL *url = [NSURL URLWithString:pasteboard.string];
    NSArray *urlBlacklist = @[@"youtube.com", @"google.com", @"reddit.com", @"twitter.com", @"facebook.com", @"imgur.com", @"discord.com", @"discord.gg"];
    NSMutableArray *repos = [NSMutableArray new];
    
    for (ZBRepo *repo in [self.databaseManager repos]) {
        if (repo.secure) {
            [repos addObject:[[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", repo.baseURL]] host]];
        } else {
            [repos addObject:[[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", repo.baseURL]] host]];
        }
    }
    if ((url && url.scheme && url.host)) {
        if ([[url scheme] isEqual:@"https"] || [[url scheme] isEqual:@"http"]) {
            if (!askedToAddFromClipboard || ![lastPaste isEqualToString:pasteboard.string]) {
                if (![urlBlacklist containsObject:url.host] && ![repos containsObject:url.host]) {
                    [self showAddRepoFromClipboardAlert:url];
                }
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
    [self presentViewController:shareSheet animated:YES completion:nil];
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
    [cell setSpinning:visible];
}

- (void)setSpinnerVisible:(BOOL)visible forRepo:(NSString *)bfn {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger pos = [self->sourceIndexes[bfn] integerValue];
        ZBRepoTableViewCell *cell = (ZBRepoTableViewCell *)[self.tableView cellForRowAtIndexPath:[self indexPathForPosition:pos]];
        [self setSpinnerVisible:visible forCell:cell];
    });
}

- (void)clearAllSpinners {
    [((ZBTabBarController *)self.tabBarController).repoBusyList removeAllObjects];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)editMode:(id)sender {
    [self setEditing:!self.editing animated:YES];
    [self layoutNavigationButtons];
}

- (void)cancel:(id)sender {
    [self.databaseManager cancelUpdates:self];
    ((ZBTabBarController *)self.tabBarController).repoBusyList = [NSMutableDictionary new];
}

- (void)refreshTable {
    if (isRefreshingTable)
        return;
    self->sources = [[self.databaseManager repos] mutableCopy];
    dispatch_async(dispatch_get_main_queue(), ^{
        self->isRefreshingTable = YES;
        [self updateCollation];
        [self.tableView reloadData];
        self->isRefreshingTable = NO;
    });
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
        } else if ([components count] >= 4) {
            NSString *urlString = [path componentsSeparatedByString:@"/add/"][1];
            
            NSURL *url;
            if ([urlString containsString:@"https://"] || [urlString containsString:@"http://"]) {
                url = [NSURL URLWithString:urlString];
            } else {
                url = [NSURL URLWithString:[@"https://" stringByAppendingString:urlString]];
            }
            
            if (url && url.scheme && url.host) {
                [self showAddRepoAlert:url];
            } else {
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
        } else {
            textField.text = @"https://";
        }
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.keyboardType = UIKeyboardTypeURL;
        textField.returnKeyType = UIReturnKeyNext;
    }];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showAddRepoFromClipboardAlert:(NSURL *)repoURL {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Would you like to add the URL from your clipboard?" message:repoURL.absoluteString preferredStyle:UIAlertControllerStyleAlert];
    alertController.view.tintColor = [UIColor tintColor];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *sourceURL = repoURL.absoluteString;
        
        UIAlertController *wait = [UIAlertController alertControllerWithTitle:@"Please Wait..." message:@"Verifying Source" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:wait animated:YES completion:nil];
        
        __weak typeof(self) weakSelf = self;
        [self->repoManager addSourceWithString:sourceURL response:^(BOOL success, NSString *error, NSURL *url) {
            if (!success) {
                NSLog(@"[Zebra] Could not add source %@ due to error %@", url.absoluteString, error);
                [wait dismissViewControllerAnimated:YES completion:^{
                    [weakSelf presentVerificationFailedAlert:error url:url present:NO];
                }];
            } else {
                [wait dismissViewControllerAnimated:YES completion:^{
                    NSLog(@"[Zebra] Added source, new Repo File: %@", [NSString stringWithContentsOfFile:[ZBAppDelegate sourcesListPath] encoding:NSUTF8StringEncoding error:nil]);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                        ZBRefreshViewController *console = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
                        console.repoURLs = @[ repoURL ];
                        [weakSelf presentViewController:console animated:YES completion:nil];
                    });
                }];
            }
        }];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
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
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)addReposWithText:(NSString *)text {
    UIAlertController *wait = [UIAlertController alertControllerWithTitle:@"Please Wait..." message:@"Verifying Source(s)" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:wait animated:YES completion:nil];
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(ZBRepoManager *) repoManager = self->repoManager;
    
    [repoManager addSourcesFromString:text response:^(BOOL success, NSString * _Nonnull error, NSArray<NSURL *> * _Nonnull failedURLs) {
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
                            
                            [weakSelf presentViewController:navCon animated:YES completion:nil];
                        } else {
                            NSURL *failedURL = [failedURLs[0] URLByDeletingLastPathComponent];
                            [weakSelf showAddRepoAlert:failedURL];
                        }
                    }];
                    
                    [errorAlert addAction:editAction];
                }
                
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                
                [errorAlert addAction:cancelAction];
                
                [weakSelf presentViewController:errorAlert animated:YES completion:nil];
            } else {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                ZBRefreshViewController *console = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
                console.repoURLs = [repoManager verifiedURLs];
                [weakSelf presentViewController:console animated:YES completion:nil];
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
        sourceIndexes[[object baseFileName]] = @((index << 16) | section.count);
        [section addObject:object];
    }
    NSUInteger lastIndex = 0;
    NSMutableIndexSet *sectionsToRemove = [NSMutableIndexSet indexSet];
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];
    for (NSMutableArray *section in unsortedSections) {
        if ([section count] == 0) {
            NSRange range = NSMakeRange(lastIndex, [unsortedSections count] - lastIndex);
            [sectionsToRemove addIndex:[unsortedSections indexOfObject:section inRange:range]];
            lastIndex = [sectionsToRemove lastIndex] + 1;
        } else {
            NSArray *data = [collation sortedArrayFromArray:section collationStringSelector:selector];
            [sections addObject:data];
        }
    }
    [sectionIndexTitles removeObjectsAtIndexes:sectionsToRemove];
    for (NSString *bfn in [sourceIndexes allKeys]) {
        NSInteger pos = [sourceIndexes[bfn] integerValue];
        int index = (int)(pos >> 16);
        NSInteger row = pos & 0xFF;
        index = (int)[sectionIndexTitles indexOfObject:[NSString stringWithFormat:@"%c", 65 + index]];
        sourceIndexes[bfn] = @(index << 16 | row);
    }
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

- (ZBRepoTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBRepoTableViewCell *cell = (ZBRepoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
    
    ZBRepo *source = [self sourceAtIndexPath:indexPath];
    
    cell.repoLabel.text = [source origin];
    
    NSDictionary *busyList = ((ZBTabBarController *)self.tabBarController).repoBusyList;
    [self setSpinnerVisible:[busyList[[source baseFileName]] boolValue] forCell:cell];
    
    if ([source isSecure]) {
        cell.urlLabel.text = [NSString stringWithFormat:@"https://%@", [source shortURL]];
    } else {
        cell.urlLabel.text = [NSString stringWithFormat:@"http://%@", [source shortURL]];
    }
    [cell.iconImageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    
    cell.repoLabel.textColor = [UIColor cellPrimaryTextColor];
    cell.urlLabel.textColor = [UIColor cellSecondaryTextColor];
    cell.backgroundContainerView.backgroundColor = [UIColor cellBackgroundColor];
    return cell;
}

 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
     return ![self.databaseManager isDatabaseBeingUpdated];
 }

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBRepo *repo = [self sourceAtIndexPath:indexPath];
    return [repo canDelete] ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBRepo *repo = [self sourceAtIndexPath:indexPath];
    NSMutableArray *actions = [NSMutableArray array];
    if ([repo canDelete]) {
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:[queue queueToKeyDisplayed:ZBQueueTypeRemove] handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            [self->sources removeObject:repo];
            [self->repoManager deleteSource:repo];
            [self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
        }];
        [actions addObject:deleteAction];
    }
    if (![self.databaseManager isDatabaseBeingUpdated]) {
        NSString *title = [queue useIcon] ? [queue queueToKeyDisplayed:ZBQueueTypeReinstall] : @"Refresh";
        UITableViewRowAction *refreshAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            [self.databaseManager updateRepo:repo useCaching:YES];
        }];
        refreshAction.backgroundColor = [UIColor tintColor];
        [actions addObject:refreshAction];
    }
    return actions;
}

 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView beginUpdates];
        if ([tableView numberOfRowsInSection:indexPath.section] == 1) {
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        [self updateCollation];
        [tableView endUpdates];
        
        ZBTabBarController *tabController = (ZBTabBarController *)[[[UIApplication sharedApplication] delegate] window].rootViewController;
        [tabController setPackageUpdateBadgeValue:(int)[self.databaseManager packagesWithUpdates].count];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBDatabaseCompletedUpdate" object:nil];
    }
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
    return [sectionIndexTitles objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([self hasDataInSection:section]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.textLabel.font = [UIFont boldSystemFontOfSize:15];
        header.textLabel.textColor = [UIColor cellPrimaryTextColor];
        header.tintColor = [UIColor clearColor];
        [(UIView *)[header valueForKey:@"_backgroundView"] setBackgroundColor:[UIColor clearColor]];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return (action == @selector(copy:));
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        ZBRepoTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        [pasteBoard setString:cell.urlLabel.text];
    }
}

#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"segueReposToRepoSection" sender:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *destination = [segue destinationViewController];
    
    if ([destination isKindOfClass:[ZBRepoSectionsListTableViewController class]]) {
        NSIndexPath *indexPath = sender;
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

#pragma mark - ZBAddRepoDelegate

- (void)didAddReposWithText:(NSString *)text {
    [self addReposWithText:text];
}

#pragma mark - Database Delegate

- (void)databaseStartedUpdate {
    [super databaseStartedUpdate];
    [self layoutNavigationButtons];
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    [super databaseCompletedUpdate:packageUpdates];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->errorMessages) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ZBRefreshViewController *refreshController = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
            refreshController.messages = self->errorMessages;
            self->errorMessages = NULL;
            [self presentViewController:refreshController animated:YES completion:nil];
        }
    });
}

- (void)didEndRefreshing {
    [self layoutNavigationButtons];
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
            [self presentViewController:alertController animated:YES completion:nil];
        }
        
        for (NSString *line in contents) {
            NSArray *components = [line componentsSeparatedByString:@" "];
            if ([components count] != 0 && [components[0] isEqualToString:@"deb"]) {
                [urls appendString:[components[1] stringByAppendingString:@"\n"]];
            }
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Import Sources" message:urls preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self->repoManager mergeSourcesFrom:url into:[ZBAppDelegate sourcesListURL] completion:^(NSError * _Nonnull error) {
                if (error != NULL) {
                    NSLog(@"[Zebra] Error when merging sources from %@ into %@: %@", url, [ZBAppDelegate sourcesListURL], error);
                } else {
                    NSLog(@"[Zebra] Successfully merged sources");
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    UIViewController *console = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
                    [self presentViewController:console animated:YES completion:nil];
                }
            }];
        }];
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:NULL];
        
        [alertController addAction:yesAction];
        [alertController addAction:noAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        NSMutableString *urls = [@"Would you like to import the following repos?\n" mutableCopy];
        
        NSError *readError;
        NSArray *contents = [[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&readError] componentsSeparatedByString:@"\n"];
        if (readError != NULL) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:readError.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:NULL];
            
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
        
        for (NSString *line in contents) {
            NSArray *components = [line componentsSeparatedByString:@" "];
            if ([components count] == 2 && [components[0] isEqualToString:@"URIs:"]) {
                [urls appendString:[components[1] stringByAppendingString:@"\n"]];
            }
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Import Sources" message:urls preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self->repoManager mergeSourcesFrom:url into:[ZBAppDelegate sourcesListURL] completion:^(NSError * _Nonnull error) {
                if (error != NULL) {
                    NSLog(@"[Zebra] Error when merging sources from %@ into %@: %@", url, [ZBAppDelegate sourcesListURL], error);
                } else {
                    NSLog(@"[Zebra] Successfully merged sources");
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    UIViewController *console = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
                    [self presentViewController:console animated:YES completion:nil];
                }
            }];
        }];
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:NULL];
        
        [alertController addAction:yesAction];
        [alertController addAction:noAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)darkMode:(NSNotification *)notification {
    [ZBDevice refreshViews];
    [self.tableView reloadData];
    self.tableView.sectionIndexColor = [UIColor tintColor];
    [self.navigationController.navigationBar setTintColor:[UIColor tintColor]];
}

@end
