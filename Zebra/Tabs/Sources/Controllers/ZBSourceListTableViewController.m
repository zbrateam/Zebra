//
//  ZBSourceListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/3/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <ZBDevice.h>
#import <ZBAppDelegate.h>
#import <ZBTabBarController.h>
#import <UIColor+GlobalColors.h>
#import "ZBSourceImportTableViewController.h"
#import "ZBSourceListTableViewController.h"
#import "ZBAddRepoViewController.h"
#import <Database/ZBDatabaseManager.h>
#import <Database/ZBRefreshViewController.h>
#import <Sources/Helpers/ZBSourceManager.h>
#import <Sources/Helpers/ZBSource.h>
#import <Sources/Views/ZBRepoTableViewCell.h>
#import <Sources/Controllers/ZBRepoSectionsListTableViewController.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Queue/ZBQueue.h>

@import FirebaseAnalytics;
@import SDWebImage;

@interface ZBSourceListTableViewController () {
    NSMutableArray *errorMessages;
    BOOL askedToAddFromClipboard;
    BOOL isRefreshingTable;
    NSString *lastPaste;
    ZBSourceManager *sourceManager;
}
@end

@implementation ZBSourceListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyLocalization];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
    sources = [[self.databaseManager sources] mutableCopy];
    sourceIndexes = [NSMutableDictionary new];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRepoTableViewCell" bundle:nil] forCellReuseIdentifier:@"repoTableViewCell"];
    [self baseViewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    }
}

- (void)applyLocalization {
    // This isn't exactly "best practice", but this way the text in IB isn't useless.
    self.navigationItem.title = NSLocalizedString([self.navigationItem.title capitalizedString], @"");
}

- (void)baseViewDidLoad {
    sourceManager = [ZBSourceManager sharedInstance];
    
    self.navigationController.navigationBar.tintColor = [UIColor tintColor];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(delewhoop:) name:@"deleteRepoTouchAction" object:nil];
    
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    
//    self.tableView.contentInset = UIEdgeInsetsMake(5.0, 0.0, CGRectGetHeight(self.tabBarController.tabBar.frame), 0.0);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkClipboard) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBDatabaseCompletedUpdate" object:nil];
    [self refreshTable];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBDatabaseCompletedUpdate" object:nil];
}

