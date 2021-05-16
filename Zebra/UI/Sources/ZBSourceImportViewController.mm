//
//  ZBSourceImportViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/5/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourceImportViewController.h"
#import "ZBAppDelegate.h"

#import <Model/ZBDummySource.h>

#import <Extensions/UINavigationBar+Extensions.h>
#import <Extensions/UIViewController+Extensions.h>
#import <UI/Sources/Views/Cells/ZBSourceTableViewCell.h>
#import <Extensions/ZBColor.h>

#import <Plains/Model/PLSource.h>
#import <Plains/Managers/PLSourceManager.h>
#import <SDWebImage/SDWebImage.h>

@interface ZBSourceImportViewController () {
    double individualIncrement;
    NSUInteger sourcesToVerify;
    PLSourceManager *sourceManager;
}
@property NSArray <ZBDummySource *> *baseSources;
@property NSMutableDictionary <NSString *, NSString *> *titles;
@property NSMutableDictionary <NSString *, NSNumber *> *selectedSources;
@end

@implementation ZBSourceImportViewController

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    
    if (self) {
        if (@available(iOS 13.0, *)) {
            self.modalInPresentation = YES;
        }
        
        _titles = [NSMutableDictionary new];
        _selectedSources = [NSMutableDictionary new];
        _sourceFilesToImport = [NSMutableArray new];
        
        sourceManager = [PLSourceManager sharedInstance];
    }
    
    return self;
}

- (instancetype)initWithPaths:(NSArray <NSURL *> *)filePaths extension:(NSString *)extension {
    self = [self init];
    
    if (self) {
        for (NSURL *url in filePaths) {
            BOOL isDirectory = NO;
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory];
            if (exists && isDirectory) { // If the location is a directory then add each individual file URL
                for (NSString *filename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[url path] error:nil]) {
                    if ([[filename pathExtension] isEqualToString:extension]) {
                        NSURL *fileURL = [url URLByAppendingPathComponent:filename];
                        if (fileURL) [self.sourceFilesToImport addObject:fileURL];
                    }
                }
            }
            else if (exists && [[url pathExtension] isEqualToString:extension]) {
                [self.sourceFilesToImport addObject:url];
            }
        }
    }
    
    return self;
}

- (instancetype)initWithPaths:(NSArray <NSURL *> *)filePaths {
    return [self initWithPaths:filePaths extension:@"list"];
}

- (instancetype)initWithSources:(NSSet <ZBDummySource *> *)sources {
    self = [self init];
    
    if (self) {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"repositoryURI" ascending:YES];
        self.baseSources = [[sources allObjects] sortedArrayUsingDescriptors:@[sortDescriptor]];
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)loadView {
    [super loadView];

    self.navigationController.navigationBar.navProgressView.progress = 0;
    
    if (self.navigationController.viewControllers.firstObject == self) {
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
        self.navigationItem.leftBarButtonItem = cancelItem;
    }
    
    UIBarButtonItem *importItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Import", @"") style:UIBarButtonItemStyleDone target:self action:@selector(importSelected)];
    importItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = importItem;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBSourceTableViewCell" bundle:nil] forCellReuseIdentifier:@"sourceTableViewCell"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.baseSources || !self.baseSources.count) {
        [self processSourcesFromLists];

        self.navigationItem.title = NSLocalizedString(@"Import Sources", @"");

        [self.tableView reloadData];
    } else {
        sourcesToVerify = self.baseSources.count;
        individualIncrement = (double) 1 / sourcesToVerify;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            for (ZBDummySource *source in self.baseSources) {
                self.titles[source.UUID] = NSLocalizedString(@"Verifying...", @"");
            }

            [self verifySources:self.baseSources];
        });
    }
}

- (void)increaseProgressBy:(double)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        double trueProgress = self.navigationController.navigationBar.navProgressView.progress + progress;
        if (trueProgress >= 1.0) {
            [self.navigationController.navigationBar.navProgressView setProgress:1.0 animated:YES];
            [UIView animateWithDuration:0.5 animations:^{
                [self.navigationController.navigationBar.navProgressView setAlpha:0.0];
            } completion:^(BOOL finished) {
                [self setImportEnabled:[self shouldEnableImportButton]];
            }];
        }
        else {
            [self.navigationController.navigationBar.navProgressView setProgress:trueProgress animated:YES];
        }
    });
}

- (void)setImportEnabled:(BOOL)enabled {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.rightBarButtonItem.enabled = enabled;
    });
}

