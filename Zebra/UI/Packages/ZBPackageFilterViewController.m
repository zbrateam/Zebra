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
        
//        self.title = NSLocalizedString(@"Filters", @"");
        self.view.tintColor = [UIColor accentColor];
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"xmark.circle"] style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor accentColor];
    
    UILabel *titleLabel = [UILabel new];
    titleLabel.textColor = [UIColor primaryTextColor];
    titleLabel.text = NSLocalizedString(@"Filters", @"");
    UIFont *titleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    UIFont *largeTitleFont = [UIFont fontWithDescriptor:[titleFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:titleFont.pointSize];
    titleLabel.font = largeTitleFont;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; // Filter By and Sort By
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 4 + self.filter.canSetSection; // At a maximum
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
                    cell.detailTextLabel.text = self.filter.section ?: NSLocalizedString(@"All Sections", @"");
                    break;
                }
                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Role", @"");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = @"User";
                    break;
                }
                case 2: {
                    cell.textLabel.text = NSLocalizedString(@"Commercial", @"");
                    break;
                }
                case 3: {
                    cell.textLabel.text = NSLocalizedString(@"Favorites", @"");
                    break;
                }
                case 4: {
                    cell.textLabel.text = NSLocalizedString(@"Installed", @"");
                    break;
                }
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Package Name", @"");
                    if (self.filter.sortOrder == 0) cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    break;
                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Date Installed", @"");
                    if (self.filter.sortOrder == 1) cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    break;
                case 2:
                    cell.textLabel.text = NSLocalizedString(@"Package Size", @"");
                    if (self.filter.sortOrder == 2) cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    break;
            }
            break;
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? NSLocalizedString(@"Filter By", @"") : NSLocalizedString(@"Sort By", @"");
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return section == 0 ? [NSString stringWithFormat:NSLocalizedString(@"%d out of %d packages shown.", @""), 100, 125] : NULL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 0: {
            // Nothing yet
            break;
        }
        case 1: {
            self.filter.sortOrder = indexPath.row;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
    }
    
    [delegate applyFilter:self.filter];
}

@end
