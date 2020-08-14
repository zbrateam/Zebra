//
//  ZBSourceAddViewController.m
//  Zebra
//
//  Created by Wilson Styres on 6/1/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourceAddViewController.h"
#import <Database/ZBDatabaseManager.h>
#import <Sources/Helpers/ZBBaseSource.h>
#import <Sources/Helpers/ZBSourceManager.h>
#import "ZBSourceTableViewCell.h"
#import <Extensions/UIColor+GlobalColors.h>
@import SDWebImage;

@interface ZBSourceAddViewController () {
    UIViewController *delegate;
    UISearchController *searchController;
    NSArray *addedSources;
    NSMutableArray <ZBBaseSource *> *sources;
    NSMutableArray <ZBBaseSource *> *selectedSources;
    NSArray <ZBBaseSource *> *filteredSources;
    BOOL searchTermIsEmpty;
    BOOL searchTermIsURL;
    ZBBaseSource *enteredSource;
}
@end

@implementation ZBSourceAddViewController

#pragma mark - Initializers

- (id)initWithDelegate:(UIViewController *)delegate {
    self = [super init];
    
    if (self) {
        self.title = @"Add Sources";
        self.definesPresentationContext = YES;
        self->delegate = delegate;
        
        searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.obscuresBackgroundDuringPresentation = NO;
        searchController.hidesNavigationBarDuringPresentation = NO;
        searchController.searchResultsUpdater = self;
        searchController.delegate = self;
        searchController.searchBar.placeholder = @"Source Name or URL";
        searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchController.searchBar.showsCancelButton = NO;
        
        searchTermIsEmpty = YES;
        searchTermIsURL = NO;
        [self downloadSources];
    }
    
    return self;
}

- (void)downloadSources {
    if (!sources) sources = [NSMutableArray new];
    if (!filteredSources) filteredSources = [NSMutableArray new];
    if (!selectedSources) selectedSources = [NSMutableArray new];
    if (!addedSources) addedSources = [[[ZBSourceManager sharedInstance] sources] allObjects];
    
    NSURL *url = [NSURL URLWithString:@"https://api.ios-repo-updates.com/1.0/repositories/"];
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *JSONError;
        NSDictionary *fullJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONError];
        NSArray *repos = [fullJSON objectForKey:@"repositories"];
        
        for (NSDictionary *repo in repos) {
            NSURL *URL = [NSURL URLWithString:repo[@"url"]];
            if (URL) {
                ZBBaseSource *baseSource = [[ZBBaseSource alloc] initFromURL:URL];
                [baseSource setLabel:repo[@"name"]];
                [baseSource setVerificationStatus:ZBSourceExists];
                
                [self->sources addObject:baseSource];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
    
    [dataTask resume];
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
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([ZBSourceTableViewCell class]) bundle:nil] forCellReuseIdentifier:@"SourceTableViewCell"];
    
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    searchController.active = YES;
}

- (void)dismiss {
    searchController.active = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Adding Sources

- (void)addSelectedSources {
    ZBSourceManager *sourceManager = [ZBSourceManager sharedInstance];
    
    NSSet *sourcesToAdd = [NSSet setWithArray:selectedSources];
    [sourceManager addBaseSources:sourcesToAdd];
    [[ZBDatabaseManager sharedInstance] updateSources:sourcesToAdd useCaching:YES];
    
    [self dismiss];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return searchTermIsEmpty || !searchTermIsURL ? 1 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (searchTermIsEmpty) {
        return 0;
    } else if (section == 0 && searchTermIsURL) {
        return 1;
    } else {
        return filteredSources.count;
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSourceTableViewCell *cell = (ZBSourceTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"SourceTableViewCell" forIndexPath:indexPath];

    if (indexPath.section == 0 && searchTermIsURL) {
        if (enteredSource) {
            if ([addedSources containsObject:enteredSource]) {
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
                cell.sourceLabel.text = enteredSource.label;
                cell.urlLabel.text = enteredSource.repositoryURI;
                [cell.iconImageView sd_setImageWithURL:enteredSource.iconURL placeholderImage:[UIImage imageNamed:@"Unknown"]];
            }
        }
    }
    else {
        ZBBaseSource *source = filteredSources[indexPath.row];
        if ([addedSources containsObject:(ZBSource *)source]) {
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
        cell.sourceLabel.text = source.label;
        cell.urlLabel.text = source.repositoryURI;
        [cell.iconImageView sd_setImageWithURL:source.iconURL placeholderImage:[UIImage imageNamed:@"Unknown"]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0 && enteredSource) {
        if (![addedSources containsObject:enteredSource] && enteredSource.verificationStatus == ZBSourceExists) {
            if ([selectedSources containsObject:enteredSource]) {
                [selectedSources removeObject:enteredSource];
            } else {
                [selectedSources addObject:enteredSource];
            }
        }
    } else {
        ZBBaseSource *source = filteredSources[indexPath.row];
        if (![addedSources containsObject:source]) {
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
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"repositoryURI contains[c] %@ OR label contains[c] %@", term, term];
        filteredSources = [sources filteredArrayUsingPredicate:predicate];
        searchTermIsEmpty = NO;
        enteredSource = NULL;
        
        NSURL *enteredURL = [self searchAsURL];
        NSPredicate *doubleCheck = [NSPredicate predicateWithFormat:@"repositoryURI = %@", enteredURL.absoluteString];
        if (enteredURL && [sources filteredArrayUsingPredicate:doubleCheck].count == 0) {
            searchTermIsURL = YES;
            
            ZBBaseSource *newEnteredSource = [[ZBBaseSource alloc] initFromURL:enteredURL];
            if (newEnteredSource) {
                enteredSource = newEnteredSource;
                [newEnteredSource verify:^(ZBSourceVerificationStatus status) {
                    if ([newEnteredSource isEqual:self->enteredSource]) {
                        if (status == ZBSourceExists) {
                            self->enteredSource = newEnteredSource;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.tableView beginUpdates];
                                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                                [self.tableView endUpdates];
                            });
                            
                            [self->enteredSource getLabel:^(NSString * _Nonnull label) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.tableView beginUpdates];
                                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                                    [self.tableView endUpdates];
                                });
                            }];
                        }
                        else if (status == ZBSourceImaginary) {
                            self->enteredSource = NULL;
                            self->searchTermIsURL = NO;
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.tableView beginUpdates];
                                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
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

@end
