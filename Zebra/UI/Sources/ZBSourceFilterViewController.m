//
//  ZBSourceFilterViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/1/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBSourceFilterViewController.h"

#import <Model/ZBSourceFilter.h>
#import <Extensions/UIColor+GlobalColors.h>

@interface ZBSourceFilterViewController () {
    id <ZBFilterDelegate> delegate;
}
@property (nonatomic) ZBSourceFilter *filter;
@end

@implementation ZBSourceFilterViewController

#pragma mark - Initializers

- (instancetype)initWithFilter:(ZBSourceFilter *)filter delegate:(id <ZBFilterDelegate>)delegate {
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

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1; // Filter By and Sort By
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"filterCell"];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch (indexPath.section) {
        case 0: {
            UISwitch *switchySwitch = [[UISwitch alloc] init]; // can't name a variable 'switch'
            switch (indexPath.row) {
                case 0: {
                    switchySwitch.on = self.filter.stores;
                    [switchySwitch addTarget:self action:@selector(setShowStores:) forControlEvents:UIControlEventTouchUpInside];
                        
                    cell.textLabel.text = NSLocalizedString(@"Stores", @"");
                    break;
                }
                case 1: {
                    switchySwitch.on = self.filter.unusedSources;
                    [switchySwitch addTarget:self action:@selector(setShowUnusedSources:) forControlEvents:UIControlEventTouchUpInside];
                        
                    cell.textLabel.text = NSLocalizedString(@"Unused Sources", @"");
                    break;
                }
            }
            cell.accessoryView = switchySwitch;
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"Source Name", @"");
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

- (void)setShowStores:(UISwitch *)sender {
    self.filter.stores = sender.on;
    [delegate applyFilter:self.filter];
}

- (void)setShowUnusedSources:(UISwitch *)sender {
    self.filter.unusedSources = sender.on;
    [delegate applyFilter:self.filter];
}

@end
