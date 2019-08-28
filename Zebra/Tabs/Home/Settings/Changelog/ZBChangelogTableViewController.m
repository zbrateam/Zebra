//
//  ZBChangelogTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBChangelogTableViewController.h"
#import <ZBChangelogTableViewCell.h>
#import <ZBLog.h>

@interface ZBChangelogTableViewController ()

@end

@implementation ZBChangelogTableViewController

@synthesize releases;

- (void)viewDidLoad {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.titleView = spinner;
    [spinner startAnimating];
    
    if (@available(iOS 11.0, *)) {
        [self.navigationItem setLargeTitleDisplayMode:UINavigationItemLargeTitleDisplayModeNever];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (releases == NULL) {
        [self fetchGitHubReleases];
    }
}

- (void)fetchGitHubReleases {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:@"https://api.github.com/repos/wstyres/Zebra/releases"]];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data && !error) {
            self.releases = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        }
        else {
            ZBLog(@"[Zebra] Error while trying to access changelog: %@", error);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            self.navigationItem.titleView = NULL;
            self.navigationItem.title = @"Changelog";
        });
    }];
    
    [task resume];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return releases.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBChangelogTableViewCell *cell = (ZBChangelogTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"changelogReleaseCell"];
    
    NSDictionary *release = [releases objectAtIndex:indexPath.row];
    
    [cell.versionLabel setText:[release objectForKey:@"name"]];
    [cell.versionLabel sizeToFit];
    
    NSString *dateString = [release objectForKey:@"published_at"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    
    NSDate *date = [dateFormatter dateFromString:dateString];
    dateFormatter.dateStyle = NSDateFormatterLongStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    [cell.dateLabel setText:[dateFormatter stringFromDate:date]];
    [cell.dateLabel sizeToFit];
    [cell.detailsLabel setText:[release objectForKey:@"body"]];
    
    return cell;
}

@end
