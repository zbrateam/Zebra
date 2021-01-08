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
@property (nonatomic) UICollectionView *featuredPackagesView;
@property (nonatomic) UIStackView *stackView;
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
        [[_stackView leadingAnchor] constraintEqualToAnchor:self.view.leadingAnchor],
        [[_stackView trailingAnchor] constraintEqualToAnchor:self.view.trailingAnchor],
        [[_stackView topAnchor] constraintEqualToAnchor:self.view.topAnchor],
        [[_stackView bottomAnchor] constraintEqualToAnchor:self.view.bottomAnchor],
        [[_featuredPackagesView heightAnchor] constraintEqualToAnchor:self.view.heightAnchor multiplier:0.40]
    ]];
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;
    _featuredPackagesView.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)viewDidLoad {
    [_communityNewsView fetch];
}

@end
