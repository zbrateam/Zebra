//
//  ZBCommunityNewsTableView.m
//  Zebra
//
//  Created by Wilson Styres on 1/7/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBCommunityNewsTableView.h"

#import <UI/Common/Views/ZBBoldTableViewHeaderView.h>

#import <Extensions/UIColor+GlobalColors.h>
#import <ZBDevice.h>

@implementation ZBCommunityNewsTableView

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.dataSource = self;
        self.delegate = self;
        
        self.scrollEnabled = NO;
        
        self.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
        self.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
        
        [self registerNib:[UINib nibWithNibName:@"ZBBoldTableViewHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"BoldTableViewHeaderView"];
    }
    
    return self;
}

#pragma mark - Properties

- (void)setPosts:(NSArray *)posts {
    @synchronized (_posts) {
        _posts = posts;
        
        [self hideSpinner];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.numberOfSections == 1 && self->_posts.count) {
                [self reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else if (self.numberOfSections == 0 && self->_posts.count) {
                [self insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [self deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        });
    }
}

#pragma mark - Fetching Data

- (void)fetch {
    [self showSpinner];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *redditURL = [NSURL URLWithString:@"https://reddit.com/r/jailbreak.json"];
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:redditURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSMutableArray *chosenPosts = [NSMutableArray new];
            if (data && !error) {
                NSError *parseError = NULL;
                NSDictionary *redditJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&parseError];
                if (!parseError) {
                    NSArray *allowedFlairs = @[@"free release", @"paid release", @"update", @"upcoming", @"news", @"tutorial", @"giveaway"];
                    NSArray *posts = redditJSON[@"data"][@"children"];
                    for (NSDictionary *post in posts) {
                        NSDictionary *data = post[@"data"];
                        if ([data[@"stickied"] boolValue]) continue;
                        
                        for (NSString *flair in allowedFlairs) {
                            if ([data[@"title"] rangeOfString:flair options:NSCaseInsensitiveSearch].location != NSNotFound) {
                                NSArray *comp = [data[@"title"] componentsSeparatedByString:@"]"];
                                if (comp.count > 1) {
                                    NSString *trimmedTitle = [comp.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                    NSURL *redditURL = [NSURL URLWithString:@"https://reddit.com/"];
                                    NSURL *postURL = [[NSURL alloc] initWithString:data[@"permalink"] relativeToURL:redditURL];
                                    NSDictionary *trimmedPost = @{@"title": trimmedTitle, @"flair": flair.uppercaseString, @"link": postURL};
                                    [chosenPosts addObject:trimmedPost];
                                }
                                break;
                            }
                        }
                        
                        if (chosenPosts.count >= 3) break;
                    }
                }
            }
            self.posts = chosenPosts;
        }];
        
        [task resume];
    });
}

#pragma mark - Activity Indicator

- (void)showSpinner {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.backgroundView = activityIndicator;
        [activityIndicator startAnimating];
    });
}

- (void)hideSpinner {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.backgroundView = nil;
    });
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.posts.count > 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MIN(self.posts.count, 3);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"communityNewsCell"];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *post = self.posts[indexPath.row];
    
    cell.textLabel.text = post[@"title"];
    cell.textLabel.textColor = [UIColor accentColor];
    cell.textLabel.font = [UIFont systemFontOfSize:cell.textLabel.font.pointSize weight:UIFontWeightMedium];
    
    cell.detailTextLabel.text = post[@"flair"];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:cell.detailTextLabel.font.pointSize weight:UIFontWeightMedium];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *post = self.posts[indexPath.row];
    NSURL *url = post[@"link"];
    if (url && ([url.scheme isEqual:@"http"] || [url.scheme isEqual:@"https"])) {
        [ZBDevice openURL:url sender:nil];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ZBBoldTableViewHeaderView *cell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"BoldTableViewHeaderView"];
    
    cell.actionButton.hidden = YES;
    cell.titleLabel.text = NSLocalizedString(@"Community News", @"");
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    return 45;
}

@end
