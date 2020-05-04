//
//  ZBWishListTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/18/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBWishListTableViewController.h"
#import <ZBSettings.h>
#import <ZBQueue.h>
#import <ZBDevice.h>
#import <Extensions/UINavigationBar+Progress.h>
#import <ZBSettings.h>

@interface ZBWishListTableViewController () {
    UIImageView *shadowView;
}
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, weak) ZBPackageDepictionViewController *previewPackageDepictionVC;
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
    [self.segmentedControl setSelectedSegmentIndex:0];
    [self.segmentedControl setTintColor:[UIColor accentColor]];
    [self.toolbar setDelegate:self];
    
    [self selectionChanged:self.segmentedControl];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(export)];
    self.navigationItem.rightBarButtonItem = shareButton;
    [self updateShareButtonState];
}

- (void)updateShareButtonState {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.rightBarButtonItem.enabled = [self->wishedPackages count] != 0;
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    if (!shadowView) {
        shadowView = [self findBorderLineUnder:self.navigationController.navigationBar];
    }
    [shadowView setHidden:YES];
    
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
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
    
    [shadowView setHidden:NO];
}

- (void)export {
    if ([wishedPackages count] == 0) {
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
    return NULL;
}

- (void)selectionChanged:(UISegmentedControl *)control {
    NSUInteger index = control.selectedSegmentIndex;
    
    wishedPackages = [NSMutableArray new];
    wishedPackageIdentifiers = [[ZBSettings wishlist] mutableCopy];
    
    NSArray *nullCheck = [wishedPackageIdentifiers copy];
    for (NSString *packageID in nullCheck) {
        ZBPackage *package = (ZBPackage *)[[ZBDatabaseManager sharedInstance] topVersionForPackageID:packageID];
        if (package == NULL) {
            [wishedPackageIdentifiers removeObject:package];
        }
        else if (![wishedPackages containsObject:package]) {
            [wishedPackages addObject:package];
        }
    }
    
    if (index == 0) {
        if ([wishedPackages count] <= 1) return;
        NSUInteger i = 0;
        NSUInteger j = [wishedPackages count] - 1;
        while (i < j) {
            [wishedPackages exchangeObjectAtIndex:i withObjectAtIndex:j];
            ++i;
            --j;
        }
    }
    
    [self updateShareButtonState];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View Data Source

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([wishedPackages count] == 0) {
        return 1;
    }
    
    return [wishedPackages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([wishedPackages count] == 0) {
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
        
        ZBPackage *package = [wishedPackages objectAtIndex:indexPath.row];
        [(ZBPackageTableViewCell *)cell updateData:package];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (wishedPackages.count != 0) {
        [self performSegueWithIdentifier:@"segueWishToPackageDepiction" sender:indexPath];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return wishedPackages.count != 0;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *remove = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:(ZBDevice.useIcon ? @"╳" : NSLocalizedString(@"Remove", @"")) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        ZBPackage *package = [self->wishedPackages objectAtIndex:indexPath.row];
        
        [self->wishedPackages removeObject:package];
        [self->wishedPackageIdentifiers removeObject:[package identifier]];
        
        [ZBSettings setWishlist:self->wishedPackageIdentifiers];
        
        [self updateShareButtonState];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    
    [remove setBackgroundColor:[UIColor systemPinkColor]];
    
    return @[remove];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView setEditing:NO animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"segueWishToPackageDepiction"]) {
        ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
        NSIndexPath *indexPath = sender;
        destination.package = [wishedPackages objectAtIndex:indexPath.row];
        destination.view.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point  API_AVAILABLE(ios(13.0)){
    typeof(self) __weak weakSelf = self;
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController * _Nullable{
        return weakSelf.previewPackageDepictionVC;
    } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        if (weakSelf == nil) {
            return nil;
        }
        typeof(self) __strong strongSelf = weakSelf;
        weakSelf.previewPackageDepictionVC = (ZBPackageDepictionViewController*)[weakSelf.storyboard instantiateViewControllerWithIdentifier:@"packageDepictionVC"];
        weakSelf.previewPackageDepictionVC.package = [strongSelf.wishedPackages objectAtIndex:indexPath.row];
        weakSelf.previewPackageDepictionVC.parent = weakSelf;
        return [UIMenu menuWithTitle:@"" children:[weakSelf.previewPackageDepictionVC contextMenuActionItemsInTableView:tableView]];
    }];
}

- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    typeof(self) __weak weakSelf = self;
    [animator addCompletion:^{
        [weakSelf.navigationController pushViewController:weakSelf.previewPackageDepictionVC animated:YES];
    }];
}

@end
