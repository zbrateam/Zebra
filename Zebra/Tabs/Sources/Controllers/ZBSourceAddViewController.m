//
//  ZBSourceAddViewController.m
//  Zebra
//
//  Created by Wilson Styres on 6/1/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourceAddViewController.h"
#import <Sources/Helpers/ZBBaseSource.h>
#import "ZBSourceTableViewCell.h"
@import SDWebImage;

@interface ZBSourceAddViewController () {
    UISearchController *searchControlller;
    NSMutableArray <ZBBaseSource *> *sources;
    NSArray <ZBBaseSource *> *filteredSources;
    BOOL searchTermIsEmpty;
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
        searchControlller.searchBar.placeholder = @"Source Name or URL";
        searchControlller.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        searchTermIsEmpty = YES;
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
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([ZBSourceTableViewCell class]) bundle:nil] forCellReuseIdentifier:@"SourceTableViewCell"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    searchControlller.active = YES;
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return searchTermIsEmpty ? 1 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (searchTermIsEmpty) {
        return 0;
    } else {
        return section == 0 ? 1 : filteredSources.count;
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSourceTableViewCell *cell = (ZBSourceTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"SourceTableViewCell" forIndexPath:indexPath];

    NSString *searchTerm = searchControlller.searchBar.text;
    if (indexPath.section == 0) {
        cell.urlLabel.text = searchTerm;
        cell.sourceLabel.hidden = YES;
    }
    else {
        ZBBaseSource *source = filteredSources[indexPath.row];
        cell.sourceLabel.text = source.label;
        cell.urlLabel.text = source.repositoryURI;
        [cell.iconImageView sd_setImageWithURL:source.iconURL placeholderImage:[UIImage imageNamed:@"Unknown"]];
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
        searchTermIsEmpty = YES;
    }
    else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"repositoryURI contains[c] %@ OR label contains[c] %@", term, term];
        filteredSources = [sources filteredArrayUsingPredicate:predicate];
        searchTermIsEmpty = NO;
    }
    
    [self.tableView reloadData];
}

@end
