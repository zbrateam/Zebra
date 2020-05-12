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
#import <Sources/Helpers/ZBSource.h>

@interface ZBPackageDepictionViewController () {
    BOOL shouldShowNavButtons;
}
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *tagLineLabel;
@property (strong, nonatomic) IBOutlet ZBActionButton *getButton;
@property (strong, nonatomic) IBOutlet UIButton *moreButton;
@property (strong, nonatomic) IBOutlet WKWebView *webView;
@property (weak, nonatomic) IBOutlet UITableView *informationTableView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIStackView *headerView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *webViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *informationTableViewHeightConstraint;

@property (strong, nonatomic) ZBPackage *package;
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
    [self configureGetButton];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self updateTableViewHeightBasedOnContent];
}

- (void)setData {
    self.nameLabel.text = self.package.name;
    self.tagLineLabel.text = self.package.longDescription ? self.package.shortDescription : self.package.authorName;
    [self.package setIconImageForImageView:self.iconImageView];
        
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.package.depictionURL]];
}

- (void)applyCustomizations {
    // Navigation
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self configureNavigationButtons];
    
    // Package Icon
    self.iconImageView.layer.cornerRadius = 20;
    self.iconImageView.layer.borderWidth = 1;
    self.iconImageView.layer.borderColor = [[UIColor colorWithRed: 0.90 green: 0.90 blue: 0.92 alpha: 1.00] CGColor]; // TODO: Don't hardcode
    
    // Buttons
    self.moreButton.layer.cornerRadius = self.moreButton.frame.size.height / 2;
    
    self.webView.hidden = YES;
    self.navigationController.navigationBar._backgroundOpacity = 0.0;
}

- (void)setDelegates {
    self.webView.navigationDelegate = self;
    
    self.informationTableView.delegate = self;
    self.informationTableView.dataSource = self;
    
    self.scrollView.delegate = self;
}

- (void)configureGetButton {
    [self.getButton setTitle:@"LOAD" forState:UIControlStateNormal]; // Activity indicator going here
    [ZBPackageActions buttonTitleForPackage:self.package completion:^(NSString * _Nullable text) {
        if (text) {
            [self.getButton setTitle:[text uppercaseString] forState:UIControlStateNormal];
        }
        else {
            [self.getButton setTitle:@"LOAD" forState:UIControlStateNormal]; // Activity indicator is going here
        }
    }];
}

- (void)updateTableViewHeightBasedOnContent {
    self.informationTableViewHeightConstraint.constant = self.informationTableView.contentSize.height;
}

- (IBAction)getButtonPressed:(id)sender {
    [ZBPackageActions buttonActionForPackage:self.package]();
}

- (void)configureNavigationButtons {
    if (!self.navigationItem.titleView) {
        UIView *container = [[UIView alloc] initWithFrame:self.navigationItem.titleView.frame];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        imageView.center = self.navigationItem.titleView.center;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.layer.cornerRadius = 5;
        imageView.layer.masksToBounds = YES;
        [self.package setIconImageForImageView:imageView];
        
        [container addSubview:imageView];
        self.navigationItem.titleView = container;
    }
    
    if (!self.navigationItem.rightBarButtonItem) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        view.backgroundColor = [UIColor blackColor];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:view];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        if (self->shouldShowNavButtons) {
            self.navigationItem.rightBarButtonItem.customView.alpha = 1.0;
            self.navigationItem.titleView.alpha = 1.0;
        }
        else {
            self.navigationItem.rightBarButtonItem.customView.alpha = 0.0;
            self.navigationItem.titleView.alpha = 0.0;
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10; // For now just four but once we set up a proper data source this will be variable
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Information", @"");
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"informationCell"];
    
    cell.textLabel.font = [UIFont systemFontOfSize:14.0];
    cell.textLabel.textColor = [UIColor secondaryLabelColor]; // TODO: Use Zebra colors
    
    cell.detailTextLabel.font = [UIFont systemFontOfSize:14.0];
    cell.detailTextLabel.textColor = [UIColor labelColor]; // TODO: Use Zebra colors
    
    // Temporary, need a proper data source
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Installed Version";
            cell.detailTextLabel.text = [self.package installedVersion];
            break;
        case 1:
            cell.textLabel.text = @"Bundle Identifier";
            cell.detailTextLabel.text = [self.package identifier];
            break;
        case 2:
            cell.textLabel.text = @"Size"; // Should this be installed or download size??
            cell.detailTextLabel.text = [self.package downloadSizeString];
            break;
        case 3:
            cell.textLabel.text = @"Source";
            cell.detailTextLabel.text = [self.package.source label];
        default:
            cell.textLabel.text = @"Ze";
            cell.detailTextLabel.text = @"Bruh";
    }
    
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
    if (scrollView != self.scrollView) return;
    
    CGFloat topSafeAreaInset = self.view.safeAreaInsets.top;
    CGFloat maximumVerticalOffset = self.headerView.frame.size.height;
    CGFloat currentVerticalOffset = scrollView.contentOffset.y + topSafeAreaInset;
    CGFloat percentageVerticalOffset = currentVerticalOffset / maximumVerticalOffset;
    
    if (percentageVerticalOffset > 1.0 && !shouldShowNavButtons) {
        shouldShowNavButtons = YES;
        
        [self configureNavigationButtons];
    }
    else if (percentageVerticalOffset < 1.0 && shouldShowNavButtons) {
        shouldShowNavButtons = NO;
        
        [self configureNavigationButtons];
    }
    
    self.navigationController.navigationBar._backgroundOpacity = MAX(0, MIN(1, percentageVerticalOffset));
}

@end
