//
//  ZBSourceAddViewController.m
//  Zebra
//
//  Created by Wilson Styres on 6/1/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourceAddViewController.h"

#import <Sources/Helpers/ZBBaseSource.h>

@interface ZBSourceAddViewController () {
    UISearchController *searchControlller;
    NSMutableArray <ZBBaseSource *> *sources;
    NSArray <ZBBaseSource *> *filteredSources;
}
@end

@implementation ZBSourceAddViewController

#pragma mark - Initializers

- (id)init {
    self = [super init];
    
    if (self) {
        self.title = @"Add Source";
        self.definesPresentationContext = YES;
        
        searchControlller = [[UISearchController alloc] init];
        searchControlller.obscuresBackgroundDuringPresentation = NO;
        searchControlller.searchResultsUpdater = self;
        searchControlller.delegate = self;
        searchControlller.searchBar.placeholder = @"Enter a Source Name or URL";
        searchControlller.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        [self downloadSources];
    }
    
    return self;
}

- (void)downloadSources {
    if (!sources) sources = [NSMutableArray new];
    if (!filteredSources) filteredSources = [NSMutableArray new];
    
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
    
    self.navigationItem.searchController = searchControlller;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    searchControlller.active = YES;
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : filteredSources.count;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"sourceCell"];
    
    NSString *searchTerm = searchControlller.searchBar.text;
    if (indexPath.section == 0) {
        cell.textLabel.text = searchTerm;
    }
    else {
        NSString *label = filteredSources[indexPath.row].label;
        NSString *repositoryURI = filteredSources[indexPath.row].repositoryURI;
        
        cell.textLabel.text = label;
        cell.detailTextLabel.text = repositoryURI;
    }
    
    return cell;
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
    if ([[term stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        filteredSources = [sources copy];
    }
    else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"repositoryURI contains[c] %@ OR label contains[c] %@", term, term];
        filteredSources = [sources filteredArrayUsingPredicate:predicate];
    }
    
    [self.tableView reloadData];
}

@end
