//
//  ZBSourceAddViewController.m
//  Zebra
//
//  Created by Wilson Styres on 6/1/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourceAddViewController.h"
#import <Database/ZBRefreshViewController.h>
#import <Sources/Helpers/ZBBaseSource.h>
#import <Sources/Helpers/ZBSourceManager.h>
#import "ZBSourceTableViewCell.h"
@import SDWebImage;

@interface ZBSourceAddViewController () {
    UIViewController *delegate;
    UISearchController *searchControlller;
    NSMutableArray <ZBBaseSource *> *sources;
    NSArray <ZBBaseSource *> *filteredSources;
    BOOL searchTermIsEmpty;
    BOOL searchTermIsURL;
}
@end

@implementation ZBSourceAddViewController

#pragma mark - Initializers

- (id)initWithDelegate:(UIViewController *)delegate {
    self = [super init];
    
    if (self) {
        self.title = @"Add Source";
        self.definesPresentationContext = YES;
        self->delegate = delegate;
        
        searchControlller = [[UISearchController alloc] init];
        searchControlller.obscuresBackgroundDuringPresentation = NO;
        searchControlller.searchResultsUpdater = self;
        searchControlller.delegate = self;
        searchControlller.searchBar.placeholder = @"Source Name or URL";
        searchControlller.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        searchTermIsEmpty = YES;
        searchTermIsURL = NO;
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
        cell.urlLabel.text = [self searchAsURL].absoluteString;
        cell.sourceLabel.hidden = YES;
        cell.iconImageView.image = nil;
    }
    else {
        ZBBaseSource *source = filteredSources[indexPath.row];
        cell.sourceLabel.text = source.label;
        cell.urlLabel.text = source.repositoryURI;
        [cell.iconImageView sd_setImageWithURL:source.iconURL placeholderImage:[UIImage imageNamed:@"Unknown"]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ZBBaseSource *source;
    if (indexPath.section == 0 && searchTermIsURL) {
        source = [[ZBBaseSource alloc] initFromURL:[self searchAsURL]];
    } else {
        source = filteredSources[indexPath.row];
    }
    [[ZBSourceManager sharedInstance] verifySources:[NSSet setWithObject:source] delegate:self];
}

- (NSURL *)searchAsURL {
    NSString *urlString = [searchControlller.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (urlString.length > 0) {
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
}

#pragma mark - ZBSourceVerificationDelegate

- (void)startedSourceVerification:(BOOL)multiple {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)finishedSourceVerification:(NSArray *)existingSources imaginarySources:(NSArray *)imaginarySources {
    if (existingSources.count) {
        [[ZBSourceManager sharedInstance] addBaseSources:[NSSet setWithArray:existingSources]];
        
        NSMutableSet *existing = [NSMutableSet setWithArray:existingSources];
        if (imaginarySources.count) {
            [existing unionSet:[NSSet setWithArray:imaginarySources]];
        }
        
        ZBRefreshViewController *refreshVC = [[ZBRefreshViewController alloc] initWithBaseSources:existing delegate:self];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:^{
                [self->delegate presentViewController:refreshVC animated:YES completion:nil];
            }];
        });
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
        searchTermIsURL = [self searchAsURL] == nil ? NO : YES;
    }
    
    [self.tableView reloadData];
}

@end
