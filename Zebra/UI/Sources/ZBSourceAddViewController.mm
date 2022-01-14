//
//  ZBSourceAddViewController.m
//  Zebra
//
//  Created by Wilson Styres on 6/1/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourceAddViewController.h"
#import <WebKit/WebKit.h>

#import <UI/Sources/ZBSourceImportViewController.h>
#import <UI/Sources/ZBSourceBulkAddViewController.h>

#import <Model/ZBDummySource.h>

#import "Zebra-Swift.h"
#import <ZBDevice.h>

#import <Plains/Plains.h>
#import <SDWebImage/SDWebImage.h>

@interface ZBSourceAddViewController () {
    UISearchController *searchController;
    NSMutableSet <NSString *> *addedSourcesUUIDs;
    NSArray <ZBDummySource *> *sources;
    NSMutableArray <ZBDummySource *> *selectedSources;
    NSArray <ZBDummySource *> *filteredSources;
    BOOL clipboardHasSource;
    BOOL searchTermIsEmpty;
    BOOL searchTermIsURL;
    BOOL importExpanded;
    ZBDummySource *enteredSource;
    ZBDummySource *clipboardSource;
    NSArray *managers;
}
@end

@implementation ZBSourceAddViewController

#pragma mark - Initializers

- (id)init {
    self = [super init];
    
    if (self) {
        self.title = @"Add Sources";
        self.definesPresentationContext = YES;
        
        searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.obscuresBackgroundDuringPresentation = NO;
        searchController.hidesNavigationBarDuringPresentation = NO;
        searchController.searchResultsUpdater = self;
        searchController.delegate = self;
        searchController.searchBar.placeholder = @"Source Name or URL";
        searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchController.searchBar.showsCancelButton = NO;
        searchController.searchBar.showsBookmarkButton = YES;
        searchController.searchBar.delegate = self;
        if (@available(iOS 13.0, *)) {
            [searchController.searchBar setImage:[UIImage systemImageNamed:@"paperclip.circle"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
        } else {
            [searchController.searchBar setImage:[UIImage imageNamed:@"Unknown"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
        }
        
        searchTermIsEmpty = YES;
        searchTermIsURL = NO;
        clipboardHasSource = NO;
        [self downloadSources];
    }
    
    return self;
}

- (id)initWithURL:(NSURL *)url {
    self = [self init];
    
    if (self && url) {
        searchController.searchBar.text = [url absoluteString];
    }
    
    return self;
}

#pragma mark - Fetching Sources

- (void)downloadSources {
    if (!sources) sources = [NSMutableArray new];
    if (!filteredSources) filteredSources = [NSMutableArray new];
    if (!selectedSources) selectedSources = [NSMutableArray new];
    if (!addedSourcesUUIDs) addedSourcesUUIDs = [NSMutableSet new];
    for (PLSource *source in [[PLSourceManager sharedInstance] sources]) {
        [addedSourcesUUIDs addObject:source.UUID];
    }
    if (!managers) managers = [self loadManagers];

    #if TARGET_OS_MACCATALYST
    return;
    #endif

    __weak ZBSourceAddViewController *weakSelf = self;
    [[ZBCanister shared] fetchRepos:^{
        if (!weakSelf)
            return;
        ZBSourceAddViewController *strong = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            strong->sources = [[ZBCanister shared] repos];
            [self.tableView reloadData];
        });
        
    }];
}

- (NSArray *)loadManagers {
#if TARGET_OS_MACCATALYST
    return NULL;
#else
    NSMutableArray *result = [NSMutableArray new];
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Application Support/xyz.willy.Zebra/sources.list"]) {
        NSDictionary *dict4 = @{@"name" : @"Zebra 1.x",
                               @"label": [NSString stringWithFormat:NSLocalizedString(@"Transfer sources from %@ to Zebra 2.x", @""), @"Zebra 1.x"],
                               @"url"  : @"file:///var/mobile/Library/Application Support/xyz.willy.Zebra/sources.list",
                               @"ext"  : @"list",
                               @"icon" : @"file:///Applications/Zebra.app/AppIcon60x60@2x.png"};
        [result addObject:dict4];
    }
    return result;
#endif
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.searchController = searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", @"") style:UIBarButtonItemStyleDone target:self action:@selector(addSelectedSources)];
    addButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = addButton;
    
    [self.tableView registerClass:[ZBSourceTableViewCell class] forCellReuseIdentifier:@"SourceTableViewCell"];
    
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self checkPasteboard:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    searchController.active = YES;
}

- (void)checkPasteboard:(BOOL)checked {
    if (!checked) {
        if (@available(iOS 14.0, *)) {
            [[UIPasteboard generalPasteboard] detectPatternsForPatterns:[NSSet setWithObject:UIPasteboardDetectionPatternProbableWebURL] completionHandler:^(NSSet<UIPasteboardDetectionPattern> * _Nullable patterns, NSError * _Nullable error) {
                if (!error && [patterns containsObject:UIPasteboardDetectionPatternProbableWebURL]) {
                    [self checkPasteboard:YES];
                }
            }];
        } else {
            [self checkPasteboard:YES];
        }
    }
    
    if (checked) {
        NSURL *potentialSourceURL = [[UIPasteboard generalPasteboard] URL];
        if (!potentialSourceURL) potentialSourceURL = [NSURL URLWithString:[[UIPasteboard generalPasteboard] string]];
        ZBDummySource *potentialBaseSource = [[ZBDummySource alloc] initWithURL:potentialSourceURL];
        if (potentialBaseSource) {
            self->clipboardSource = potentialBaseSource;
            self->clipboardHasSource = YES;
            [potentialBaseSource verify:^(ZBSourceVerificationStatus status) {
                if (status == ZBSourceExists) {
                    self->clipboardSource = potentialBaseSource;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                    });
                    
                    [self->clipboardSource getOrigin:^(NSString * _Nonnull label) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                        });
                    }];
                }
                else if (status == ZBSourceImaginary) {
                    self->clipboardSource = NULL;
                    self->clipboardHasSource = NO;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                    });
                }
            }];
        } else {
            self->clipboardHasSource = NO;
            self->clipboardSource = NULL;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        });
    }
}

