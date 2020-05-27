//
//  ZBWishListTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/18/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBWishListTableViewController.h"
#import "ZBPackageViewController.h"
#import "ZBPackageActions.h"

#import <ZBSettings.h>
#import <ZBQueue.h>
#import <ZBDevice.h>
#import <Database/ZBDatabaseManager.h>
#import <Extensions/UINavigationBar+Extensions.h>
#import <Extensions/UIColor+GlobalColors.h>
#import <Packages/Views/ZBPackageTableViewCell.h>
#import <Packages/Helpers/ZBPackage.h>

@interface ZBWishListTableViewController () {
    UIImageView *shadowView;
}
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, weak) ZBPackageViewController *previewPackageDepictionVC;
@end

@implementation ZBWishListTableViewController

@synthesize wishedPackages;
@synthesize wishedPackageIdentifiers;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Wish List", @"");
    
    [self.segmentedControl setTitle:NSLocalizedString(@"Newest First", @"") forSegmentAtIndex:0];
    [self.segmentedControl setTitle:NSLocalizedString(@"Oldest First", @"") forSegmentAtIndex:1];
    [self.segmentedControl addTarget:self action:@selector(selectionChanged:) forControlEvents:UIControlEventValueChanged];
    self.segmentedControl.selectedSegmentIndex = 0;
    self.segmentedControl.tintColor = [UIColor accentColor];
    [self.toolbar setDelegate:self];
    
    [self selectionChanged:self.segmentedControl];
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(export)];
    self.navigationItem.rightBarButtonItem = shareButton;
    [self updateShareButtonState];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"ZBPackageStatusUpdate" object:nil];
}

- (void)updateShareButtonState {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.rightBarButtonItem.enabled = self->wishedPackages.count != 0;
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!shadowView) {
        shadowView = [self findBorderLineUnder:self.navigationController.navigationBar];
    }
    shadowView.hidden = YES;
    
    switch ([ZBSettings interfaceStyle]) {
        case ZBInterfaceStyleLight:
            self.toolbar.barStyle = UIBarStyleDefault;
            break;
        case ZBInterfaceStyleDark:
            self.toolbar.barStyle = UIBarStyleBlackTranslucent;
            break;
        case ZBInterfaceStylePureBlack:
            self.toolbar.barStyle = UIBarStyleBlackOpaque;
            break;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    shadowView.hidden = NO;
}

- (void)export {
    if (wishedPackages.count == 0) {
        return;
    }
    NSArray *packages = [wishedPackages copy];
    [packages sortedArrayUsingSelector:@selector(name)];
    
    NSMutableArray *descriptions = [NSMutableArray new];
    for (ZBPackage *package in packages) {
        [descriptions addObject:[package description]];
    }
    
    NSString *fullList = [descriptions componentsJoinedByString:@"\n"];
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[fullList] applicationActivities:nil];
    controller.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:controller animated:YES completion:nil];
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

- (UIImageView *)findBorderLineUnder:(UIView *)view {
    if ([view isKindOfClass:[UIImageView class]] && view.bounds.size.height <= 1) {
        return (UIImageView *)view;
    }
    
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findBorderLineUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}

- (void)selectionChanged:(UISegmentedControl *)control {
    NSUInteger index = control.selectedSegmentIndex;
    
    wishedPackages = [NSMutableArray new];
    wishedPackageIdentifiers = [[ZBSettings wishlist] mutableCopy];
    
    NSArray *nullCheck = [wishedPackageIdentifiers copy];
    for (NSString *packageID in nullCheck) {
        ZBPackage *package = (ZBPackage *)[[ZBDatabaseManager sharedInstance] topVersionForPackageID:packageID];
        if (package == nil) {
            [wishedPackageIdentifiers removeObject:package];
        }
        else if (![wishedPackages containsObject:package]) {
            [wishedPackages addObject:package];
        }
    }
    
    if (index == 0) {
        if (wishedPackages.count <= 1) return;
        NSUInteger i = 0;
        NSUInteger j = wishedPackages.count - 1;
        while (i < j) {
            [wishedPackages exchangeObjectAtIndex:i withObjectAtIndex:j];
            ++i;
            --j;
        }
    }
    
    [self updateShareButtonState];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)refreshTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (wishedPackages.count == 0) {
        return 1;
    }
    
    return wishedPackages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (wishedPackages.count == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noWishesCell"];
        cell.textLabel.text = NSLocalizedString(@"No items in Wish List", @"");
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor secondaryTextColor];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }
    else {
        ZBPackageTableViewCell *cell = (ZBPackageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
        [cell setColors];
        
        ZBPackage *package = wishedPackages[indexPath.row];
        [(ZBPackageTableViewCell *)cell updateData:package];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (wishedPackages.count != 0) {
        ZBPackage *package = [wishedPackages objectAtIndex:indexPath.row];
        if (package) {
            ZBPackageViewController *packageDepiction = [[ZBPackageViewController alloc] initWithPackage:package];
            
            [[self navigationController] pushViewController:packageDepiction animated:YES];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return wishedPackages.count != 0;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *remove = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:(ZBDevice.useIcon ? @"╳" : NSLocalizedString(@"Remove", @"")) handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        ZBPackage *package = self->wishedPackages[indexPath.row];

        [self->wishedPackages removeObject:package];
        [self->wishedPackageIdentifiers removeObject:[package identifier]];

        [ZBSettings setWishlist:self->wishedPackageIdentifiers];

        [self updateShareButtonState];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];

        completionHandler(YES);
    }];

    remove.backgroundColor = [UIColor systemPinkColor];

    return [UISwipeActionsConfiguration configurationWithActions:@[remove]];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView setEditing:NO animated:YES];
}

// FIXME: Update for new depictions
//- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0)){
//    typeof(self) __weak weakSelf = self;
//    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController * _Nullable{
//        return weakSelf.previewPackageDepictionVC;
//    } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
//        if (weakSelf == nil) {
//            return nil;
//        }
//        typeof(self) __strong strongSelf = weakSelf;
//        weakSelf.previewPackageDepictionVC = (ZBPackageDepictionViewController*)[weakSelf.storyboard instantiateViewControllerWithIdentifier:@"packageDepictionVC"];
//        weakSelf.previewPackageDepictionVC.package = [strongSelf.wishedPackages objectAtIndex:indexPath.row];
//        weakSelf.previewPackageDepictionVC.parent = weakSelf;
//        return [UIMenu menuWithTitle:@"" children:[weakSelf.previewPackageDepictionVC contextMenuActionItemsInTableView:tableView]];
//    }];
//}

- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator API_AVAILABLE(ios(13.0)){
    typeof(self) __weak weakSelf = self;
    [animator addCompletion:^{
        [weakSelf.navigationController pushViewController:weakSelf.previewPackageDepictionVC animated:YES];
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBPackageStatusUpdate" object:nil];
}

@end
