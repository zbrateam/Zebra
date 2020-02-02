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
#import "ZBAddSourceViewController.h"
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
    UIAlertController *verifyPopup;
}
@end

@implementation ZBSourceListTableViewController

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    sources = [[self.databaseManager sources] mutableCopy];
    sourceIndexes = [NSMutableDictionary new];
    sourceManager = [ZBSourceManager sharedInstance];
    
    self.navigationItem.title = NSLocalizedString([self.navigationItem.title capitalizedString], @"");
    self.navigationController.navigationBar.tintColor = [UIColor accentColor];
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    
    if (@available(iOS 13.0, *)) {} else {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRepoTableViewCell" bundle:nil] forCellReuseIdentifier:@"repoTableViewCell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(darkMode:) name:@"darkMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(delewhoop:) name:@"deleteRepoTouchAction" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkClipboard) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBDatabaseCompletedUpdate" object:nil];
     
    [self refreshTable];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    }
    
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self checkClipboard];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBDatabaseCompletedUpdate" object:nil];
}

#pragma mark - Dark Mode

- (void)darkMode:(NSNotification *)notification {
//    [ZBDevice refreshViews];
    [self.tableView reloadData];
    self.tableView.sectionIndexColor = [UIColor accentColor];
    [self.navigationController.navigationBar setTintColor:[UIColor accentColor]];
}

#pragma mark - Table View Data Source

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
        
        cell.repoLabel.textColor = [UIColor primaryTextColor];
        cell.urlLabel.textColor = [UIColor secondaryTextColor];
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
            UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"Remove", @"") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
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
                
            if ([[UIColor accentColor] isEqual:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]]) {
                refreshAction.backgroundColor = [UIColor grayColor];
            }
            else {
                refreshAction.backgroundColor = [UIColor accentColor];
            }
                
            [actions addObject:refreshAction];
        }
    }
    else if ([baseSource canDelete]) {
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"Remove", @"") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            [self->sources removeObject:baseSource];
            [self->sourceManager deleteSource:(ZBSource *)baseSource];
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

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return [self hasDataInSection:section] ? 30 : 0;
//}
//
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    if ([self hasDataInSection:section]) {
//        UITableViewHeaderFooterView *view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"alphabeticalReuse"];
//        view.textLabel.textColor = [UIColor primaryTextColor];
//
//        return view;
//    }
//
//    return NULL;
//}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (![self hasDataInSection:section])
        return nil;
    return [sectionIndexTitles objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"segueReposToRepoSection" sender:indexPath];
}

#pragma mark - Navigation Buttons

- (void)addSource:(id)sender {
    [self showAddSourceAlert:NULL];
}

- (void)editMode:(id)sender {
    [self setEditing:!self.editing animated:YES];
    [self layoutNavigationButtons];
}

- (void)exportSources {
    UIActivityViewController *shareSheet = [[UIActivityViewController alloc] initWithActivityItems:@[[ZBAppDelegate sourcesListURL]] applicationActivities:nil];
    shareSheet.popoverPresentationController.barButtonItem = self.navigationItem.leftBarButtonItems[0];
    
    [self presentViewController:shareSheet animated:YES completion:nil];
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

#pragma mark - Clipboard

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

- (void)showAddRepoFromClipboardAlert:(NSURL *)repoURL {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Would you like to add the URL from your clipboard?", @"") message:repoURL.absoluteString preferredStyle:UIAlertControllerStyleAlert];
    alertController.view.tintColor = [UIColor accentColor];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"") style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        ZBBaseSource *baseSource = [[ZBBaseSource alloc] initFromURL:repoURL];
        if (baseSource) {
            [self verifyAndAdd:[NSSet setWithObject:baseSource]];
        }
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Adding a Source

- (void)showAddSourceAlert:(NSString *_Nullable)placeholder {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Source URL", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
    alertController.view.tintColor = [UIColor accentColor];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *sourceURL = [NSURL URLWithString:alertController.textFields[0].text];
        
        ZBBaseSource *baseSource = [[ZBBaseSource alloc] initFromURL:sourceURL];
        if (baseSource) {
            [self verifyAndAdd:[NSSet setWithObject:baseSource]];
        }
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add Multiple", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UINavigationController *controller = [ZBAddSourceViewController controllerWithText:alertController.textFields[0].text delegate:self];
        
        [self presentViewController:controller animated:YES completion:nil];
    }]];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        if (placeholder != NULL) {
            textField.text = placeholder;
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

#pragma mark - Table View Helper Methods

- (NSObject *)sourceAtIndexPath:(NSIndexPath *)indexPath {
    if (![self hasDataInSection:indexPath.section])
        return nil;
    return self.tableData[indexPath.section][indexPath.row];
}

- (NSIndexPath *)indexPathForPosition:(NSInteger)pos {
    NSInteger section = pos >> 16;
    NSInteger row = pos & 0xFF;
    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (void)setSpinnerVisible:(BOOL)visible forRepo:(NSString *)baseFilename {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger pos = [self->sourceIndexes[baseFilename] integerValue];
        ZBRepoTableViewCell *cell = (ZBRepoTableViewCell *)[self.tableView cellForRowAtIndexPath:[self indexPathForPosition:pos]];
        [self setSpinnerVisible:visible forCell:cell];
    });
}

