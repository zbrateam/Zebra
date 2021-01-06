//
//  ZBHomeViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/5/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBHomeViewController.h"

#import <UI/Common/Views/ZBBoldTableViewHeaderView.h>
#import <UI/Packages/Views/ZBFeaturedPackagesCollectionView.h>

@interface ZBHomeViewController ()
@property (nonatomic) UITableView *communityNewsView;
@property (nonatomic) UICollectionView *featuredPackagesView;
@property (nonatomic) UIStackView *stackView;
@property (nonatomic) NSArray <NSDictionary <NSString *, NSString *> *> *communityNews;
@end

@implementation ZBHomeViewController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.title = @"Zebra";
        
        _communityNewsView = [[UITableView alloc] init];
        _communityNewsView.dataSource = self;
        _communityNewsView.delegate = self;
        [_communityNewsView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"communityNewsCell"];
        [_communityNewsView registerNib:[UINib nibWithNibName:@"ZBBoldTableViewHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"BoldTableViewHeaderView"];
        [_communityNewsView setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
        [_communityNewsView setTableFooterView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)]];
        
        _featuredPackagesView = [[ZBFeaturedPackagesCollectionView alloc] initWithFrame:CGRectMake(0, 0, 500, 500) collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
        
        _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_communityNewsView, _featuredPackagesView]];
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    [self.view addSubview:_stackView];
    [NSLayoutConstraint activateConstraints:@[
        [[_stackView leadingAnchor] constraintEqualToAnchor:self.view.leadingAnchor],
        [[_stackView trailingAnchor] constraintEqualToAnchor:self.view.trailingAnchor],
        [[_stackView topAnchor] constraintEqualToAnchor:self.view.topAnchor],
        [[_stackView bottomAnchor] constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _communityNewsView.backgroundView = activityIndicator;
    [activityIndicator startAnimating];
    
    [self fetchCommunityNews:^(NSArray *posts) {
        self->_communityNews = posts;
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_communityNewsView.backgroundView = nil;
            if (self->_communityNews.count) {
                [self->_communityNewsView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                self->_communityNewsView.hidden = YES;
            }
        });
    }];
}

#pragma mark - Community News

- (void)fetchCommunityNews:(void (^)(NSArray *posts))completion {
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
                                [chosenPosts addObject:data];
                                break;
                            }
                        }
                        
                        if (chosenPosts.count >= 3) break;
                    }
                }
            }
            
            completion(chosenPosts);
        }];
        
        [task resume];
    });
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _communityNews.count > 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MIN(_communityNews.count, 3);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:@"communityNewsCell" forIndexPath:indexPath];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *post = _communityNews[indexPath.row];
    cell.textLabel.text = post[@"title"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