- (void)layoutNavigationButtonsRefreshing {
    [super layoutNavigationButtonsRefreshing];
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)layoutNavigationButtonsNormal {
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

- (void)checkClipboard {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSURL *url = [NSURL URLWithString:pasteboard.string];
    NSArray *urlBlacklist = @[@"youtube.com", @"youtu.be", @"google.com", @"reddit.com", @"twitter.com", @"facebook.com", @"imgur.com", @"discord.com", @"discord.gg"];
    NSMutableArray *repos = [NSMutableArray new];
    
    for (ZBSource *repo in [self.databaseManager sources]) {
        NSString *host = [[NSURL URLWithString:repo.repositoryURI] host];
        if (host) {
            [repos addObject:host];
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

- (void)editMode:(id)sender {
    [self setEditing:!self.editing animated:YES];
    [self layoutNavigationButtons];
}

- (void)refreshTable {
    if (isRefreshingTable)
        return;
    self->sources = [[self.databaseManager sources] mutableCopy];
    dispatch_async(dispatch_get_main_queue(), ^{
        self->isRefreshingTable = YES;
        [self updateCollation];
        [self.tableView reloadData];
        self->isRefreshingTable = NO;
    });
}

- (void)updateCollation {
    self.tableData = [self partitionObjects:sources collationStringSelector:@selector(label)];
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
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter URL", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
    alertController.view.tintColor = [UIColor tintColor];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *sourceURL = alertController.textFields[0].text;
        
//        [self addReposWithText:sourceURL];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add Multiple", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
    if ([ZBDevice darkModeEnabled]) {
        for (UITextField *textField in alertController.textFields) {
            textField.textColor = [UIColor cellPrimaryTextColor];
            textField.backgroundColor = [UIColor cellSeparatorColor];
            textField.superview.backgroundColor = [UIColor clearColor];
            textField.superview.layer.borderColor = [UIColor clearColor].CGColor;
        }
    }
}

- (void)showAddRepoFromClipboardAlert:(NSURL *)repoURL {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Would you like to add the URL from your clipboard?", @"") message:repoURL.absoluteString preferredStyle:UIAlertControllerStyleAlert];
    alertController.view.tintColor = [UIColor tintColor];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"") style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *sourceURL = repoURL.absoluteString;
        
        UIAlertController *wait = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please Wait...", @"") message:NSLocalizedString(@"Verifying Source(s)", @"") preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:wait animated:YES completion:nil];
        
        __weak typeof(self) weakSelf = self;
        [self->repoManager addSourcesFromString:sourceURL response:^(BOOL success, BOOL multiple, NSString * _Nonnull error, NSArray<NSURL *> * _Nonnull failedURLs) {
            if (!success) {
                NSLog(@"[Zebra] Could not add source %@ due to error %@", failedURLs[0].absoluteString, error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [wait dismissViewControllerAnimated:YES completion:^{
                        [weakSelf presentVerificationFailedAlert:error url:failedURLs[0] present:NO];
                    }];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [wait dismissViewControllerAnimated:YES completion:^{
                        NSLog(@"[Zebra] Added source, new Repo File: %@", [NSString stringWithContentsOfFile:[ZBAppDelegate sourcesListPath] encoding:NSUTF8StringEncoding error:nil]);
                        ZBBaseSource *baseSource = [[ZBBaseSource alloc] initWithArchiveType:@"deb" repositoryURI:[repoURL absoluteString] distribution:@"./" components:NULL];
                        
                        ZBRefreshViewController *console = [[ZBRefreshViewController alloc] initWithBaseSources:[NSSet setWithArray:@[baseSource]]];
                        [weakSelf presentViewController:console animated:YES completion:nil];
                    }];
                });
            }
        }];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)presentVerificationFailedAlert:(NSString *)message url:(NSURL *)url present:(BOOL)present {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to verify Repo", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
        alertController.view.tintColor = [UIColor tintColor];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (present) {
                [self showAddRepoAlert:url];
            }
        }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

- (NSObject *)sourceAtIndexPath:(NSIndexPath *)indexPath {
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
    for (ZBSource *object in array) {
        NSUInteger index = [collation sectionForObject:object collationStringSelector:selector];
        NSMutableArray *section = [unsortedSections objectAtIndex:index];
        sourceIndexes[[object baseFilename]] = @((index << 16) | section.count);
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
    
    NSObject *source = [self sourceAtIndexPath:indexPath];
    if ([source isKindOfClass:[ZBSource class]]) {
        ZBSource *trueSource = (ZBSource *)source;
        cell.repoLabel.text = [trueSource label];
        
        NSDictionary *busyList = ((ZBTabBarController *)self.tabBarController).repoBusyList;
        [self setSpinnerVisible:[busyList[[trueSource baseFilename]] boolValue] forCell:cell];
        
        cell.urlLabel.text = [trueSource repositoryURI];
        [cell.iconImageView sd_setImageWithURL:[trueSource iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
        
        cell.repoLabel.textColor = [UIColor cellPrimaryTextColor];
        cell.urlLabel.textColor = [UIColor cellSecondaryTextColor];
        cell.backgroundContainerView.backgroundColor = [UIColor cellBackgroundColor];
        
        cell.tintColor = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
    else {
        ZBBaseSource *baseSource = (ZBBaseSource *)source;
        
        cell.repoLabel.text = [baseSource repositoryURI];
        
        cell.urlLabel.text = @"Tap to learn more";
        cell.iconImageView.image = [UIImage imageNamed:@"Unknown"];
        
        cell.repoLabel.textColor = [UIColor systemPinkColor];
        cell.urlLabel.textColor = [UIColor systemPinkColor];
        cell.backgroundContainerView.backgroundColor = [UIColor cellBackgroundColor];
        
        cell.tintColor = [UIColor systemPinkColor];
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(ZBRepoTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = [self sourceAtIndexPath:indexPath];
    NSDictionary *busyList = ((ZBTabBarController *)self.tabBarController).repoBusyList;
    [self setSpinnerVisible:[busyList[[source baseFilename]] boolValue] forCell:cell];
}

 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
     return ![self.databaseManager isDatabaseBeingUpdated];
 }

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *repo = [self sourceAtIndexPath:indexPath];
    return [repo canDelete] ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBBaseSource *baseSource = [self sourceAtIndexPath:indexPath];
    NSMutableArray *actions = [NSMutableArray array];
    if ([baseSource isKindOfClass:[ZBSource class]]) {
        ZBSource *source = (ZBSource *)baseSource;
        if ([source canDelete]) {
            UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:[queue displayableNameForQueueType:ZBQueueTypeRemove useIcon:true] handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                [self->sources removeObject:source];
                [self->sourceManager deleteSource:source];
                [self refreshTable];
            }];
            [actions addObject:deleteAction];
        }
        if (![self.databaseManager isDatabaseBeingUpdated]) {
            NSString *title = [ZBDevice useIcon] ? @"↺" : NSLocalizedString(@"Refresh", @"");
            UITableViewRowAction *refreshAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                //FIXME: fix me !
        //           [self.databaseManager updateRepo:repo useCaching:YES];
            }];
                
            if ([[UIColor tintColor] isEqual:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]]) {
                refreshAction.backgroundColor = [UIColor grayColor];
            }
            else {
                refreshAction.backgroundColor = [UIColor tintColor];
            }
                
            [actions addObject:refreshAction];
        }
    }
    else if ([baseSource canDelete]) {
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:[queue displayableNameForQueueType:ZBQueueTypeRemove useIcon:true] handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            [self->sources removeObject:baseSource];
            [self->repoManager deleteBaseSource:baseSource];
            [self refreshTable];
        }];
        [actions addObject:deleteAction];
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self hasDataInSection:section]) {
        UITableViewHeaderFooterView *view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"alphabeticalReuse"];
        view.textLabel.font = [UIFont boldSystemFontOfSize:15];
        view.textLabel.textColor = [UIColor cellPrimaryTextColor];
        view.contentView.backgroundColor = [UIColor tableViewBackgroundColor];
        
        return view;
    }
    
    return NULL;
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
    }
}

