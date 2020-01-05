//
//  ZBChangelogTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBChangelogTableViewController.h"
#import <ZBLog.h>

@interface ZBChangelogTableViewController ()

@end

@implementation ZBChangelogTableViewController

@synthesize releases;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.titleView = spinner;
    [spinner startAnimating];
    
    [self.tableView setBackgroundColor:[UIColor tableViewBackgroundColor]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    
    if (releases == NULL) {
        releases = [NSMutableArray new];
        [self fetchGithubReleases];
    }
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)fetchGithubReleases {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:@"https://api.github.com/repos/wstyres/Zebra/releases"]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data && !error) {
            NSMutableArray *allReleases = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSRange r1 = [PACKAGE_VERSION rangeOfString:@"~"];
            if (r1.location != NSNotFound) {
                NSRange r2 = [PACKAGE_VERSION rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet] options:0 range:NSMakeRange(r1.location, PACKAGE_VERSION.length - r1.location)];
                NSRange rSub = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
                NSString *releaseType = [PACKAGE_VERSION substringWithRange:rSub];
                for (NSDictionary *release in allReleases) {
                    if ([[release objectForKey:@"tag_name"] containsString:releaseType]) {
                        [self->releases addObject:release];
                    }
                }
            }
            else {
                for (NSDictionary *release in allReleases) {
                    if (![[release objectForKey:@"prerelease"] boolValue]) {
                        [self->releases addObject:release];
                    }
                }
            }

        }
        else {
            ZBLog(@"[Zebra] Error while trying to access GitHub releases: %@", error);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            self.navigationItem.titleView = NULL;
            self.navigationItem.title = NSLocalizedString(@"Changelog", @"");
        });
    }];
    
    [task resume];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [releases count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"changeLogCell";
    NSDictionary *dataDict = [releases objectAtIndex:indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    if ([dataDict objectForKey:@"body"]) {
        [cell.textLabel setText:dataDict[@"body"]];
    }
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *jsonDict = [releases objectAtIndex:section];
    return jsonDict[@"name"] ? jsonDict[@"name"] : @"Error";
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"alphabeticalReuse"];
    view.textLabel.font = [UIFont boldSystemFontOfSize:15];
    view.textLabel.textColor = [UIColor cellPrimaryTextColor];
    view.contentView.backgroundColor = [UIColor tableViewBackgroundColor];
        
    return view;
}

@end
