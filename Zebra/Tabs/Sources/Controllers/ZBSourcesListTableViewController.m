//
//  ZBSourceListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 9/7/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSourcesListTableViewController.h"

#import <ZBAppDelegate.h>
#import <Extensions/UIColor+Zebra.h>
#import <Tabs/Sources/Helpers/ZBSource.h>
#import <Tabs/Sources/Helpers/ZBSourceManager.h>

#import <Tabs/ZBTabBarController.h>
#import <Tabs/Sources/Cells/ZBSourceTableViewCell.h>

#import <Database/ZBRefreshViewController.h>
#import <Tabs/Sources/Controllers/ZBRepoSectionsListTableViewController.h>

@interface ZBSourcesListTableViewController () {
    BOOL askedToAddFromClipboard;
    BOOL isRefreshing;
    NSString *lastPaste;
}
@end

@implementation ZBSourcesListTableViewController

@synthesize sourceManager;
@synthesize baseFileNameMap;
@synthesize sources;

#pragma mark - Controller Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect frame = [[UIScreen mainScreen] bounds];
    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(16, 0, frame.size.width - 32, 0.5)];
    bar.backgroundColor = [UIColor colorWithRed:204/255.f green:204/255.f blue:204/255.f alpha:1.0];
    [self.view addSubview:bar];
    
    sourceManager = [ZBSourceManager sharedInstance];
    sources = [[self.databaseManager sources] mutableCopy];
    [self drawSourceMap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (SYSTEM_VERSION_LESS_THAN(@"13.0")) {
        //From: https://stackoverflow.com/a/48837322
        UIVisualEffectView *fxView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        fxView.backgroundColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:0.60];
        [fxView setFrame:CGRectOffset(CGRectInset(self.navigationController.navigationBar.bounds, 0, -12), 0, -60)];
        [self.navigationController.navigationBar setTranslucent:YES];
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar insertSubview:fxView atIndex:1];
    }
    
    [self registerForNotifications];
    [self layoutNavigationButtons];
}

- (void)registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkClipboard) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBDatabaseCompletedUpdate" object:nil];
}

- (void)dealloc { //Remove ourselves from receiving notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBDatabaseCompletedUpdate" object:nil];
}

#pragma mark - Data Source

- (void)refreshTable {
    if (isRefreshing) return;
    
    sources = [[self.databaseManager sources] mutableCopy];
    [self drawSourceMap];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->isRefreshing = YES;
        [self.tableView reloadData];
        self->isRefreshing = NO;
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [sources count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSourceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sourceTableCell" forIndexPath:indexPath];
    ZBSource *source = [sources objectAtIndex:indexPath.row];
    
    [cell updateData:source];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSource *source = [sources objectAtIndex:indexPath.row];
    
    return [source canDelete];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.sourceManager deleteSource:[sources objectAtIndex:indexPath.row]];
        [sources removeObjectAtIndex:indexPath.row];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.editing) {
        ZBSource *source = [sources objectAtIndex:indexPath.row];

        ZBRepoSectionsListTableViewController *sectionsController = [[ZBRepoSectionsListTableViewController alloc] init];
        sectionsController.repo = source;

        [[self navigationController] pushViewController:sectionsController animated:true];
    }
    else if (![self tableView:tableView canEditRowAtIndexPath:indexPath]) {
        [tableView deselectRowAtIndexPath:indexPath animated:true];
    }
}

#pragma mark - Table View Layout

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 69;
}

#pragma mark - Navigation Buttons

- (void)layoutNavigationButtons {
    if (self.refreshControl.refreshing) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelRefresh:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        self.navigationItem.rightBarButtonItem = nil;
    }
    else {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        if (self.isEditing) {
            UIBarButtonItem *exportButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(exportSources:)];
            UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteSelected:)];
            self.navigationItem.leftBarButtonItems = @[exportButton, deleteButton];
        }
        else {
            UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAddSourcePopup:)];
            self.navigationItem.leftBarButtonItems = @[addButton];
        }
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self layoutNavigationButtons];
}

- (void)cancelRefresh:(id)sender {
    
}

- (void)exportSources:(id)sender {
    NSURL *sourcesList = [ZBAppDelegate sourcesListURL];
    UIActivityViewController *shareSheet = [[UIActivityViewController alloc] initWithActivityItems:@[sourcesList] applicationActivities:nil];
    shareSheet.popoverPresentationController.barButtonItem = self.navigationItem.leftBarButtonItems[0];
    [self presentViewController:shareSheet animated:YES completion:nil];
}

- (void)showAddSourcePopup:(id)sender {
    [self presentViewController:[self addSourcePopup] animated:YES completion:nil];
}

- (void)deleteSelected:(id)sender {
    NSSortDescriptor *rowDescriptor = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:NO];
    NSArray *indexPaths = [[self.tableView indexPathsForSelectedRows] sortedArrayUsingDescriptors:@[rowDescriptor]];
    for (NSIndexPath *indexPath in indexPaths) {
        [self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
    }
}

#pragma mark - UIAlertControllers

- (UIAlertController *)addSourcePopup {
    return [self addSourcePopupWithPlaceholder:NULL];
}

- (UIAlertController *)addSourcePopupWithPlaceholder:(NSURL *_Nullable)url {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter URL" message:nil preferredStyle:UIAlertControllerStyleAlert];
    alertController.view.tintColor = [UIColor tintColor];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *sourceURLString = alertController.textFields[0].text;
        
        [self addSourceURLFromString:sourceURLString];
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
    
    return alertController;
}

