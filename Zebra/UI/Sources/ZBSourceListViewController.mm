//
//  ZBSourceListViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/1/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBSourceListViewController.h"

#import <UI/Sources/Views/Cells/ZBSourceTableViewCell.h>
#import <UI/Sources/ZBSourceViewController.h>
#import <UI/ZBSidebarController.h>
#import <UI/Sources/ZBSourceAddViewController.h>
#import <UI/Common/ZBErrorViewController.h>
#import <Extensions/ZBColor.h>

#import <Plains/Managers/PLSourceManager.h>
#import <Plains/Model/PLSource.h>
#import <SDWebImage/SDWebImage.h>

@interface ZBSourceListViewController () {
    PLSourceManager *sourceManager;
    NSArray *sources;
}
@property BOOL allowEditing;
@property BOOL showNavigationButtons;
@property BOOL allowRefresh;
@property BOOL showFailureSection;
@property BOOL allowSelection;
@property Class selectActionClass;
@property NSMutableDictionary <NSString *, NSMutableArray *> *failures;
@end

@implementation ZBSourceListViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        self.title = @"Sources";
        
        sourceManager = [PLSourceManager sharedInstance];
        
        _failures = [NSMutableDictionary new];
        _allowRefresh = YES;
        _allowEditing = YES;
        _allowSelection = YES;
        _showNavigationButtons = YES;
        _showFailureSection = YES;
        _selectActionClass = [ZBSourceViewController class];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSources) name:PLSourceListUpdatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setSourceDownloading:) name:PLStartedSourceDownloadNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedSourceDownload:) name:PLFailedSourceDownloadNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setSourceFinished:) name:PLFinishedSourceDownloadNotification object:nil];
    }
    
    return self;
} 

- (instancetype)initWithSources:(NSArray <PLSource *> *)sources {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        self->sources = sources;
    }
    
    return self;
}

- (int)hasIssues {
    __block int hasIssues = NO;
    [self.failures enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray * _Nonnull obj, BOOL * _Nonnull stop) {
        hasIssues += obj.count ? 1 : 0;
    }];
    return hasIssues;
}

- (void)viewDidLoad {
    [super viewDidLoad];

#if TARGET_OS_IOS
    if (self.allowRefresh) {
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(refreshSources) forControlEvents:UIControlEventValueChanged];
    }
    
    if (self.showNavigationButtons) {
        UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButton:)];
        self.navigationItem.rightBarButtonItem = addItem;
    }
#endif
    
    [self.tableView setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBSourceTableViewCell" bundle:nil] forCellReuseIdentifier:@"sourceTableViewCell"];
    
    [self loadSources];
}

#if TARGET_OS_MACCATALYST
- (NSArray *)toolbarItems {
    return @[@"refreshButton", @"addButton"];
}
#endif

- (void)addButton:(id)sender {
    ZBSourceAddViewController *addVC = [[ZBSourceAddViewController alloc] init];
    UINavigationController *addNav = [[UINavigationController alloc] initWithRootViewController:addVC];

    [self presentViewController:addNav animated:YES completion:nil];
}

- (void)refreshButton:(id)sender {
    [self refreshSources];
}

- (void)reloadSources {
    self->sources = NULL;
    [self loadSources];
}

- (void)loadSources {
    if (!self.isViewLoaded) return;
    
    if (sources) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView transitionWithView:self.tableView duration:0.20f options:UIViewAnimationOptionTransitionCrossDissolve animations:^(void) {
                [self.tableView reloadData];
            } completion:nil];
        });
    } else { // Load sources for the first time, every other access is done by the filter and delegate methods
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            self->sources = [[self->sourceManager sources] sortedArrayUsingSelector:@selector(compareByOrigin:)];
            [self loadSources];
        });
    }
}

- (void)refreshSources {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self->sourceManager refreshSources];
#if TARGET_OS_IOS
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
        });
#endif
    });
}

- (void)failedSourceDownload:(NSNotification *)notification {
    NSString *UUID = notification.userInfo[@"uuid"];
    NSString *reason = notification.userInfo[@"reason"];
    
    NSMutableArray *sourceFailures = self.failures[UUID] ?: [NSMutableArray new];
    [sourceFailures addObject:reason];
    self.failures[UUID] = sourceFailures;
    
    NSUInteger row = [sources indexOfObjectPassingTest:^BOOL(PLSource *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.UUID isEqualToString:UUID];
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.showFailureSection) [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:self.showFailureSection]] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)setSourceDownloading:(NSNotification *)notification {
    NSString *UUID = notification.userInfo[@"uuid"];
    
    NSUInteger row = [sources indexOfObjectPassingTest:^BOOL(PLSource *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.UUID isEqualToString:UUID];
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ZBSourceTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        [cell setSpinning:YES];
    });
}

