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
#import "ZBActionButton.h"
#import "ZBBoldHeaderView.h"
#import "ZBInfoTableViewCell.h"
#import <Sources/Helpers/ZBSource.h>
#import <Extensions/UIColor+GlobalColors.h>
#import <Extensions/UINavigationBar+Extensions.h>
#import <ZBDevice.h>
#import <Downloads/ZBDownloadManager.h>

@interface ZBPackageDepictionViewController () {
    BOOL shouldShowNavButtons;
}
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *tagLineLabel;
@property (strong, nonatomic) IBOutlet ZBActionButton *getButton;
@property (strong, nonatomic) IBOutlet ZBActionButton *moreButton;
@property (strong, nonatomic) IBOutlet WKWebView *webView;
@property (weak, nonatomic) IBOutlet UITableView *informationTableView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIStackView *headerView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *webViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *informationTableViewHeightConstraint;

@property (strong, nonatomic) ZBPackage *package;
@property (strong, nonatomic) NSArray *packageInformation;
@property (strong, nonatomic) ZBActionButton *getBarButton;
@end

@implementation ZBPackageDepictionViewController

#pragma mark - Initializers

- (id)initWithPackage:(ZBPackage *)package {
    self = [super init];
    
    if (self) {
        self.package = package;
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setDelegates];
    [self applyCustomizations];
    [self setData];
    
    [self.informationTableView registerNib:[UINib nibWithNibName:NSStringFromClass([ZBInfoTableViewCell class]) bundle:nil] forCellReuseIdentifier:@"InfoTableViewCell"]; // TODO: Find a home for this line
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self updateTableViewHeightBasedOnContent];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController.navigationBar _setBackgroundOpacity:1];
}

#pragma mark - Methods Called From viewDidLoad

- (void)setDelegates {
    self.webView.navigationDelegate = self;
    
    self.informationTableView.delegate = self;
    self.informationTableView.dataSource = self;
    
    self.scrollView.delegate = self;
}

- (void)applyCustomizations {
    // Navigation
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self.navigationController.navigationBar _setBackgroundOpacity:0];
    [self configureNavigationItems];
    
    // Tagline label tapping
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAuthorName)];
    self.tagLineLabel.userInteractionEnabled = YES;
    [self.tagLineLabel addGestureRecognizer:gestureRecognizer];

    // Package Icon
    self.iconImageView.layer.cornerRadius = 20;
    self.iconImageView.layer.borderWidth = 1;
    self.iconImageView.layer.borderColor = [[UIColor colorWithRed: 0.90 green: 0.90 blue: 0.92 alpha: 1.00] CGColor]; // TODO: Don't hardcode
    
    // Buttons
    [self.moreButton setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)]; // We don't want this button to have the default contentEdgeInsets inherited by a ZBActionButton
    [self configureGetButton:self.getButton];
    [self configureGetButton:self.getBarButton];

    // Web View
    self.webView.hidden = YES;
    self.webView.scrollView.backgroundColor = [UIColor tableViewBackgroundColor];
}

- (void)setData {
    self.nameLabel.text = self.package.name;
    self.tagLineLabel.text = self.package.tagline ?: self.package.authorName;
    [self.package setIconImageForImageView:self.iconImageView];
    self.packageInformation = [self.package information];
    [self loadDepiction];
}

#pragma mark - Helper Methods

- (void)updateTableViewHeightBasedOnContent {
    self.informationTableViewHeightConstraint.constant = self.informationTableView.contentSize.height;
}

- (void)loadDepiction {
    if (self.package.depictionURL == nil) return;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.package.depictionURL];
    [request setAllHTTPHeaderFields:[ZBDevice depictionHeaders]];
    self.webView.customUserAgent = [ZBDevice depictionUserAgent];
    [self.webView.scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView loadRequest:request];
}

- (void)showAuthorName {
    [UIView transitionWithView:self.tagLineLabel duration:0.25f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.tagLineLabel.text = self.package.authorName;
    } completion:nil];
}

