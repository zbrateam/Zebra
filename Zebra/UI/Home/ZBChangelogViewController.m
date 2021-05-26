//
//  ZBChangelogViewController.m
//  Zebra
//
//  Created by midnightchips on 6/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBChangelogViewController.h"

#import <ZBLog.h>
#import <ZBDevice.h>
#import <ZBSettings.h>
#import <Extensions/ZBColor.h>

@implementation ZBChangelogViewController

- (instancetype)init {
    if (@available(iOS 13.0, macCatalyst 13.0, *)) {
        self = [super initWithStyle:UITableViewStyleInsetGrouped];
    } else {
        self = [super initWithStyle:UITableViewStyleGrouped];
    }
 
    if (self) {
        self.title = @"Changelog";
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.releases == NULL) {
        self.releases = [NSMutableArray new];
        [self fetchGithubReleases];
    }
}

- (void)fetchGithubReleases {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:@"https://api.github.com/repos/zbrateam/Zebra/releases"]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data && !error) {
            NSMutableArray *allReleases = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSRange r1 = [PACKAGE_VERSION rangeOfString:@"~"];
            if (r1.location != NSNotFound) {
                NSRange r2 = [PACKAGE_VERSION rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet] options:0 range:NSMakeRange(r1.location, PACKAGE_VERSION.length - r1.location)];
                NSString *releaseType;
                if (r2.location != NSNotFound) {
                    NSRange rSub = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
                    releaseType = [PACKAGE_VERSION substringWithRange:rSub];
                } else {
                    releaseType = [PACKAGE_VERSION substringFromIndex:r1.location + 1];
                }
                
                for (NSDictionary *release in allReleases) {
                    if ([[release objectForKey:@"tag_name"] containsString:releaseType]) {
                        [self.releases addObject:release];
                    }
                }
            }
            else {
                for (NSDictionary *release in allReleases) {
                    if (![[release objectForKey:@"prerelease"] boolValue]) {
                        [self.releases addObject:release];
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
            self.title = NSLocalizedString(@"Changelog", @"");
        });
    }];
    
    [task resume];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.releases.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"changeLogCell";
    NSDictionary *dataDict = self.releases[indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    if (dataDict[@"body"]) {
        cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:dataDict[@"body"]];
    }
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.textColor = [ZBColor labelColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *jsonDict = self.releases[section];
    return jsonDict[@"name"] ?: @"Error";
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"alphabeticalReuse"];
    view.textLabel.font = [UIFont boldSystemFontOfSize:15];
    view.textLabel.textColor = [ZBColor labelColor];
    view.contentView.backgroundColor = [ZBColor systemGroupedBackgroundColor];
        
    return view;
}

@end