- (void)delewhoop:(NSNotification *)notification {
    ZBSource *repo = (ZBSource *)[[notification userInfo] objectForKey:@"repo"];
    NSInteger pos = [sourceIndexes[[repo baseFilename]] integerValue];
    [self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:[self indexPathForPosition:pos]];
}

#pragma mark - Database Delegate

- (void)databaseCompletedUpdate:(int)packageUpdates {
    [super databaseCompletedUpdate:packageUpdates];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->errorMessages) {
            ZBRefreshViewController *refreshController = [[ZBRefreshViewController alloc] initWithMessages:[self->errorMessages copy]];
            [self presentViewController:refreshController animated:YES completion:nil];
            self->errorMessages = NULL;
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
    ZBSourceImportTableViewController *importController = [[ZBSourceImportTableViewController alloc] initWithSourceFiles:@[url]];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:importController];
    [self presentViewController:navController animated:true completion:nil];
}

- (void)darkMode:(NSNotification *)notification {
    [ZBDevice refreshViews];
    [self.tableView reloadData];
    self.tableView.sectionIndexColor = [UIColor tintColor];
    [self.navigationController.navigationBar setTintColor:[UIColor tintColor]];
}

#pragma mark - Source Verification Delegate

- (void)source:(ZBBaseSource *)source status:(ZBSourceVerification)verified {
    
}

@end
