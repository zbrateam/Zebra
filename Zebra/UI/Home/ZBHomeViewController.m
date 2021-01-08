//
//  ZBHomeViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/5/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBHomeViewController.h"

#import <UI/Common/Views/ZBBoldTableViewHeaderView.h>
#import <UI/Home/Views/ZBCommunityNewsTableView.h>
#import <UI/Packages/Views/ZBFeaturedPackagesCollectionView.h>

#import <Extensions/UIColor+GlobalColors.h>

@import SafariServices;

@interface ZBHomeViewController ()
@property (nonatomic) ZBCommunityNewsTableView *communityNewsView;
@property (nonatomic) ZBFeaturedPackagesCollectionView *featuredPackagesView;
@property (nonatomic) UIStackView *stackView;
@property (nonatomic) NSArray <NSDictionary <NSString *, NSString *> *> *communityNews;
@property (nonatomic) NSLayoutConstraint *featuredPackagesViewHeightConstraint;
@property (nonatomic) NSLayoutConstraint *communityNewsViewHeightConstraint;
@end

@implementation ZBHomeViewController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.title = @"Zebra";
        
        _communityNewsView = [[ZBCommunityNewsTableView alloc] init];
        
        _featuredPackagesView = [[ZBFeaturedPackagesCollectionView alloc] initWithFrame:CGRectZero];
        
        _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_featuredPackagesView, _communityNewsView]];
        _stackView.axis = UILayoutConstraintAxisVertical;
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    [self.view addSubview:_stackView];
    [NSLayoutConstraint activateConstraints:@[
        [[_stackView leadingAnchor] constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [[_stackView trailingAnchor] constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [[_stackView topAnchor] constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [[_stackView bottomAnchor] constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _featuredPackagesViewHeightConstraint =
    [_featuredPackagesView.heightAnchor constraintEqualToConstant:_featuredPackagesView.collectionViewLayout.collectionViewContentSize.height];
    _featuredPackagesViewHeightConstraint.active = YES;
    _featuredPackagesView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _communityNewsViewHeightConstraint =
    [_communityNewsView.heightAnchor constraintEqualToConstant:_communityNewsView.contentSize.height];
    _communityNewsViewHeightConstraint.active = YES;
    _communityNewsView.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)viewDidLoad {
    [_communityNewsView fetch];
    [_featuredPackagesView fetch];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _featuredPackagesViewHeightConstraint.constant = _featuredPackagesView.collectionViewLayout.collectionViewContentSize.height;
    _communityNewsViewHeightConstraint.constant = _communityNewsView.contentSize.height;
}


@end
