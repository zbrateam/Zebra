//
//  ZBAuthorSelectorTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/22/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBAuthorSelectorTableViewController.h"

#import <ZBSettings.h>
#import <Database/ZBDatabaseManager.h>
#import <Extensions/UIImageView+Zebra.h>

@interface ZBAuthorSelectorTableViewController () {
    NSArray *authors;
    NSString *selectedAuthor;
    NSIndexPath *selectedIndex;
}
@end

@implementation ZBAuthorSelectorTableViewController

#pragma mark - View Controller Lifecycle

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        authors = @[];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Select an Author", @"");
    
    [self layoutNaviationButtons];
}

#pragma mark - Bar Button Actions

- (void)layoutNaviationButtons {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", @"") style:UIBarButtonItemStyleDone target:self action:@selector(addSections)];
    self.navigationItem.rightBarButtonItem.enabled = selectedAuthor;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(goodbye)];
}

- (void)addSections {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.authorsSelected(@[self->selectedAuthor]);
    });
    
    [self goodbye];
}

- (void)goodbye {
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [authors count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sectionSelectorCell"];
    
    cell.textLabel.text = authors[indexPath.row];
    
    cell.accessoryType = [selectedIndex isEqual:indexPath] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    NSString *author = authors[indexPath.row];
    
    if ([selectedIndex isEqual:indexPath]) {
        selectedIndex = NULL;
        selectedAuthor = NULL;
    }
    else {
        selectedIndex = indexPath;
        selectedAuthor = author;
    }
    
    [[self tableView] reloadData];
    [self layoutNaviationButtons];
}

@end
