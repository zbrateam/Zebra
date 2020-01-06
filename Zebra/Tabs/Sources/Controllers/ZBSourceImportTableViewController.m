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
#import <Sources/Helpers/ZBSourceManager.h>
#import <Sources/Views/ZBRepoTableViewCell.h>
#import <UIColor+GlobalColors.h>

@interface ZBSourceImportTableViewController ()
@property NSArray <ZBBaseSource *> *baseSources;
@property NSMutableDictionary <NSString *, NSNumber *> *sources;
@property NSMutableDictionary <NSString *, NSString *> *titles;
@property NSMutableDictionary <NSString *, NSNumber *> *selectedSources;
@property ZBSourceManager *sourceManager;
@end

@implementation ZBSourceImportTableViewController

@synthesize baseSources;
@synthesize sourceFilesToImport;
@synthesize sources;
@synthesize titles;
@synthesize sourceManager;
@synthesize selectedSources;

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
    
    UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    [activityView sizeToFit];
    activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)];
    
    UIBarButtonItem *loadingView = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    [self.navigationItem setRightBarButtonItem:loadingView];
    [activityView startAnimating];

    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRepoTableViewCell" bundle:nil] forCellReuseIdentifier:@"repoTableViewCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (baseSources == NULL || sources == NULL || titles == NULL) {
        [self processSourcesFromLists];
        
        dispatch_async(dispatch_get_main_queue(), ^{
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
    ZBSourceVerification status = [[sources objectForKey:[source baseFilename]] integerValue];
    
    cell.repoLabel.alpha = 1.0;
    cell.urlLabel.alpha = 1.0;
    cell.repoLabel.textColor = [UIColor cellPrimaryTextColor];
    [cell setSpinning:false];
    switch (status) {
        case ZBSourceExists: {
            if ([selectedSources objectForKey:[source baseFilename]]) {
                BOOL selected = [[selectedSources objectForKey:[source baseFilename]] boolValue];
                if (selected) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
            else {
                [selectedSources setObject:@YES forKey:[source baseFilename]];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            break;
        }
        case ZBSourceUnverified:
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            cell.repoLabel.alpha = 0.7;
            cell.urlLabel.alpha = 0.7;
            break;
        case ZBSourceImaginary: {
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            cell.repoLabel.textColor = [UIColor systemPinkColor];
            break;
        }
        case ZBSourceVerifying:
            [cell setSpinning:true];
            
            cell.repoLabel.alpha = 0.7;
            cell.urlLabel.alpha = 0.7;
            break;
    }
    
    cell.repoLabel.text = [self.titles objectForKey:[source baseFilename]];
    cell.urlLabel.text = source.repositoryURI;
    
    [cell.iconImageView sd_setImageWithURL:[[source mainDirectoryURL] URLByAppendingPathComponent:@"CydiaIcon.png"] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    
    return cell;
}

- (void)updateCellForSource:(ZBBaseSource *)source {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger index = [self->baseSources indexOfObject:source];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    });
}

#pragma mark - Processing Sources

- (void)processSourcesFromLists {
    sources = [NSMutableDictionary new];
    titles = [NSMutableDictionary new];
    sourceManager = [ZBSourceManager sharedInstance];
    
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

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (ZBBaseSource *source in self->baseSources) {
            [self->sources setObject:@(ZBSourceUnverified) forKey:[source baseFilename]];
            [self->titles setObject:NSLocalizedString(@"Verifying...", @"") forKey:[source baseFilename]];
        }
        
        [self->sourceManager verifySources:self->baseSources delegate:self];
    });
}

#pragma mark - Verification Delegate

- (void)source:(ZBBaseSource *)source status:(ZBSourceVerification)verified {
    [self->sources setObject:@(verified) forKey:[source baseFilename]];
    if (verified == ZBSourceExists) {
        [source getLabel:^(NSString * _Nonnull label) {
            if (!label) {
                label = source.repositoryURI;
            }
            
            [self->titles setObject:label forKey:[source baseFilename]];
            [self updateCellForSource:source];
        }];
    }
    else if (verified == ZBSourceImaginary) {
        [self->titles setObject:@"Unable to verify source" forKey:[source baseFilename]];
        [self updateCellForSource:source];
    }
}

@end
