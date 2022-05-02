//
//  ZBSourceListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/3/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBSourceImportTableViewController.h"
#import "ZBSourceListTableViewController.h"

#import "ZBDevice.h"
#import "ZBAppDelegate.h"
#import "ZBTabBarController.h"
#import "UIColor+GlobalColors.h"
#import "ZBAddSourceViewController.h"
#import "ZBDatabaseManager.h"
#import "ZBRefreshViewController.h"
#import "ZBSourceManager.h"
#import "ZBSource.h"
#import "ZBSourceTableViewCell.h"
#import "ZBSourceSectionsListTableViewController.h"
#import "ZBPackage.h"
#import "ZBQueue.h"
#import "ZBThemeManager.h"

@import SDWebImage;

@interface ZBSourceListTableViewController () <UITextFieldDelegate> {
    NSMutableArray *errorMessages;
    BOOL askedToAddFromClipboard;
    BOOL isRefreshingTable;
    NSString *lastPaste;
    ZBSourceManager *sourceManager;
    UIAlertController *verifyPopup;
}
@end

@implementation ZBSourceListTableViewController

- (BOOL)forceSetColors {
    return YES;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    sources = [[self.databaseManager sources] mutableCopy];
    sourceIndexes = [NSMutableDictionary new];
    sourceManager = [ZBSourceManager sharedInstance];
    
    self.navigationItem.title = NSLocalizedString([self.navigationItem.title capitalizedString], @"");
    self.navigationController.navigationBar.tintColor = [UIColor accentColor];
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBSourceTableViewCell" bundle:nil] forCellReuseIdentifier:@"sourceTableViewCell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(delewhoop:) name:@"deleteSourceTouchAction" object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkClipboard) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBDatabaseCompletedUpdate" object:nil];
     
    [self refreshTable];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//
//    [self checkClipboard];
//}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBDatabaseCompletedUpdate" object:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return sectionIndexTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self hasDataInSection:section];
}

