//
//  ZBChangeLogTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBChangeLogTableViewController.h"

@interface ZBChangeLogTableViewController ()

@end

@implementation ZBChangeLogTableViewController
@synthesize changeLogArray;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"Changelog"];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchGithubReleases];
}

- (void)fetchGithubReleases {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:@"https://api.github.com/repos/wstyres/Zebra/releases"]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          if (data && !error) {
              self->changeLogArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
              dispatch_async(dispatch_get_main_queue(), ^{
                  [self.tableView reloadData];
              });
          }
          if (error) {
              NSLog(@"[Zebra] Github error %@", error);
          }
      }] resume];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [changeLogArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"changeLogCell";
    NSDictionary *dataDict = [changeLogArray objectAtIndex:indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    if ([dataDict objectForKey:@"body"]) {
        [cell.textLabel setText:dataDict[@"body"]];
    }
    [cell.textLabel setNumberOfLines:0];
    [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *jsonDict = [changeLogArray objectAtIndex:section];
    return jsonDict[@"name"] ? jsonDict[@"name"] : @"Error";
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.backgroundColor = [UIColor tableViewBackgroundColor];
    header.textLabel.font = [UIFont boldSystemFontOfSize:15];
    header.textLabel.textColor = [UIColor cellPrimaryTextColor];
    header.tintColor = [UIColor clearColor];
    [(UIView *)[header valueForKey:@"_backgroundView"] setBackgroundColor:[UIColor tableViewBackgroundColor]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 30;
        default :
            return 45;
    }
}

@end
