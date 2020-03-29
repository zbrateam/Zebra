//
//  ZBRepoBlacklistTableViewController.m
//  Zebra
//
//  Created by midnightchips on 7/7/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBRepoBlacklistTableViewController.h"
#import "ZBDatabaseManager.h"
#import "ZBSource.h"
#import "ZBRepoTableViewCell.h"
#import "UIColor+GlobalColors.h"
@import SDWebImage;

@implementation ZBRepoBlacklistTableViewController

+ (BOOL)supportRefresh {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    [self.navigationItem setTitle:NSLocalizedString(@"Featured Repos", @"")];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.estimatedRowHeight = 60.0;
    self.tableView.rowHeight = 60;
    [self refreshTable];
}

- (void)baseViewDidLoad {}

- (void)layoutNavigationButtonsNormal {}

- (void)checkClipboard {}

- (void)refreshTable {
    self->sources = [[[ZBDatabaseManager sharedInstance] sources] mutableCopy];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateCollation];
        [self.tableView reloadData];
    });
}

- (ZBRepoTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBRepoTableViewCell *cell = (ZBRepoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
    NSArray *blackListedRepos = [[NSUserDefaults standardUserDefaults] arrayForKey:@"blackListedRepos"];
    ZBSource *source = [self sourceAtIndexPath:indexPath];
    
    cell.repoLabel.text = [source label];
    
    cell.urlLabel.text = [source repositoryURI];
    [cell.iconImageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    if (![blackListedRepos containsObject:source.repositoryURI]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.repoLabel.textColor = [UIColor primaryTextColor];
    cell.urlLabel.textColor = [UIColor secondaryTextColor];
    cell.backgroundContainerView.backgroundColor = [UIColor cellBackgroundColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *blocked = [[defaults arrayForKey:@"blackListedRepos"] mutableCopy];
    if (!blocked) {
        blocked = [NSMutableArray new];
    }
    ZBSource *repo = [self sourceAtIndexPath:indexPath];
    
    if ([blocked containsObject:repo.repositoryURI]) {
        [blocked removeObject:repo.repositoryURI];
    } else {
        [blocked addObject:repo.repositoryURI];
    }
    [defaults setObject:blocked forKey:@"blackListedRepos"];
    [defaults synchronize];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView reloadData];
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionFade;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.fillMode = kCAFillModeForwards;
    transition.duration = 0.35;
    transition.subtype = kCATransitionFromTop;
    [self.tableView.layer addAnimation:transition forKey:@"UITableViewReloadDataAnimationKey"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshCollection" object:self];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
 }

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {}

@end