- (UIAlertController *)addRepoFromClipboardPopup:(NSURL *_Nonnull)sourceURL {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Would you like to add the URL from your clipboard?" message:sourceURL.absoluteString preferredStyle:UIAlertControllerStyleAlert];
    alertController.view.tintColor = [UIColor tintColor];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self addSourceURL:sourceURL];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
    
    return alertController;
}

#pragma mark - Clipboard

- (void)checkClipboard {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSURL *url = [NSURL URLWithString:pasteboard.string];
    NSArray *urlBlacklist = @[@"youtube.com", @"google.com", @"reddit.com", @"twitter.com", @"facebook.com", @"imgur.com", @"discord.com", @"discord.gg"];
    
    NSMutableArray *currentSourceURLs = [NSMutableArray new];
    for (ZBSource *source in sources) {
        if (source.secure) {
            [currentSourceURLs addObject:[[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", source.baseURL]] host]];
        }
        else {
            [currentSourceURLs addObject:[[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", source.baseURL]] host]];
        }
    }
    
    if ((url && url.scheme && url.host)) {
        if ([[url scheme] isEqual:@"https"] || [[url scheme] isEqual:@"http"]) {
            if (!askedToAddFromClipboard || ![lastPaste isEqualToString:pasteboard.string]) {
                if (![urlBlacklist containsObject:url.host] && ![currentSourceURLs containsObject:url.host]) {
                    [self presentViewController:[self addRepoFromClipboardPopup:url] animated:true completion:nil];
                }
            }
            askedToAddFromClipboard = YES;
            lastPaste = pasteboard.string;
        }
    }
}

#pragma mark - Adding a Source

- (void)addSourceURL:(NSURL *)sourceURL {
    [self addSourceURLFromString:[sourceURL absoluteString]];
}

- (void)addSourceURLFromString:(NSString *)sourceURLString {
    UIAlertController *wait = [UIAlertController alertControllerWithTitle:@"Please Wait..." message:@"Verifying Source(s)" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:wait animated:YES completion:nil];
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(ZBSourceManager *) sourceManager = self->sourceManager;
    
    [sourceManager addSourcesFromString:sourceURLString response:^(BOOL success, NSString * _Nonnull error, NSArray<NSURL *> * _Nonnull failedURLs) {
        [weakSelf dismissViewControllerAnimated:YES completion:^{
            if (!success) {
                UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:error preferredStyle:UIAlertControllerStyleAlert];
                
                if (failedURLs.count) {
                    UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [weakSelf addSourceURLFromString:sourceURLString];
                    }];
                    
                    [errorAlert addAction:retryAction];
                    
                    UIAlertAction *editAction = [UIAlertAction actionWithTitle:@"Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        if ([failedURLs count] > 1) {
                            //Show add multi controller
                        }
                        else {
                            NSURL *failedURL = [failedURLs[0] URLByDeletingLastPathComponent];
                            
                            [weakSelf presentViewController:[weakSelf addSourcePopupWithPlaceholder:failedURL] animated:true completion:nil];
                        }
                    }];
                    
                    [errorAlert addAction:editAction];
                }
                
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                
                [errorAlert addAction:cancelAction];
                
                [weakSelf presentViewController:errorAlert animated:YES completion:nil];
            }
            else {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                ZBRefreshViewController *console = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
                
                console.repoURLs = [sourceManager verifiedURLs];
                [weakSelf presentViewController:console animated:YES completion:nil];
            }
        }];
    }];
}

#pragma mark - UI Updates

- (void)drawSourceMap {
    if (![sources count]) return;
    
    NSMutableArray *map = [NSMutableArray new];
    for (ZBSource *source in sources) {
        [map addObject:[source baseFileName]];
    }
    
    self.baseFileNameMap = (NSArray *)map;
}

- (BOOL)setSpinnerVisible:(BOOL)visible forCell:(ZBSourceTableViewCell *)cell {
    return [cell setSpinning:visible];
}

- (BOOL)setSpinnerVisible:(BOOL)visible forBaseFileName:(NSString *)baseFileName {
    __block ZBSourceTableViewCell *cell;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger cellPosition = [[self baseFileNameMap] indexOfObject:baseFileName];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:cellPosition inSection:0];
        cell = (ZBSourceTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    });
    
    return [self setSpinnerVisible:visible forCell:cell];
}

- (void)clearAllSpinners {
    dispatch_async(dispatch_get_main_queue(), ^{
        [((ZBTabBarController *)self.tabBarController).repoBusyList removeAllObjects];
        [self.tableView reloadData];
    });
}

#pragma mark - URL Handling

- (void)handleURL:(NSURL *)url {
    NSString *path = [url path];
    
    if (![path isEqualToString:@""]) {
        NSArray *components = [path pathComponents];
        if ([components count] == 2) {
            [self presentViewController:[self addSourcePopup] animated:true completion:nil];
        } else if ([components count] >= 4) {
            NSString *urlString = [path componentsSeparatedByString:@"/add/"][1];
            
            NSURL *url;
            if ([urlString containsString:@"https://"] || [urlString containsString:@"http://"]) {
                url = [NSURL URLWithString:urlString];
            } else {
                url = [NSURL URLWithString:[@"https://" stringByAppendingString:urlString]];
            }
            
            if (url && url.scheme && url.host) {
                [self presentViewController:[self addSourcePopupWithPlaceholder:url] animated:true completion:nil];
            } else {
                [self presentViewController:[self addSourcePopup] animated:true completion:nil];
            }
        }
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
            [self->sourceManager mergeSourcesFrom:url into:[ZBAppDelegate sourcesListURL] completion:^(NSError * _Nonnull error) {
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
            [self->sourceManager mergeSourcesFrom:url into:[ZBAppDelegate sourcesListURL] completion:^(NSError * _Nonnull error) {
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

@end
