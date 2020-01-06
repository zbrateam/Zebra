//
//  ZBSourceImportTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/5/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SDWebImage;

#import "ZBSourceImportTableViewController.h"

#import <Sources/Helpers/ZBBaseSource.h>
#import <Sources/Views/ZBRepoTableViewCell.h>

@interface ZBSourceImportTableViewController ()
@property NSArray <ZBBaseSource *> *baseSources;
@end

@implementation ZBSourceImportTableViewController

@synthesize sourceFilesToImport;
@synthesize baseSources;

#pragma mark - Initializers

- (id)initWithSourceFiles:(NSArray <NSURL *> *)filePaths {
    self = [super init];
    
    if (self) {
        self.sourceFilesToImport = filePaths;
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.titleView = spinner;
    [spinner startAnimating];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRepoTableViewCell" bundle:nil] forCellReuseIdentifier:@"repoTableViewCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (baseSources == NULL) {
        NSMutableSet *baseSourcesSet = [NSMutableSet new];
        
        for (NSURL *sourcesLocation in sourceFilesToImport) {
            NSError *error;
            [baseSourcesSet unionSet:[ZBBaseSource baseSourcesFromList:sourcesLocation error:&error]];
            
            if (error) {
                break;
            }
        }
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"repositoryURI" ascending:YES];
        baseSources = [[baseSourcesSet allObjects] sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.titleView = NULL;
            self.navigationItem.title = NSLocalizedString(@"Import Sources", @"");
            
            [self.tableView reloadData];
        });
    }
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sourceFilesToImport count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [baseSources count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBRepoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell"];
    if (!cell) {
        cell = (ZBRepoTableViewCell *)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"repoTableViewCell"];
    }
    
    ZBBaseSource *source = [baseSources objectAtIndex:indexPath.row];

    [cell verifyAndSetLabel:source];
    cell.urlLabel.text = source.repositoryURI;
    
    [cell.iconImageView sd_setImageWithURL:[[source mainDirectoryURL] URLByAppendingPathComponent:@"CydiaIcon.png"] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    
    return cell;
}

#pragma mark - Processing Sources

@end
