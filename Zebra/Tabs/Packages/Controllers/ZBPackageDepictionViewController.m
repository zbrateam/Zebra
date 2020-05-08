//
//  ZBPackageDepictionViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/23/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageDepictionViewController.h"

@interface ZBPackageDepictionViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (strong, nonatomic) IBOutlet UIButton *getButton;
@property (strong, nonatomic) IBOutlet UIButton *moreButton;
@property (strong, nonatomic) IBOutlet WKWebView *webView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *webViewHeightConstraint;
@end

@implementation ZBPackageDepictionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _iconImageView.layer.cornerRadius = 20;
    _iconImageView.layer.borderWidth = 1;
    _iconImageView.layer.borderColor = [[UIColor grayColor] CGColor];
    _iconImageView.image = [UIImage imageNamed:@"icon"];
    
    _getButton.layer.cornerRadius = _getButton.frame.size.height / 2;
    _moreButton.layer.cornerRadius = _moreButton.frame.size.height / 2;
    
    _webView.hidden = YES;
    _webView.navigationDelegate = self;
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://getzbra.com/repo/depictions/xyz.willy.Zebra/"]]];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.webViewHeightConstraint.constant = self.webView.scrollView.contentSize.height;
        [[self view] layoutIfNeeded];
        webView.hidden = NO;
    });
}

@end