- (BOOL)shouldEnableImportButton {
    for (NSString *bfn in self.selectedSources) {
        if ([self.selectedSources[bfn] boolValue]) {
            return YES;
        }
    }
    return NO;
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.baseSources.count ?: 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.baseSources.count) {
        ZBSourceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sourceTableViewCell"];
        if (!cell) {
            cell = (ZBSourceTableViewCell *)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sourceTableViewCell"];
        }
        
        ZBDummySource *source = self.baseSources[indexPath.row];
        ZBSourceVerificationStatus status = source.verificationStatus;

        cell.sourceLabel.alpha = 1.0;
        cell.urlLabel.alpha = 1.0;
        cell.sourceLabel.textColor = [ZBColor labelColor];
        [cell setSpinning:NO];
        switch (status) {
            case ZBSourceExists: {
                BOOL selected = [self.selectedSources[source.UUID] boolValue];
                cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                break;
            }
            case ZBSourceUnverified: {
                [cell setSpinning:YES];
                cell.accessoryType = UITableViewCellAccessoryNone;

                cell.sourceLabel.alpha = 0.7;
                cell.urlLabel.alpha = 0.7;
                break;
            }
            case ZBSourceImaginary: {
                cell.accessoryType = UITableViewCellAccessoryNone;

                cell.sourceLabel.textColor = [UIColor systemPinkColor];
                break;
            }
            case ZBSourceVerifying: {
                [cell setSpinning:YES];

                cell.sourceLabel.alpha = 0.7;
                cell.urlLabel.alpha = 0.7;
                break;
            }
        }

        cell.sourceLabel.text = self.titles[source.UUID];
        cell.urlLabel.text = source.repositoryURI;

        [cell.iconImageView sd_setImageWithURL:source.iconURL placeholderImage:[UIImage imageNamed:@"Unknown"]];
        
        return cell;
    }
    else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noSourcesCell"];
        
        cell.textLabel.text = NSLocalizedString(@"No sources to import", @"");
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [ZBColor secondaryLabelColor];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.baseSources.count) return;
    
    ZBDummySource *source = self.baseSources[indexPath.row];
    if (source && source.verificationStatus == ZBSourceExists) {
        BOOL selected = [self.selectedSources[source.UUID] boolValue];

        [self setSource:source selected:!selected];
        [self updateCellForSource:source];
        [self setImportEnabled:[self shouldEnableImportButton]];
    }
}

- (void)updateCellForSource:(ZBDummySource *)source {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger index = [self.baseSources indexOfObject:source];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    });
}

#pragma mark - Processing Sources

- (void)processSourcesFromLists {
    NSMutableSet *baseSourcesSet = [NSMutableSet new];

    for (NSURL *sourcesLocation in self.sourceFilesToImport) {
        NSError *error = nil;
        [baseSourcesSet unionSet:[ZBDummySource baseSourcesFromList:sourcesLocation error:&error]];

        if (error) {
            break;
        }
    }

    [baseSourcesSet minusSet:[ZBDummySource baseSourcesFromList:[ZBAppDelegate sourcesListURL] error:nil]];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"repositoryURI" ascending:YES];
    self.baseSources = [[baseSourcesSet allObjects] sortedArrayUsingDescriptors:@[sortDescriptor]];

    sourcesToVerify = self.baseSources.count;
    individualIncrement = (double) 1 / sourcesToVerify;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (ZBDummySource *source in self.baseSources) {
            self.titles[source.UUID] = NSLocalizedString(@"Verifying...", @"");
        }

        [self verifySources:self.baseSources];
    });
}

#pragma mark - Importing Sources

- (void)setSource:(ZBDummySource *)source selected:(BOOL)selected {
    if (source.verificationStatus != ZBSourceExists) return;

    self.selectedSources[source.UUID] = @(selected);
}

- (void)importSelected {
    NSMutableSet *sources = [NSMutableSet new];
    NSMutableArray *baseFilenames = [NSMutableArray new];
    
    for (NSString *baseFilename in [self.selectedSources allKeys]) {
        if ([self.selectedSources[baseFilename] boolValue]) {
            if (baseFilename) [baseFilenames addObject:baseFilename];
        }
    }
    
    for (ZBDummySource *source in self.baseSources) {
        if ([baseFilenames containsObject:source.UUID]) {
            if (source) [sources addObject:source];
        }
    }
    
    NSString *message = sources.count > 1 ? [NSString stringWithFormat:NSLocalizedString(@"Are you sure that you want to import %d sources into Zebra?", @""), (int)sources.count] : NSLocalizedString(@"Are you sure that you want to import 1 source into Zebra?", @"");
    UIAlertController *areYouSure = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirm Import", @"") message:message preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        [self->sourceManager addSources:sources error:nil];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [areYouSure addAction:yesAction];
    
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"") style:UIAlertActionStyleCancel handler:nil];
    [areYouSure addAction:noAction];
    
    areYouSure.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:areYouSure animated:YES completion:nil];
}

#pragma mark - Source Verification

- (void)verifySources:(NSArray <ZBDummySource *> *)sources {
    for (ZBDummySource *source in sources) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [source verify:^(ZBSourceVerificationStatus status) {
                [self source:source status:status];
            }];
        });
    }
}

- (void)source:(ZBDummySource *)source status:(ZBSourceVerificationStatus)status {
    if (status == ZBSourceExists) {
        [source getOrigin:^(NSString * _Nonnull origin) {
            if (!origin) {
                origin = source.repositoryURI;
            }
            
            self.titles[source.UUID] = origin;
            [self setSource:source selected:YES];
            [self updateCellForSource:source];
            
            [self increaseProgressBy:self->individualIncrement];
        }];
    }
    else if (status == ZBSourceImaginary) {
        self.titles[source.UUID] = NSLocalizedString(@"Unable to verify source", @"");
        [self updateCellForSource:source];
        
        [self increaseProgressBy:individualIncrement];
    }
}

@end
