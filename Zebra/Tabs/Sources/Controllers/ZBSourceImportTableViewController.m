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
        
        baseSources = [baseSourcesSet allObjects];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.titleView = NULL;
            self.navigationItem.title = NSLocalizedString(@"Import", @"");
            
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
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sourceImportCell"];
    
    ZBBaseSource *source = [baseSources objectAtIndex:indexPath.row];
    
    cell.textLabel.text = source.repositoryURI;
    [cell.imageView sd_setImageWithURL:[[source mainDirectoryURL] URLByAppendingPathComponent:@"CydiaIcon.png"] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    
    return cell;
}

#pragma mark - Processing Sources

@end