- (void)setSpinnerVisible:(BOOL)visible forCell:(ZBRepoTableViewCell *)cell {
    [cell setSpinning:visible];
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

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return sectionIndexTitles;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *destination = [segue destinationViewController];
    
    if ([destination isKindOfClass:[ZBRepoSectionsListTableViewController class]]) {
        NSIndexPath *indexPath = sender;
        ((ZBRepoSectionsListTableViewController *)destination).repo = [self sourceAtIndexPath:indexPath];
    }
}

//I said to myself: "who actually wrote this and named it that." and then i remembered I wrote it
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

#pragma mark - URL Handling

- (void)handleURL:(NSURL *)url {
    NSString *path = [url path];
    
    if (![path isEqualToString:@""]) {
        NSArray *components = [path pathComponents];
        if ([components count] == 2) {
            [self showAddSourceAlert:NULL];
        } else if ([components count] >= 4) {
            NSString *urlString = [path componentsSeparatedByString:@"/add/"][1];
            
            NSURL *url;
            if ([urlString containsString:@"https://"] || [urlString containsString:@"http://"]) {
                url = [NSURL URLWithString:urlString];
            } else {
                url = [NSURL URLWithString:[@"https://" stringByAppendingString:urlString]];
            }
            
            if (url && url.scheme && url.host) {
                [self showAddSourceAlert:[url absoluteString]]; //This should probably be changed
            } else {
                [self showAddSourceAlert:NULL];
            }
        }
    }
}

- (void)handleImportOf:(NSURL *)url {
    ZBSourceImportTableViewController *importController = [[ZBSourceImportTableViewController alloc] initWithSourceFiles:@[url]];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:importController];
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Source Verification Delegate

- (void)startedSourceVerification:(BOOL)multiple {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self->verifyPopup) {
            NSString *message = NSLocalizedString(multiple ? @"Verifying Sources" : @"Verifying Source", @"");
            self->verifyPopup = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please Wait...", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
        }
        
        [self presentViewController:self->verifyPopup animated:YES completion:nil];
    });
}

- (void)finishedSourceVerification:(NSArray *)existingSources imaginarySources:(NSArray *)imaginarySources {
    if ([existingSources count]) { //If there are any existing sources, go ahead and add them
        [sourceManager addBaseSources:[NSSet setWithArray:existingSources]];
        
        NSMutableSet *existing = [NSMutableSet setWithArray:existingSources];
        if ([imaginarySources count]) {
            [existing unionSet:[NSSet setWithArray:imaginarySources]];
        }
        
        ZBRefreshViewController *refreshVC = [[ZBRefreshViewController alloc] initWithBaseSources:existing delegate:self];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->verifyPopup dismissViewControllerAnimated:YES completion:^{
                [self presentViewController:refreshVC animated:YES completion:nil];
            }];
        });
    }
    else if ([imaginarySources count]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->verifyPopup dismissViewControllerAnimated:YES completion:^{
                NSMutableArray *urls = [NSMutableArray new];

                NSMutableString *message = [NSMutableString new];
                NSString *title;
                BOOL multiple = [imaginarySources count] > 1;
                if (multiple) {
                    title = NSLocalizedString(@"Failed to add sources", @"");
                    [message appendString:NSLocalizedString(@"Unable to locate APT repositories at:", @"")];
                }
                else {
                    title = NSLocalizedString(@"Failed to add source", @"");
                    [message appendString:NSLocalizedString(@"Unable to locate an APT repository at:", @"")];
                }
                [message appendString:@"\n"];

                for (ZBBaseSource *source in imaginarySources) {
                    [urls addObject:[source repositoryURI]];
                }
                [message appendString:[urls componentsJoinedByString:@"\n"]];

                UIAlertController *errorPopup = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

                [errorPopup addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

                UIAlertAction *editAction = [UIAlertAction actionWithTitle:@"Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    if (multiple) {
                        UINavigationController *controller = [ZBAddSourceViewController controllerWithText:[urls componentsJoinedByString:@"\n"] delegate:self];

                        [self presentViewController:controller animated:YES completion:nil];
                    }
                    else {
                        [self showAddSourceAlert:urls[0]];
                    }
                }];
                [errorPopup addAction:editAction];

                [errorPopup setPreferredAction:editAction];

                [self presentViewController:errorPopup animated:YES completion:nil];
            }];
        });
    }
}

- (void)verifyAndAdd:(NSSet *)baseSources {
    [sourceManager verifySources:baseSources delegate:self];
}

@end
