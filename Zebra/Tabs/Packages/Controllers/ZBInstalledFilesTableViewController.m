//
//  ZBInstalledFilesTableViewController.m
//  Zebra
//
//  Created by midnightchips on 7/13/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBInstalledFilesTableViewController.h"
#import "UIColor+GlobalColors.h"
@interface ZBInstalledFilesTableViewController ()

@end

@implementation ZBInstalledFilesTableViewController {
    NSMutableArray *files;
}

@synthesize package;

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableView) name:@"darkMode" object:nil];
    files = [NSMutableArray new];
    [self getInstalledFiles];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
}

- (void)getInstalledFiles {
    NSArray *installedFiles = [ZBPackage filesInstalled:package.identifier];
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
        [displayStr appendString:components[components.count - 1]];
        [files addObject:displayStr];
    }
}

- (void)reloadTableView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
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
    cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

@end