- (void)configureGetButton:(ZBActionButton *)button {
    [button showActivityLoader];
    [ZBPackageActions buttonTitleForPackage:self.package completion:^(NSString * _Nullable text) {
        if (text) {
            [button hideActivityLoader];
            [button setTitle:[text uppercaseString] forState:UIControlStateNormal];
        } else {
            [button showActivityLoader];
        }
    }];
}

- (IBAction)getButtonPressed:(id)sender {
    [ZBPackageActions buttonActionForPackage:self.package]();
}

- (void)configureNavigationItems {
    UIView *container = [[UIView alloc] initWithFrame:self.navigationItem.titleView.frame];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    imageView.center = self.navigationItem.titleView.center;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.layer.cornerRadius = 5;
    imageView.layer.masksToBounds = YES;
    imageView.alpha = 0.0;
    [self.package setIconImageForImageView:imageView];
    [container addSubview:imageView];
    self.navigationItem.titleView = container;
    
    self.getBarButton = [[ZBActionButton alloc] init];
    [self.getBarButton addTarget:self action:@selector(getButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.getBarButton];
    self.navigationItem.rightBarButtonItem.customView.alpha = 0.0;
}

- (void)setNavigationItemsHidden:(BOOL)hidden {
    [UIView animateWithDuration:0.25 animations:^{
        self.navigationItem.rightBarButtonItem.customView.alpha = hidden ? 0.0 : 1.0;
        self.navigationItem.titleView.subviews[0].alpha = hidden ? 0.0 : 1.0;
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.packageInformation count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ZBBoldHeaderView *headerView = [[ZBBoldHeaderView alloc] initWithFrame:CGRectZero];
    headerView.titleLabel.text = NSLocalizedString(@"Information", @"");
    
    return headerView;
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBInfoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InfoTableViewCell" forIndexPath:indexPath];
    
    cell.nameLabel.text = self.packageInformation[indexPath.row][@"name"];
    cell.valueLabel.text = self.packageInformation[indexPath.row][@"value"];
    
    return cell;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
        webView.hidden = NO;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    // This is a pretty simple implementation now, it might cause problems later for depictions with ads but not sure at the moment.
    NSURL *url = navigationAction.request.URL;
    if ([url isEqual:self.webView.URL]) {
        decisionHandler(WKNavigationActionPolicyAllow);
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
        
        SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url];
        safariVC.preferredControlTintColor = [UIColor accentColor];
        [self presentViewController:safariVC animated:YES completion:nil];
    }
}

#pragma mark - WKWebView contentSize Observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.webView.scrollView && [keyPath isEqual:@"contentSize"]) {
        if (self.webViewHeightConstraint.constant != self.webView.scrollView.contentSize.height) {
            NSLog(@"%f", self.webView.scrollView.contentSize.height);
            self.webViewHeightConstraint.constant = self.webView.scrollView.contentSize.height;
            [[self view] layoutIfNeeded];
        }
    }
}

- (void)dealloc {
    if (self.package.depictionURL != nil) [self.webView.scrollView removeObserver:self forKeyPath:@"contentSize" context:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.scrollView) return;
    
    CGFloat maximumVerticalOffset = self.headerView.frame.size.height - (self.getButton.bounds.size.height / 2);
    CGFloat currentVerticalOffset = scrollView.contentOffset.y + self.view.safeAreaInsets.top;
    CGFloat percentageVerticalOffset = currentVerticalOffset / maximumVerticalOffset;
    CGFloat opacity = MAX(0, MIN(1, percentageVerticalOffset));

    if (self.navigationController.navigationBar._backgroundOpacity == opacity) return; // Return if the opacity doesn't differ from what it is currently.
    
    [self setNavigationItemsHidden:(opacity < 1)];
    [self.navigationController.navigationBar _setBackgroundOpacity:opacity]; // Ensure the opacity is not negative or greater than 1.
}

@end
