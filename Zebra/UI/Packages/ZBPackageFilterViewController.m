//
//  ZBPackageFilterViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/14/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBPackageFilterViewController.h"

#import <Extensions/UIColor+GlobalColors.h>
#import <Model/ZBPackageFilter.h>
#import <Model/ZBSource.h>
#import <UI/Common/ZBSelectionViewController.h>

@interface ZBPackageFilterViewController () {
    id <ZBFilterDelegate> delegate;
}
@property (nonatomic) ZBPackageFilter *filter;
@end

@implementation ZBPackageFilterViewController

#pragma mark - Initializers

- (instancetype)initWithFilter:(ZBPackageFilter *)filter delegate:(id <ZBFilterDelegate>)delegate {
    if (@available(iOS 13.0, *)) {
        self = [super initWithStyle:UITableViewStyleInsetGrouped];
    } else {
        self = [super initWithStyle:UITableViewStyleGrouped];
    }
    
    if (self) {
        self->delegate = delegate;
        self.filter = filter;
        
        self.title = NSLocalizedString(@"Filters", @"");
        self.view.tintColor = [UIColor accentColor];
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)setTitle:(NSString *)title {
    UILabel *titleLabel = [UILabel new];
    titleLabel.textColor = [UIColor primaryTextColor];
    titleLabel.text = title;
    UIFont *titleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    UIFont *largeTitleFont = [UIFont fontWithDescriptor:[titleFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:titleFont.pointSize];
    titleLabel.font = largeTitleFont;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 13.0, *)) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.down.circle.fill"] style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
    }
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor tertiaryTextColor];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Selection Delegate

- (void)selectedChoices:(NSArray *)choices fromIndexPath:(NSIndexPath *)indexPath {
    // Our indexPath section is only going to be 0 in this controller
    switch (indexPath.row) {
        case 0: { // Sections
            self.filter.sections = choices;
            break;
        }
        case 1: {
            NSArray *roles = @[@"User", @"Hacker", @"Developer", @"Deity"];
            NSString *role = choices.firstObject;
            if (role) {
                NSUInteger index = [roles indexOfObject:role];
                self.filter.role = index;
                self.filter.userSetRole = index != [ZBSettings role];
            }
            break;
        }
        default:
            break;
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [delegate applyFilter:self.filter];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; // Filter By and Sort By
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1 + self.filter.canSetSection; // At a maximum
    } else {
        return 3;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"filterCell"];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row + !self.filter.canSetSection) {
                case 0: {
                    cell.textLabel.text = NSLocalizedString(@"Section", @"");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = self.filter.sections.count ? NSLocalizedString(@"Sections", @"") : NSLocalizedString(@"All Sections", @"");
                    break;
                }
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Role", @"");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    
                    NSArray *roles = @[@"User", @"Hacker", @"Developer", @"Deity"];
                    cell.detailTextLabel.text = roles[self.filter.role];
                    break;
                }
//                case 2: {
//                    cell.textLabel.text = NSLocalizedString(@"Commercial", @"");
//                    break;
//                }
//                case 3: {
//                    cell.textLabel.text = NSLocalizedString(@"Favorites", @"");
//                    break;
//                }
//                case 4: {
//                    cell.textLabel.text = NSLocalizedString(@"Installed", @"");
//                    break;
//                }
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Package Name", @"");
                    break;
                case 1:
                    if (self.filter.source.remote) {
                        cell.textLabel.text = NSLocalizedString(@"Date Uploaded", @"");
                    } else {
                        cell.textLabel.text = NSLocalizedString(@"Date Installed", @"");
                    }
                    break;
                case 2:
                    cell.textLabel.text = NSLocalizedString(@"Package Size", @"");
                    break;
            }
            if (self.filter.sortOrder == indexPath.row) cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? NSLocalizedString(@"Filter By", @"") : NSLocalizedString(@"Sort By", @"");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row + !self.filter.canSetSection) {
                case 0: {
                    NSArray *sections = [[self.filter.source sections] allKeys];
                    ZBSelectionViewController *sectionSelectionVC = [[ZBSelectionViewController alloc] initWithDelegate:self indexPath:indexPath];
                    sectionSelectionVC.choices = sections;
                    sectionSelectionVC.selections = self.filter.sections.mutableCopy;
                    sectionSelectionVC.selectionType = ZBSelectionTypeInverse;
                    sectionSelectionVC.title = NSLocalizedString(@"Select a Section", @"");
                    [self.navigationController pushViewController:sectionSelectionVC animated:YES];
                    break;
                }
                case 1: {
                    NSArray *roles;
                    if ([ZBSettings role] == 3) {
                        roles = @[@"User", @"Hacker", @"Developer", @"Deity"];
                    } else {
                        roles = @[@"User", @"Hacker", @"Developer"]; // "Deity" will not be shown to normal users at all
                    }
                    ZBSelectionViewController *roleSelectionVC = [[ZBSelectionViewController alloc] initWithDelegate:self indexPath:indexPath];
                    roleSelectionVC.choices = roles;
                    roleSelectionVC.selections = [NSMutableArray arrayWithObjects:[roles objectAtIndex:self.filter.role], nil];
                    roleSelectionVC.selectionType = ZBSelectionTypeNormal;
                    roleSelectionVC.allowsMultiSelection = NO;
                    roleSelectionVC.title = NSLocalizedString(@"Select a Role", @"");
                    roleSelectionVC.footer = NSLocalizedString(@"User: Apps, Tweaks, and Themes\nHacker: Adds Command Line Tools\nDeveloper: Everything (well, almost)", @"");
                    [self.navigationController pushViewController:roleSelectionVC animated:YES];
                    break;
                }
            }
            break;
        }
        case 1: {
            self.filter.sortOrder = indexPath.row;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
            [delegate applyFilter:self.filter];
            break;
        }
    }
}

@end
