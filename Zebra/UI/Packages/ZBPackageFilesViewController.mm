//
//  ZBPackageFilesViewController.m
//  Zebra
//
//  Created by midnightchips on 7/13/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageFilesViewController.h"

#import <Extensions/ZBColor.h>
#import <Plains/Model/PLPackage.h>

@interface ZBPackageFilesViewController () {
    NSMutableArray *files;
}
@property (nonatomic, strong) PLPackage *package;
@end

@implementation ZBPackageFilesViewController

- (id)initWithPackage:(PLPackage *)package {
    self = [super init];

    if (self) {
        self.package = package;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    files = [NSMutableArray new];
    [self getInstalledFiles];
    [self setTitle:NSLocalizedString(@"Installed Files", @"")];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)getInstalledFiles {
    NSArray *installedFiles = [self.package installedFiles];
    installedFiles = [installedFiles sortedArrayUsingSelector:@selector(compare:)];

    for (int i = 0; i < installedFiles.count; ++i) {
        NSString *file = installedFiles[i];
        if ([file isEqualToString:@"/."] || file.length == 0) {
            continue;
        }

        NSArray *components = [file componentsSeparatedByString:@"/"];
        NSMutableString *displayStr = [NSMutableString new];
        for (int b = 0; b < components.count - 2; ++b) {
            [displayStr appendString:@"\t"]; // add tab character
        }
        if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionLeftToRight) {
            [displayStr appendString:components[components.count - 1]];
        } else {
            [displayStr insertString:components[components.count - 1] atIndex:0];
        }

        [files addObject:displayStr];
    }
}

- (void)reloadTableView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"fileCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = [files objectAtIndex:indexPath.row];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.textColor = [ZBColor labelColor];
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30;
}

@end
