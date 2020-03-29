//
//  TableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/18/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBWishListTableViewController.h"
#import <ZBSettings.h>
#import <ZBQueue.h>
#import <ZBDevice.h>
#import <Extensions/UITableViewRowAction+Image.h>

@interface ZBWishListTableViewController ()
@property (nonatomic, weak) ZBPackageDepictionViewController *previewPackageDepictionVC;
@end

@implementation ZBWishListTableViewController

@synthesize wishedPackages;
@synthesize wishedPackageIdentifiers;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Wish List", @"");
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    if (!wishedPackages) wishedPackages = [NSMutableArray new];
    if (!wishedPackageIdentifiers) wishedPackageIdentifiers = [[ZBSettings wishlist] mutableCopy];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil] forCellReuseIdentifier:@"packageTableViewCell"];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
        
    NSArray *nullCheck = [wishedPackageIdentifiers copy];
    for (NSString *packageID in nullCheck) {
        ZBPackage *package = (ZBPackage *)[[ZBDatabaseManager sharedInstance] topVersionForPackageID:packageID];
        if (package == NULL) {
            [wishedPackageIdentifiers removeObject:package];
        }
        else {
            [wishedPackages addObject:package];
        }
    }
    [self.tableView reloadData];
    
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
        
        [self.tableView reloadData];
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
        destination.view.backgroundColor = [UIColor tableViewBackgroundColor];
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
        return [UIMenu menuWithTitle:@"" children:[weakSelf.previewPackageDepictionVC contextMenuActionItemsForIndexPath:indexPath]];
    }];
}

- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    typeof(self) __weak weakSelf = self;
    [animator addCompletion:^{
        [weakSelf.navigationController pushViewController:weakSelf.previewPackageDepictionVC animated:YES];
    }];
}

@end
