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
    NSDictionary *dataDict = releases[indexPath.section];

    ZBChangelogEntryCell *cell = (ZBChangelogEntryCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    NSMutableAttributedString *attributedString = _attributedStrings[@(indexPath.section)];
    if (!attributedString) {
        NSString *html = [NSString stringWithFormat:@"<!DOCTYPE html><html><head><meta charset=\"utf-8\"><style>"
                          @"body { font: -apple-system-body; }"
                          @"body > :last-child { margin-bottom: 0; }"
                          @"</style></head><body>%@</body></html>",
                          dataDict[@"body_html"] ?: @"Error"];
        attributedString = [[NSMutableAttributedString alloc] initWithData:[html dataUsingEncoding:NSUTF8StringEncoding] options:@{
            NSDocumentTypeDocumentOption: NSHTMLTextDocumentType
        } documentAttributes:nil error:nil];
        _attributedStrings[@(indexPath.section)] = attributedString;
    }
    [attributedString addAttributes:@{
        NSForegroundColorAttributeName: [UIColor primaryTextColor]
    } range:NSMakeRange(0, attributedString.length)];
    cell.attributedString = attributedString;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *jsonDict = releases[section];
    return jsonDict[@"name"] ?: @"Error";
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"alphabeticalReuse"];
    view.textLabel.font = [UIFont boldSystemFontOfSize:15];
    view.textLabel.textColor = [UIColor primaryTextColor];
    view.contentView.backgroundColor = [UIColor tableViewBackgroundColor];
        
    return view;
}

@end