- (ZBSourceTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSourceTableViewCell *cell = (ZBSourceTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"sourceTableViewCell" forIndexPath:indexPath];
    
    NSObject *source = [self sourceAtIndexPath:indexPath];
    if ([source isKindOfClass:[ZBSource class]]) {
        ZBSource *trueSource = (ZBSource *)source;
        cell.sourceLabel.text = [trueSource label];
        
        NSDictionary *busyList = ((ZBTabBarController *)self.tabBarController).sourceBusyList;
        [self setSpinnerVisible:[busyList[[trueSource baseFilename]] boolValue] forCell:cell];
        
        cell.urlLabel.text = [trueSource repositoryURI];
        [cell.iconImageView sd_setImageWithURL:[trueSource iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
        
        cell.sourceLabel.textColor = [UIColor primaryTextColor];
        cell.urlLabel.textColor = [UIColor secondaryTextColor];
        
        cell.tintColor = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else {
        ZBBaseSource *baseSource = (ZBBaseSource *)source;
        
        [self setSpinnerVisible:NO forCell:cell];
        
        cell.sourceLabel.text = [baseSource repositoryURI];
        
        cell.urlLabel.text = NSLocalizedString(@"Tap to learn more", @"");
        cell.iconImageView.image = [UIImage imageNamed:@"Unknown"];
        
        cell.sourceLabel.textColor = [UIColor systemPinkColor];
        cell.urlLabel.textColor = [UIColor systemPinkColor];
        
        cell.tintColor = [UIColor systemPinkColor];
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    cell.backgroundContainerView.backgroundColor = [UIColor cellBackgroundColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(ZBSourceTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = [self sourceAtIndexPath:indexPath];
    NSDictionary *busyList = ((ZBTabBarController *)self.tabBarController).sourceBusyList;
    [self setSpinnerVisible:[busyList[[source baseFilename]] boolValue] forCell:cell];
}

 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
     return ![self.databaseManager isDatabaseBeingUpdated];
 }

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = [self sourceAtIndexPath:indexPath];
    return [source canDelete] ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBBaseSource *baseSource = [self sourceAtIndexPath:indexPath];
    NSMutableArray *actions = [NSMutableArray array];
    if ([baseSource isKindOfClass:[ZBSource class]]) {
        ZBSource *source = (ZBSource *)baseSource;
        if ([source canDelete]) {
            NSString *title = [ZBDevice useIcon] ? @"✗" : NSLocalizedString(@"Remove", @"");
            UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:title handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                [self->sources removeObject:source];
                [self->sourceManager deleteSource:source];
                [self refreshTable];
            }];
            [actions addObject:deleteAction];
        }
        if (![self.databaseManager isDatabaseBeingUpdated]) {
            NSString *title = [ZBDevice useIcon] ? @"↻" : NSLocalizedString(@"Refresh", @"");
            UITableViewRowAction *refreshAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                [self.databaseManager updateSource:source useCaching:YES];
            }];
            
            ZBAccentColor accentColor = [ZBSettings accentColor];
            if ((accentColor == ZBAccentColorMonochrome || accentColor == ZBAccentColorShark) && [ZBSettings interfaceStyle] >= ZBInterfaceStyleDark) {
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (![self hasDataInSection:section])
        return nil;
    return sectionIndexTitles[section];
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
        ZBSource *source = [self sourceAtIndexPath:indexPath];
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        [pasteBoard setString:source.repositoryURI];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSObject *source = [self sourceAtIndexPath:indexPath];
    if ([source isKindOfClass:[ZBSource class]]) {
        [self performSegueWithIdentifier:@"segueSourcesToSourceSection" sender:indexPath];
    }
    else {
        ZBBaseSource *baseSource = (ZBBaseSource *)source;
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Zebra was unable to download the source specified at %@. It may be temporarily inaccessible or could have been added incorrectly.", @""), [baseSource repositoryURI]];
        UIAlertController *invalidSourceAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Invalid Source", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove Source", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self->sources removeObject:source];
            [self->sourceManager deleteSource:(ZBSource *)baseSource];
            [self refreshTable];
        }];
        [invalidSourceAlert addAction:deleteAction];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:nil];
        [invalidSourceAlert addAction:okAction];
        
        [self presentViewController:invalidSourceAlert animated:YES completion:nil];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - Navigation Buttons

- (void)addSource:(id)sender {
    [self showAddSourceAlert:nil];
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

#pragma mark - Adding a Source

- (void)showAddSourceAlert:(NSString *_Nullable)placeholder {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Source URL", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
    alertController.view.tintColor = [UIColor accentColor];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];

    UIAlertAction *add = [UIAlertAction actionWithTitle:NSLocalizedString(@"Add", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self addSourceFromAlertController:alertController];
    }];
    [alertController addAction:add];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add Multiple…", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UINavigationController *controller = [ZBAddSourceViewController controllerWithText:alertController.textFields[0].text delegate:self];
        [self presentViewController:controller animated:YES completion:nil];
    }]];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.delegate = self;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.keyboardType = UIKeyboardTypeURL;
        textField.returnKeyType = UIReturnKeyGo;
        [[ZBThemeManager sharedInstance] configureTextField:textField];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:textField];

        if (placeholder != nil) {
            textField.text = placeholder;
            [add setEnabled:YES];
        } else {
            textField.text = @"https://";
            [add setEnabled:NO];
            [self _detectURLOnPasteboardWithCompletion:^(NSString *result) {
                if (result) {
                    textField.text = result;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:textField];
                    });
                }
            }];
        }
    }];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)_detectURLOnPasteboardWithCompletion:(void (^)(NSString *))completion {
    if (@available(iOS 14, *)) {
        // Not the most usable API…
        // First we check if the contents of the pasteboard is a URL. This prevents iOS from
        // displaying a scary “pasted from” alert. If it is a URL, we go ahead and grab it, which
        // will trigger the alert, but the user will at least see why we accessed the pasteboard.
        UIPasteboardDetectionPattern pattern = UIPasteboardDetectionPatternProbableWebURL;
        [[UIPasteboard generalPasteboard] detectPatternsForPatterns:[NSSet setWithObject:pattern]
                                                  completionHandler:^(NSSet <UIPasteboardDetectionPattern> *patterns, NSError *error) {
            if ([patterns containsObject:pattern]) {
                [[UIPasteboard generalPasteboard] detectValuesForPatterns:[NSSet setWithObject:pattern]
                                                        completionHandler:^(NSDictionary <UIPasteboardDetectionPattern, id> *values, NSError *error) {
                    NSString *result = values[pattern];
                    if (result) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion([self _fullyQualifiedURLForInput:result]);
                        });
                    }
                }];
            }
        }];
    } else {
        NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        NSString *input = [UIPasteboard generalPasteboard].string ?: @"";
        NSRange range = [detector rangeOfFirstMatchInString:input options:kNilOptions range:NSMakeRange(0, input.length)];
        if (range.location != NSNotFound) {
            NSString *result = [input substringWithRange:range];
            if ([self _isValidURL:result checkFullyQualified:NO]) {
                completion([self _fullyQualifiedURLForInput:result]);
            }
        }
    }
}