- (void)dismiss {
    searchController.active = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Adding Sources

- (void)addSelectedSources {
    PLSourceManager *sourceManager = [PLSourceManager sharedInstance];
    for (ZBDummySource *source in selectedSources) {
        [sourceManager addSourceWithArchiveType:source.archiveType repositoryURI:source.repositoryURI distribution:source.distribution components:source.components];
    }
    
    [self dismiss];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return searchTermIsEmpty ? clipboardHasSource : 0;
        case 1:
            return searchTermIsEmpty && managers.count ? importExpanded ? managers.count + 1 : 1 : 0;
        case 2:
            return searchTermIsURL;
        case 3: {
            return !searchTermIsEmpty ? filteredSources.count : 0;
        }
        default:
            return 0;
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSourceTableViewCell *cell = (ZBSourceTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"SourceTableViewCell" forIndexPath:indexPath];

    if (indexPath.section == 0 && searchTermIsEmpty && clipboardSource) {
        if ([addedSourcesUUIDs containsObject:clipboardSource.UUID]) {
            [cell setDisabled:YES];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            [cell setDisabled:NO];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        if (clipboardSource.verificationStatus == ZBSourceVerifying || clipboardSource.verificationStatus == ZBSourceUnverified) {
            [cell setSpinning:YES];
            cell.urlLabel.text = clipboardSource.origin;
            cell.sourceLabel.hidden = YES;
            cell.iconImageView.image = nil;
        }
        else if (clipboardSource.verificationStatus == ZBSourceExists) {
            if ([selectedSources containsObject:clipboardSource]) cell.accessoryType = UITableViewCellAccessoryCheckmark;

            [cell setSpinning:NO];
            cell.sourceLabel.hidden = NO;
            cell.sourceLabel.text = clipboardSource.origin;
            cell.urlLabel.text = NSLocalizedString(@"From your clipboard", @"");
            [cell.iconImageView sd_setImageWithURL:clipboardSource.iconURL placeholderImage:[UIImage imageNamed:@"Unknown"]];
        }
    } else if (indexPath.section == 1 && searchTermIsEmpty) {
        if (indexPath.row == 0) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"importSectionHeader"];
            
            cell.textLabel.text = NSLocalizedString(@"Transfer Sources", @"");
            cell.textLabel.font = [UIFont systemFontOfSize:cell.textLabel.font.pointSize weight:UIFontWeightSemibold];
            if (@available(iOS 13.0, *)) {
                cell.accessoryView =  [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:importExpanded ? @"chevron.up" : @"chevron.down"]];
            } else {
                // FIXME: Fallback on earlier versions
            }
            cell.accessoryView.tintColor = [UIColor tertiaryLabelColor];
            
            return cell;
        } else if (importExpanded) {
            NSDictionary *manager = managers[indexPath.row - 1];
            
            cell.sourceLabel.hidden = NO;
            cell.sourceLabel.text = manager[@"name"];
            cell.urlLabel.text = manager[@"label"];
            [cell.iconImageView sd_setImageWithURL:[NSURL URLWithString:manager[@"icon"]] placeholderImage:[UIImage imageNamed:@"Unknown"]];
        }
    } else if (indexPath.section == 2 && searchTermIsURL) {
        if (enteredSource) {
            if ([addedSourcesUUIDs containsObject:enteredSource.UUID]) {
                [cell setDisabled:YES];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else {
                [cell setDisabled:NO];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            if (enteredSource.verificationStatus == ZBSourceVerifying || enteredSource.verificationStatus == ZBSourceUnverified) {
                [cell setSpinning:YES];
                cell.urlLabel.text = [self searchAsURL].absoluteString;
                cell.sourceLabel.hidden = YES;
                cell.iconImageView.image = nil;
            }
            else if (enteredSource.verificationStatus == ZBSourceExists) {
                if ([selectedSources containsObject:enteredSource]) cell.accessoryType = UITableViewCellAccessoryCheckmark;

                [cell setSpinning:NO];
                cell.sourceLabel.hidden = NO;
                cell.sourceLabel.text = enteredSource.origin;
                cell.urlLabel.text = enteredSource.repositoryURI;
                [cell.iconImageView sd_setImageWithURL:enteredSource.iconURL placeholderImage:[UIImage imageNamed:@"Unknown"]];
            }
        }
    } else if (indexPath.section == 3) {
        ZBDummySource *source = filteredSources[indexPath.row];
        if ([addedSourcesUUIDs containsObject:source.UUID]) {
            [cell setDisabled:YES];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else if ([selectedSources containsObject:source]) {
            [cell setDisabled:NO];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            [cell setDisabled:NO];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        cell.sourceLabel.hidden = NO;
        cell.sourceLabel.text = source.origin;
        cell.urlLabel.text = source.repositoryURI;
        
        [cell.iconImageView sd_setImageWithURL:source.iconURL placeholderImage:[UIImage imageNamed:@"Unknown"]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0 && searchTermIsEmpty && clipboardHasSource) {
        if (![addedSourcesUUIDs containsObject:clipboardSource.UUID] && clipboardSource.verificationStatus == ZBSourceExists) {
            if ([selectedSources containsObject:clipboardSource]) {
                [selectedSources removeObject:clipboardSource];
            } else {
                [selectedSources addObject:clipboardSource];
            }
        }
    } else if (indexPath.section == 1 && searchTermIsEmpty) {
        if (indexPath.row == 0) {
            importExpanded = !importExpanded;

            NSMutableArray *indexPaths = [NSMutableArray new];
            for (int i = 0; i < managers.count; i++) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i + 1 inSection:1]];
            }

            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (importExpanded) {
                [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            [self.tableView endUpdates];
        } else if (importExpanded) {
            NSDictionary *manager = managers[indexPath.row - 1];
            ZBSourceImportViewController *importController = [[ZBSourceImportViewController alloc] initWithPaths:@[[NSURL URLWithString:manager[@"url"]]] extension:manager[@"ext"]];

            [self.navigationController pushViewController:importController animated:YES];
        }
        return;
    } else if (indexPath.section == 2 && enteredSource) {
        if (![addedSourcesUUIDs containsObject:enteredSource.UUID] && enteredSource.verificationStatus == ZBSourceExists) {
            if ([selectedSources containsObject:enteredSource]) {
                [selectedSources removeObject:enteredSource];
            } else {
                [selectedSources addObject:enteredSource];
            }
        }
    } else if (indexPath.section == 3) {
        ZBDummySource *source = filteredSources[indexPath.row];
        if (![addedSourcesUUIDs containsObject:source.UUID]) {
            if ([selectedSources containsObject:source]) {
                [selectedSources removeObject:source];
            } else {
                [selectedSources addObject:source];
            }
        }
    }

    self.navigationItem.rightBarButtonItem.enabled = selectedSources.count;
    if (selectedSources.count) {
        self.navigationItem.rightBarButtonItem.title = [NSString stringWithFormat:@"Add (%lu)", (unsigned long)selectedSources.count];
    }
    else {
        self.navigationItem.rightBarButtonItem.title = @"Add";
    }

    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (NSURL *)searchAsURL {
    NSString *urlString = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (urlString.length > 0) {
        NSDataDetector *detector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:nil];
        NSTextCheckingResult *result = [detector firstMatchInString:urlString options:0 range:NSMakeRange(0, urlString.length)];
        if (result && result.range.length == urlString.length) {
            if (![urlString hasPrefix:@"https://"] && ![urlString hasPrefix:@"http://"]) {
                urlString = [@"https://" stringByAppendingString:urlString];
            }
            if (![urlString hasSuffix:@"/"]) {
                urlString = [urlString stringByAppendingString:@"/"];
            }
            
            return [NSURL URLWithString:urlString];
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

#pragma mark - UISearchContollerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [searchController.searchBar setShowsCancelButton:NO];
    });
}

- (void)didPresentSearchController:(UISearchController *)searchController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [searchController.searchBar becomeFirstResponder];
    });
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *term = searchController.searchBar.text;
    term = [term stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (term.length == 0) {
        filteredSources = [sources copy];
        searchTermIsEmpty = YES;
        searchTermIsURL = NO;
    }
    else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"repositoryURI contains[c] %@ OR origin contains[c] %@", term, term];
        filteredSources = [sources filteredArrayUsingPredicate:predicate];
        searchTermIsEmpty = NO;
        enteredSource = NULL;

        NSURL *enteredURL = [self searchAsURL];
        NSPredicate *doubleCheck = [NSPredicate predicateWithFormat:@"repositoryURI = %@", enteredURL.absoluteString];
        if (enteredURL && [sources filteredArrayUsingPredicate:doubleCheck].count == 0) {
            searchTermIsURL = YES;

            ZBDummySource *newEnteredSource = [[ZBDummySource alloc] initWithURL:enteredURL];
            if (newEnteredSource) {
                enteredSource = newEnteredSource;
                [newEnteredSource verify:^(ZBSourceVerificationStatus status) {
                    if ([newEnteredSource isEqual:self->enteredSource]) {
                        if (status == ZBSourceExists) {
                            self->enteredSource = newEnteredSource;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.tableView beginUpdates];
                                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
                                [self.tableView endUpdates];
                            });

                            [self->enteredSource getOrigin:^(NSString * _Nonnull label) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.tableView beginUpdates];
                                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
                                    [self.tableView endUpdates];
                                });
                            }];
                        }
                        else if (status == ZBSourceImaginary) {
                            self->enteredSource = NULL;
                            self->searchTermIsURL = NO;

                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.tableView beginUpdates];
                                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
                                [self.tableView endUpdates];
                            });
                        }
                    }
                }];
            }
        } else {
            searchTermIsURL = NO;
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - Search Bar Delegate

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
    ZBSourceBulkAddViewController *bulkAddView = [[ZBSourceBulkAddViewController alloc] init];
    
    [self.navigationController pushViewController:bulkAddView animated:YES];
}

#pragma mark - Keyboard Shortcuts

- (NSArray<UIKeyCommand *> *)keyCommands {
    // escape key
    UIKeyCommand *cancel = [UIKeyCommand keyCommandWithInput:@"\e" modifierFlags:0 action:@selector(dismiss)];
    cancel.discoverabilityTitle = NSLocalizedString(@"Cancel", @"");

    return @[cancel];
}

@end
