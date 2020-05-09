//
//  ZBPackageDepictionViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/23/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageDepictionViewController.h"
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageActions.h>

@interface ZBPackageDepictionViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *shortDescriptionLabel;
@property (strong, nonatomic) IBOutlet UIButton *getButton;
@property (strong, nonatomic) IBOutlet UIButton *moreButton;
@property (strong, nonatomic) IBOutlet WKWebView *webView;
@property (weak, nonatomic) IBOutlet UITableView *informationTableView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIStackView *headerView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *webViewHeightConstraint;

@property (strong, nonatomic) ZBPackage *package;
@end

@implementation ZBPackageDepictionViewController

- (id)initWithPackage:(ZBPackage *)package {
    self = [super init];
    
    if (self) {
        self.package = package;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    [self setData];
    [self applyCustomizations];
    [self setDelegates];
    [self configureGetButton];
}

- (void)setData {
    self.nameLabel.text = self.package.name;
    self.shortDescriptionLabel.text = self.package.shortDescription;
    [self.package setIconImageForImageView:self.iconImageView];
        
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.package.depictionURL]];
}

- (void)applyCustomizations {
    // Navigation
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    // Package Icon
    self.iconImageView.layer.cornerRadius = 20;
    self.iconImageView.layer.borderWidth = 1;
    self.iconImageView.layer.borderColor = [[UIColor colorWithRed: 0.90 green: 0.90 blue: 0.92 alpha: 1.00] CGColor]; // TODO: Don't hardcode
    
    // Buttons
    self.getButton.layer.cornerRadius = self.getButton.frame.size.height / 2;
    self.moreButton.layer.cornerRadius = self.moreButton.frame.size.height / 2;
    
    self.webView.hidden = YES;
    
//    if (@available(iOS 13.0, *)) {
//        UINavigationBarAppearance *navBarAppearance = [UINavigationBarAppearance new];
//        [navBarAppearance configureWithTransparentBackground];
//        navBarAppearance.backgroundColor = nil;
//        self.navigationItem.standardAppearance = navBarAppearance;
//        self.navigationItem.scrollEdgeAppearance = navBarAppearance;
//
//    }
//    else {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
        self.navigationController.navigationBar.translucent = YES;
        self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
//    }
}

- (void)setDelegates {
    self.webView.navigationDelegate = self;
    
    self.informationTableView.delegate = self;
    self.informationTableView.dataSource = self;
    
    self.scrollView.delegate = self;
}

- (void)configureGetButton {
    [self.getButton setTitle:@"LOAD" forState:UIControlStateNormal];
    [ZBPackageActions buttonTitleForPackage:self.package completion:^(NSString * _Nullable text) {
        [self.getButton setTitle:[text uppercaseString] forState:UIControlStateNormal];
    }];
}

- (IBAction)getButtonPressed:(id)sender {
    [ZBPackageActions buttonActionForPackage:self.package]();
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"informationCell"];
    
    cell.textLabel.text = @"Identifier";
    cell.detailTextLabel.text = [self.package identifier];
    
    return cell;
}

#pragma mark - WKNavigtaionDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.webViewHeightConstraint.constant = self.webView.scrollView.contentSize.height;
        [[self view] layoutIfNeeded];
        webView.hidden = NO;
    });
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat maximumVerticalOffset = self.headerView.frame.size.height;
    CGFloat currentVerticalOffset = scrollView.contentOffset.y;
    CGFloat percentageVerticalOffset = currentVerticalOffset / maximumVerticalOffset;

    UIColor *color = [UIColor colorWithWhite:1.0 alpha:percentageVerticalOffset];
    self.navigationController.navigationBar.backgroundColor = color;
}

@end