- (BOOL)_isValidURL:(NSString *)input checkFullyQualified:(BOOL)checkFullyQualified {
    // Check for valid URL. The data detector also matches incomplete URLs without a scheme. In some
    // cases, a missing scheme is fine. If it isn’t, we also check that NSURL can parse the URL,
    // and that a scheme and host are present.
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    BOOL result = [detector rangeOfFirstMatchInString:input ?: @"" options:kNilOptions range:NSMakeRange(0, input.length)].location == 0;
    if (checkFullyQualified) {
        NSURL *url = [NSURL URLWithString:input];
        result = result && url.scheme.length > 0 && url.host.length > 0;
    }
    return result;
}

- (NSString *)_fullyQualifiedURLForInput:(NSString *)input {
    // If there’s no scheme, let’s just give it a shot anyway by prepending https://.
    if (![input containsString:@"://"]) {
        input = [@"https://" stringByAppendingString:input];
    }

    // If NSURL can parse this and a scheme and host are present, let’s go with it.
    NSURL *url = [NSURL URLWithString:input];
    if (url.scheme.length > 0 && url.host.length > 0) {
        return url.absoluteString;
    }
    return nil;
}

- (void)textDidChange:(NSNotification *)notification {
    UIAlertController * alertController = (UIAlertController *)self.presentedViewController;
    UITextField *textField = alertController.textFields.firstObject;
    UIAlertAction * add = alertController.actions[1];
    
    // This will be useful when pasting the url in text field
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(http(s)?://){2}" options:NSRegularExpressionCaseInsensitive
    error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:textField.text ?: @"" options:0 range:NSMakeRange(0, textField.text.length)];
    if (match) {
        if ([textField.text hasPrefix:@"https"]) {
            textField.text = [textField.text substringFromIndex:8];
        } else {
            textField.text = [textField.text substringFromIndex:7];
        }
    }
    
    // check if it is URL or not
    BOOL isURL = [self _isValidURL:textField.text checkFullyQualified:YES];
    [add setEnabled:isURL];
}

- (void)addSourceFromAlertController:(UIAlertController *)alertController {
    NSString *urlString = [alertController.textFields[0].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([urlString hasPrefix:@"http:"]) {
        // Warn user for insecure source (has low self esteem)
        UIAlertController *insecureSource = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"You are adding a repository that is not secure", @"") message:NSLocalizedString(@"Data downloaded from this repository might not be encrypted. Are you sure you want to add it?", @"") preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *addInsecure = [UIAlertAction actionWithTitle:NSLocalizedString(@"Add", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *repoString = [urlString copy];
            if (![repoString hasSuffix:@"/"]) {
                repoString = [repoString stringByAppendingString:@"/"];
            }

            NSURL *sourceURL = [NSURL URLWithString:repoString];
            [self checkSourceURL:sourceURL];
        }];
        [insecureSource addAction:addInsecure];

        UIAlertAction *edit = [UIAlertAction actionWithTitle:NSLocalizedString(@"Edit", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showAddSourceAlert:urlString];
        }];
        [insecureSource addAction:edit];

        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil];
        [insecureSource addAction:cancel];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:insecureSource animated:YES completion:nil];
        });
        return;
    }

    if (![urlString hasSuffix:@"/"]) {
        urlString = [urlString stringByAppendingString:@"/"];
    }

    NSURL *sourceURL = [NSURL URLWithString:urlString];
    [self checkSourceURL:sourceURL];
}

