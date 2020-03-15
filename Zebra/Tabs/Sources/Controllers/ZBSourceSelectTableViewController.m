//
//  ZBSourceSelectTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/14/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SDWebImage;

#import "ZBSourceSelectTableViewController.h"
#import "ZBRepoTableViewCell.h"
#import "ZBSource.h"
#import "UIColor+GlobalColors.h"

@interface ZBSourceSelectTableViewController () {
    ZBSource *selectedSource;
    NSIndexPath *selectedIndex;
}

@end

@implementation ZBSourceSelectTableViewController

- (id)init {
    return [super initWithStyle:UITableViewStyleGrouped];
}

+ (BOOL)supportRefresh {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Select a Source";
}

- (void)baseViewDidLoad {}

- (void)layoutNavigationButtonsNormal {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(goodbye)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleDone target:self action:@selector(layoutNavigationButtonsNormal)];
    self.navigationItem.rightBarButtonItem.enabled = selectedSource;
}

- (void)checkClipboard {}

- (void)goodbye {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)refreshTable {
    self->sources = [[[ZBDatabaseManager sharedInstance] sources] mutableCopy];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateCollation];
        [self.tableView reloadData];
    });
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBRepoTableViewCell *cell = (ZBRepoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
    ZBSource *source = [self sourceAtIndexPath:indexPath];
    
    cell.repoLabel.text = [source label];
    cell.urlLabel.text = [source repositoryURI];
    [cell.iconImageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.repoLabel.textColor = [UIColor primaryTextColor];
    cell.urlLabel.textColor = [UIColor secondaryTextColor];
    cell.backgroundContainerView.backgroundColor = [UIColor cellBackgroundColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->selectedIndex && ![self->selectedIndex isEqual:indexPath]) {
            UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:self->selectedIndex];
            oldCell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
        newCell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        self->selectedIndex = indexPath;
        self->selectedSource = [self sourceAtIndexPath:self->selectedIndex];
        
        [self layoutNavigationButtonsNormal];
    });
}


@end