- (void)setSourceFinished:(NSNotification *)notification {
    NSString *UUID = notification.userInfo[@"uuid"];
    
    NSUInteger row = [sources indexOfObjectPassingTest:^BOOL(PLSource *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.UUID isEqualToString:UUID];
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ZBSourceTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        [cell setSpinning:NO];
    });
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.showFailureSection) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && self.showFailureSection) {
        return [self hasIssues];
    } else {
        return sources.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && self.showFailureSection) {
        ZBSourceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sourceTableViewCell" forIndexPath:indexPath];
        
        int hasIssues = [self hasIssues];
        cell.sourceLabel.text = hasIssues > 1 ? [NSString stringWithFormat:@"%d sources could not be refreshed.", hasIssues] : @"1 source could not be refreshed.";
        cell.urlLabel.text = @"Tap to learn more.";
        if (@available(iOS 13.0, macCatalyst 13.0, *)) {
            cell.iconImageView.image = [UIImage systemImageNamed:@"xmark.octagon.fill"];
        }
        cell.iconImageView.layer.borderColor = [UIColor clearColor].CGColor;
        cell.tintColor = [UIColor systemRedColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        return cell;
    } else {
        ZBSourceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sourceTableViewCell" forIndexPath:indexPath];
        
        PLSource *source = sources[indexPath.row];
        [cell setSource:source];
        
        if (self.failures[source.UUID].count) {
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
            cell.tintColor = [UIColor systemRedColor];
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.tintColor = nil;
        }
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    PLSource *source = sources[indexPath.row];
    source.messages = self.failures[source.UUID];
    
    ZBErrorViewController *errorVC = [[ZBErrorViewController alloc] initWithSource:source];
    
    [[self navigationController] pushViewController:errorVC animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.showFailureSection && [self hasIssues] && indexPath.row == 0) {
        NSMutableArray *failedSources = [NSMutableArray new];
        [self.failures enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray * _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.count) [failedSources addObject:[sourceManager sourceForUUID:key]];
        }];
        
        ZBSourceListViewController *sourceController = [[ZBSourceListViewController alloc] initWithSources:failedSources];
        sourceController.allowEditing = NO;
        sourceController.allowRefresh = NO;
        sourceController.showNavigationButtons = NO;
        sourceController.showFailureSection = NO;
        sourceController.selectActionClass = [ZBErrorViewController class];
        sourceController.failures = self.failures;
        sourceController.title = @"Failures";
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:sourceController];
        [self presentViewController:navController animated:YES completion:nil];
        
        
        // TODO: Make images for these on iOS 12
        if (@available(iOS 13.0, macCatalyst 13.0, *)) {
            sourceController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"xmark"] style:UIBarButtonItemStyleDone target:sourceController action:@selector(goodbye)];
            sourceController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"list.triangle"] style:UIBarButtonItemStylePlain target:sourceController action:@selector(showLog)];
        } else {
            sourceController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:sourceController action:@selector(goodbye)];
            sourceController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Log" style:UIBarButtonItemStylePlain target:sourceController action:@selector(showLog)];
        }
    } else {
        PLSource *source = sources[indexPath.row];
        if (self.selectActionClass == [ZBErrorViewController class]) source.messages = self.failures[source.UUID];
        
        UIViewController *controller = [[self.selectActionClass alloc] initWithSource:source];
        
        [[self navigationController] pushViewController:controller animated:YES];
    }
}

- (void)goodbye {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)showLog {
    ZBErrorViewController *errorVC = [[ZBErrorViewController alloc] init];
    
    [[self navigationController] pushViewController:errorVC animated:YES];
}

#pragma mark - Table View Delegate

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLSource *source = sources[indexPath.row];
    if (self.allowEditing && [source canRemove]) {
        UIContextualAction *removeAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self->sourceManager removeSource:source];
            self->sources = NULL;
            [self loadSources];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
        return [UISwipeActionsConfiguration configurationWithActions:@[removeAction]];
    }
    return NULL;
}

# pragma mark - Keyboard Shortcuts

- (NSArray<UIKeyCommand *> *)keyCommands {
    if (self.selectActionClass == [ZBErrorViewController class]) {
        // escape key
        UIKeyCommand *goodbyeShortcut = [UIKeyCommand keyCommandWithInput:@"\e" modifierFlags:0 action:@selector(goodbye)];
        goodbyeShortcut.discoverabilityTitle = NSLocalizedString(@"Dismiss", @"");

        return @[goodbyeShortcut];
    } else {
        UIKeyCommand *refresh = [UIKeyCommand keyCommandWithInput:@"r" modifierFlags:UIKeyModifierCommand action:@selector(refreshSources)];
        refresh.discoverabilityTitle = NSLocalizedString(@"Refresh", @"");

        UIKeyCommand *add = [UIKeyCommand keyCommandWithInput:@"n" modifierFlags:UIKeyModifierCommand action:@selector(addButton:)];
        add.discoverabilityTitle = NSLocalizedString(@"Add", @"");

        return @[refresh, add];
    }
}

@end