- (void)checkSourceURL:(NSURL *)sourceURL {
    ZBBaseSource *baseSource = [[ZBBaseSource alloc] initFromURL:sourceURL];
    if (!baseSource) {
        UIAlertController *malformed = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Invalid URL", @"") message:NSLocalizedString(@"The URL you entered is not valid. Please check it and try again.", @"") preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:nil];
        [malformed addAction:ok];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:malformed animated:YES completion:nil];
        });
    }
    else if ([baseSource exists]) {
        //You have already added this source.
        UIAlertController *youAlreadyAdded = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Failed to add source", @"") message:NSLocalizedString(@"You have already added this source.", @"") preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil];
        [youAlreadyAdded addAction:cancelAction];

        UIAlertAction *viewAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"View", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSInteger pos = [self->sourceIndexes[baseSource.baseFilename] integerValue];
            NSIndexPath *indexPath = [self indexPathForPosition:pos];

            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        }];
        [youAlreadyAdded addAction:viewAction];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:youAlreadyAdded animated:YES completion:nil];
        });
    }
    else {
        if (baseSource) {
            [self verifyAndAdd:[NSSet setWithObject:baseSource]];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    [alertController dismissViewControllerAnimated:YES completion:^{
        [self addSourceFromAlertController:alertController];
    }];
    return NO;
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

- (void)setSpinnerVisible:(BOOL)visible forSource:(NSString *)baseFilename {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger pos = [self->sourceIndexes[baseFilename] integerValue];
        ZBSourceTableViewCell *cell = (ZBSourceTableViewCell *)[self.tableView cellForRowAtIndexPath:[self indexPathForPosition:pos]];
        [self setSpinnerVisible:visible forCell:cell];
    });
}

- (void)setSpinnerVisible:(BOOL)visible forCell:(ZBSourceTableViewCell *)cell {
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
        NSMutableArray *section = unsortedSections[index];
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
    for (NSUInteger i = 0; i < [sections count]; ++i) {
        NSArray <ZBSource *> *section = sections[i];
        for (NSUInteger j = 0; j < [section count]; ++j) {
            ZBSource *source = section[j];
            sourceIndexes[[source baseFilename]] = @((i << 16) | j);
        }
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
    
    if ([destination isKindOfClass:[ZBSourceSectionsListTableViewController class]]) {
        NSIndexPath *indexPath = sender;
        ((ZBSourceSectionsListTableViewController *)destination).source = [self sourceAtIndexPath:indexPath];
    }
}

//I said to myself: "who actually wrote this and named it that." and then i remembered I wrote it
- (void)delewhoop:(NSNotification *)notification {
    ZBSource *source = (ZBSource *)[[notification userInfo] objectForKey:@"source"];
    NSInteger pos = [sourceIndexes[[source baseFilename]] integerValue];
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
        NSLog(@"XXX count %lu", (unsigned long)components.count);
        if ([components count] == 2) {
            // No URL passed in. Just present the prompt.
            [self showAddSourceAlert:nil];
        } else if ([components count] >= 3) {
            // URL passed in. Try and parse a valid URL out of it, and do our best to display the
            // prompt with it. If we can’t parse out a valid URL, we’ll display the prompt anyway
            // with no URL prefilled.
            NSString *urlString = [path componentsSeparatedByString:@"/add/"][1];
            NSLog(@"XXX add %@", urlString);
            NSLog(@"XXX fq: %@", [self _fullyQualifiedURLForInput:urlString]);
            [self showAddSourceAlert:[self _fullyQualifiedURLForInput:urlString]];
        }
    }
}

- (void)handleImportOf:(NSURL *)url {
    ZBSourceImportTableViewController *importController = [[ZBSourceImportTableViewController alloc] initWithPaths:@[url] extension:[url pathExtension]];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:importController];
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Source Verification Delegate

- (void)startedSourceVerification:(BOOL)multiple {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self->verifyPopup) {
            NSString *message = NSLocalizedString(multiple ? @"Verifying Sources" : @"Verifying Source", @"");
            self->verifyPopup = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please Wait…", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
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

                [errorPopup addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];

                UIAlertAction *editAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Edit", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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

- (void)scrollToTop {
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

@end
