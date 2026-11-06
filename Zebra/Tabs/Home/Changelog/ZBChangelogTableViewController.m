//
//  ZBChangelogTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBChangelogTableViewController.h"

#import "ZBLog.h"
#import "ZBDevice.h"
#import "ZBSettings.h"
#import "UIColor+GlobalColors.h"
#import "ZBChangelogEntryCell.h"
#import "ZBLabelTextView.h"
#import "NSURLSession+Zebra.h"
#import "ZBGitHubRelease.h"

@interface ZBChangelogTableViewController ()

@end

@implementation ZBChangelogTableViewController {
    NSMutableDictionary <NSNumber *, NSMutableAttributedString *> *_attributedStrings;
}

@synthesize releases;

- (BOOL)hasSpinner {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }

    [self.tableView registerClass:[ZBChangelogEntryCell class] forCellReuseIdentifier:@"changeLogCell"];

    // Prevent additional separator lines from being displayed, especially while loading.
    self.tableView.tableHeaderView = [[UIView alloc] init];
    self.tableView.tableFooterView = [[UIView alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (releases == NULL) {
        releases = [NSMutableArray new];
        [self fetchGithubReleases];
    }
}

- (void)fetchGithubReleases {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:@"https://api.github.com/repos/zbrateam/Zebra/releases"]];
    [request setValue:@"application/vnd.github.v3.html" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionDataTask *task = [[NSURLSession zbra_standardSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, __unused NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSMutableArray <ZBGitHubRelease *> *releases = [NSMutableArray array];
        if (data && !error) {
            NSArray <ZBGitHubRelease *> *allReleases = [ZBGitHubRelease arrayFromData:data error:nil];

            NSRange r1 = [@PACKAGE_VERSION rangeOfString:@"~"];
            if (r1.location != NSNotFound) {
                NSRange r2 = [@PACKAGE_VERSION rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet] options:0 range:NSMakeRange(r1.location, @PACKAGE_VERSION.length - r1.location)];
                NSRange rSub = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
                NSString *releaseType = [@PACKAGE_VERSION substringWithRange:rSub];
                for (ZBGitHubRelease *release in allReleases) {
                    if ([release.tagName containsString:releaseType]) {
                        [releases addObject:release];
                    }
                }
            }
            else {
                for (ZBGitHubRelease *release in allReleases) {
                    if (!release.prerelease) {
                        [releases addObject:release];
                    }
                }
            }

        }
        else {
            ZBLog(@"[Zebra] Error while trying to access GitHub releases: %@", error);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self->releases addObjectsFromArray:releases];
            self->_attributedStrings = [NSMutableDictionary dictionary];
            [self.tableView reloadData];
            self.navigationItem.titleView = NULL;
            self.navigationItem.title = NSLocalizedString(@"Changelog", @"");
        });
    }];
    
    [task resume];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return releases.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"changeLogCell";
    ZBGitHubRelease *release = releases[indexPath.section];

    ZBChangelogEntryCell *cell = (ZBChangelogEntryCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    NSMutableAttributedString *attributedString = _attributedStrings[@(indexPath.section)];
    if (!attributedString) {
        attributedString = [ZBLabelTextView attributedStringWithBody:release.bodyHTML];
        _attributedStrings[@(indexPath.section)] = attributedString;
    }
    [attributedString addAttributes:@{
        NSForegroundColorAttributeName: [UIColor primaryTextColor]
    } range:NSMakeRange(0, attributedString.length)];
    cell.attributedString = attributedString;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return releases[section].name;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"alphabeticalReuse"];
    view.textLabel.font = [UIFont boldSystemFontOfSize:15];
    view.textLabel.textColor = [UIColor primaryTextColor];

    if (@available(iOS 13, *)) {
    } else {
        view.contentView.backgroundColor = [UIColor tableViewBackgroundColor];
    }

    return view;
}

@end
