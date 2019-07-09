//
//  ZBRepoBlacklistTableViewController.m
//  Zebra
//
//  Created by midnightchips on 7/7/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBRepoBlacklistTableViewController.h"
#import "ZBTabBarController.h"
#import "ZBDatabaseManager.h"
#import "ZBRepo.h"
#import "ZBRepoTableViewCell.h"
#import "UIColor+GlobalColors.h"
@import SDWebImage;

@interface ZBRepoBlacklistTableViewController () {
    NSMutableArray *sources;
    NSMutableDictionary <NSString *, NSNumber *> *sourceIndexes;
    NSMutableArray *sectionIndexTitles;
}

@end

@implementation ZBRepoBlacklistTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"Featured Repos"];
    sources = [[[ZBDatabaseManager sharedInstance] repos] mutableCopy];
    sourceIndexes = [NSMutableDictionary new];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRepoTableViewCell" bundle:nil] forCellReuseIdentifier:@"repoTableViewCell"];
    self.tableView.estimatedRowHeight = 60.0;
    self.tableView.rowHeight = 60;
    [self refreshTable];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)refreshTable {
    self->sources = [[[ZBDatabaseManager sharedInstance] repos] mutableCopy];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateCollation];
        [self.tableView reloadData];
    });
}

- (void)updateCollation {
    self.tableData = [self partitionObjects:sources collationStringSelector:@selector(origin)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector {
    [sourceIndexes removeAllObjects];
    sectionIndexTitles = [NSMutableArray arrayWithArray:[[UILocalizedIndexedCollation currentCollation] sectionIndexTitles]];
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    NSInteger sectionCount = [[collation sectionTitles] count];
    NSMutableArray *unsortedSections = [NSMutableArray arrayWithCapacity:sectionCount];
    for (int i = 0; i < sectionCount; ++i) {
        [unsortedSections addObject:[NSMutableArray array]];
    }
    for (ZBRepo *object in array) {
        NSUInteger index = [collation sectionForObject:object collationStringSelector:selector];
        NSMutableArray *section = [unsortedSections objectAtIndex:index];
        sourceIndexes[[object baseFileName]] = @((index << 16) | section.count);
        [section addObject:object];
    }
    NSUInteger lastIndex = 0;
    NSMutableIndexSet *sectionsToRemove = [NSMutableIndexSet indexSet];
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];
    for (NSMutableArray *section in unsortedSections) {
        if ([section count] == 0) {
            NSRange range = NSMakeRange(lastIndex, [unsortedSections count] - lastIndex);
            [sectionsToRemove addIndex:[unsortedSections indexOfObject:section inRange:range]];
            lastIndex = [sectionsToRemove lastIndex] + 1;
        }
        else {
            NSArray *data = [collation sortedArrayFromArray:section collationStringSelector:selector];
            [sections addObject:data];
        }
    }
    [sectionIndexTitles removeObjectsAtIndexes:sectionsToRemove];
    for (NSString *bfn in [sourceIndexes allKeys]) {
        NSInteger pos = [sourceIndexes[bfn] integerValue];
        int index = (int)(pos >> 16);
        NSInteger row = pos & 0xFF;
        index = (int)[sectionIndexTitles indexOfObject:[NSString stringWithFormat:@"%c", 65 + index]];
        sourceIndexes[bfn] = @(index << 16 | row);
    }
    return sections;
}

- (NSInteger)hasDataInSection:(NSInteger)section {
    if ([self.tableData count] == 0)
        return 0;
    return [[self.tableData objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sectionIndexTitles count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self hasDataInSection:section];
}

- (ZBRepoTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBRepoTableViewCell *cell = (ZBRepoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
    NSArray *blackListedRepos = [[NSUserDefaults standardUserDefaults] arrayForKey:@"blackListedRepos"];
    ZBRepo *source = [self sourceAtIndexPath:indexPath];
    
    cell.repoLabel.text = [source origin];
    
    if ([source isSecure]) {
        cell.urlLabel.text = [NSString stringWithFormat:@"https://%@", [source shortURL]];
    }
    else {
        cell.urlLabel.text = [NSString stringWithFormat:@"http://%@", [source shortURL]];
    }
    [cell.iconImageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    if (![blackListedRepos containsObject:source.baseURL]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.repoLabel.textColor = [UIColor cellPrimaryTextColor];
    cell.urlLabel.textColor = [UIColor cellSecondaryTextColor];
    cell.backgroundContainerView.backgroundColor = [UIColor cellBackgroundColor];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self hasDataInSection:section] ? 30 : 0;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return sectionIndexTitles;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (![self hasDataInSection:section])
        return nil;
    return [sectionIndexTitles objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([self hasDataInSection:section]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.textLabel.font = [UIFont boldSystemFontOfSize:15];
        header.textLabel.textColor = [UIColor cellPrimaryTextColor];
        header.tintColor = [UIColor clearColor];
        [(UIView *)[header valueForKey:@"_backgroundView"] setBackgroundColor:[UIColor clearColor]];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *blocked = [[defaults arrayForKey:@"blackListedRepos"] mutableCopy];
    if (!blocked) {
        blocked = [NSMutableArray new];
    }
    ZBRepo *repo = [self sourceAtIndexPath:indexPath];
    
    if ([blocked containsObject:repo.baseURL]) {
        [blocked removeObject:repo.baseURL];
    } else {
        [blocked addObject:repo.baseURL];
    }
    [defaults setObject:blocked forKey:@"blackListedRepos"];
    [defaults synchronize];
    [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
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

- (ZBRepo *)sourceAtIndexPath:(NSIndexPath *)indexPath {
    if (![self hasDataInSection:indexPath.section])
        return nil;
    return self.tableData[indexPath.section][indexPath.row];
}


@end
