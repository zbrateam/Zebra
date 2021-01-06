//
//  ZBHomeViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/5/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBHomeViewController.h"

#import <UI/Common/Views/ZBBoldTableViewHeaderView.h>
#import "ZBFeaturedPackagesCollectionView.h"

@interface ZBHomeViewController ()
@property (nonatomic) UITableView *communityNewsView;
@property (nonatomic) UICollectionView *featuredPackagesView;
@property (nonatomic) UIStackView *stackView;
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
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:@"communityNewsCell" forIndexPath:indexPath];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.textLabel.text = @"News";
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
