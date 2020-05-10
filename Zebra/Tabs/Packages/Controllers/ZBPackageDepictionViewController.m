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

#import <Sources/Helpers/ZBSource.h>

@interface ZBPackageDepictionViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *tagLineLabel;
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
    
    NSLog(@"first sub: %@", self.view.subviews[0]);
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
    
    // Package Icon
    self.iconImageView.layer.cornerRadius = 20;
    self.iconImageView.layer.borderWidth = 1;
    self.iconImageView.layer.borderColor = [[UIColor colorWithRed: 0.90 green: 0.90 blue: 0.92 alpha: 1.00] CGColor]; // TODO: Don't hardcode
    
    // Buttons
    self.getButton.layer.cornerRadius = self.getButton.frame.size.height / 2;
    self.moreButton.layer.cornerRadius = self.moreButton.frame.size.height / 2;
    
    self.webView.hidden = YES;
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    self.navigationController.navigationBar.translucent = YES;
//    self.navigationController.navigationBar.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
    self.navigationController.navigationBar._backgroundOpacity = 0.0;
    
//    self.extendedLayoutIncludesOpaqueBars = YES;
//    self.edgesForExtendedLayout = UIRectEdgeTop;
    
//    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
//    self.scrollView.backgroundColor = [UIColor blueColor];
//    self.view.backgroundColor = [UIColor purpleColor];
//    self.navigationController.navigationBar.translucent = YES;
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

- (IBAction)getButtonPressed:(id)sender {
    [ZBPackageActions buttonActionForPackage:self.package]();
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4; // For now just four but once we set up a proper data source this will be variable
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Information", @"");
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"informationCell"];
    
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
    CGFloat maximumVerticalOffset = self.headerView.frame.size.height;
    CGFloat currentVerticalOffset = scrollView.contentOffset.y;
    CGFloat percentageVerticalOffset = currentVerticalOffset / maximumVerticalOffset;

//    UIColor *color = [UIColor colorWithWhite:1.0 alpha:percentageVerticalOffset];
//    self.navigationController.navigationBar.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:percentageVerticalOffset];
    self.navigationController.navigationBar._backgroundOpacity = percentageVerticalOffset;
}

@end
