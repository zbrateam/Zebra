//
//  ZBHomeViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/5/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBHomeViewController.h"

#import <Managers/ZBPackageManager.h>
#import <UI/Packages/Views/ZBFeaturedPackagesCollectionView.h>
#import <UI/Common/Views/ZBBoldHeaderView.h>
#import <UI/Packages/Views/ZBPackageCollectionView.h>
#import <UI/Home/Views/ZBCommunityNewsTableView.h>

#import <Extensions/UIColor+GlobalColors.h>

@import SafariServices;

@interface ZBHomeViewController ()
@property (nonatomic) ZBFeaturedPackagesCollectionView *featuredPackagesView;
@property (nonatomic) ZBPackageCollectionView *changesCollectionView;
@property (nonatomic) ZBCommunityNewsTableView *communityNewsView;
@property (nonatomic) UIStackView *stackView;
@property (nonatomic) NSArray <NSDictionary <NSString *, NSString *> *> *communityNews;
@property (nonatomic) NSLayoutConstraint *featuredPackagesViewHeightConstraint;
@property (nonatomic) NSLayoutConstraint *changesCollectionViewHeightConstraint;
@property (nonatomic) NSLayoutConstraint *communityNewsViewHeightConstraint;
@property (nonatomic) UIScrollView *scrollView;
@end

@implementation ZBHomeViewController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.title = @"Zebra";
        
        _featuredPackagesView = [[ZBFeaturedPackagesCollectionView alloc] init];
        ZBBoldHeaderView *header = [[ZBBoldHeaderView alloc] init];
        header.titleLabel.text = @"What's New";
        header.actionButton.hidden = NO;
        [header.actionButton setTitle:@"See All" forState:UIControlStateNormal];
        _changesCollectionView = [[ZBPackageCollectionView alloc] init];
        _communityNewsView = [[ZBCommunityNewsTableView alloc] init];
        
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        
        _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_featuredPackagesView, header, _changesCollectionView, _communityNewsView]];
        _stackView.axis = UILayoutConstraintAxisVertical;
        _stackView.spacing = 8;
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    _scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:_scrollView];
    [NSLayoutConstraint activateConstraints:@[
        [[_scrollView leadingAnchor] constraintEqualToAnchor:self.view.leadingAnchor],
        [[_scrollView trailingAnchor] constraintEqualToAnchor:self.view.trailingAnchor],
        [[_scrollView topAnchor] constraintEqualToAnchor:self.view.topAnchor],
        [[_scrollView bottomAnchor] constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_scrollView addSubview:_stackView];
    [NSLayoutConstraint activateConstraints:@[
        [[_stackView leadingAnchor] constraintEqualToAnchor:_scrollView.leadingAnchor],
        [[_stackView trailingAnchor] constraintEqualToAnchor:_scrollView.trailingAnchor],
        [[_stackView topAnchor] constraintEqualToAnchor:_scrollView.topAnchor],
        [[_stackView bottomAnchor] constraintEqualToAnchor:_scrollView.bottomAnchor],
        [[_stackView widthAnchor] constraintEqualToAnchor:_scrollView.widthAnchor],
    ]];
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _featuredPackagesViewHeightConstraint = [_featuredPackagesView.heightAnchor constraintEqualToConstant:_featuredPackagesView.itemSize.height + 16];
    _featuredPackagesViewHeightConstraint.active = YES;
    _featuredPackagesView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _changesCollectionViewHeightConstraint = [_changesCollectionView.heightAnchor constraintEqualToConstant:_changesCollectionView.itemSize.height];
    _changesCollectionViewHeightConstraint.active = YES;
    _changesCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _communityNewsViewHeightConstraint = [_communityNewsView.heightAnchor constraintEqualToConstant:_communityNewsView.contentSize.height];
    _communityNewsViewHeightConstraint.active = YES;
    _communityNewsView.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)viewDidLoad {
    [_featuredPackagesView fetch];
    _changesCollectionView.packages = [[ZBPackageManager sharedInstance] latestPackages:20];
    [_communityNewsView fetch];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _scrollView.refreshControl = [[UIRefreshControl alloc] init];
    [_scrollView.refreshControl addTarget:self action:@selector(refreshSources) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    _featuredPackagesViewHeightConstraint.constant = _featuredPackagesView.itemSize.height + 16;
    _changesCollectionViewHeightConstraint.constant = _changesCollectionView.itemSize.height * 3;
    _communityNewsViewHeightConstraint.constant = _communityNewsView.contentSize.height;
}

- (void)refreshSources {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_scrollView.refreshControl endRefreshing];
        });
    });
}


@end
