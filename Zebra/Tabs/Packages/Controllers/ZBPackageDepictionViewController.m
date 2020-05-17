//
//  ZBPackageDepictionViewController.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-16.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBPackageDepictionViewController.h"
#import <Packages/Helpers/ZBPackage.h>
#import <ZBDevice.h>
#import "NSAttributedString+Markdown.h"
#import <Packages/Controllers/ZBPackageChangelogTableViewController.h>

@interface WKWebView ()
@property (setter=_setApplicationNameForUserAgent:,copy) NSString * _applicationNameForUserAgent;
@end

@interface ZBPackageDepictionViewController ()

// Web Outlets
@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewHeightConstraint;

// Native Outlets
@property (weak, nonatomic) IBOutlet UIView *nativeView;
@property (weak, nonatomic) IBOutlet UILabel *changelogNotesLabel;
@property (weak, nonatomic) IBOutlet UILabel *changelogVersionTitleLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *previewCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

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
}

#pragma mark - Methods Called From viewDidLoad

- (void)setDelegates {
    self.webView.navigationDelegate = self;
    self.webView.scrollView.delegate = self;
}

- (void)applyCustomizations {
    self.webView.hidden = YES;
    self.webView.scrollView.scrollEnabled = NO;
}

- (void)setData {
    [self loadWebDepiction];
    
    NSAttributedString *descriptionAttributedString = [[NSAttributedString alloc] initWithMarkdownString:self.package.packageDescription];
    [self.descriptionLabel setAttributedText:descriptionAttributedString];
    
    NSAttributedString *changelogNotesAttributedString = [[NSAttributedString alloc] initWithMarkdownString:self.package.changelogNotes];
    [self.changelogNotesLabel setAttributedText:changelogNotesAttributedString];
    
    [self.changelogVersionTitleLabel setText:self.package.changelogTitle];
}

#pragma mark - Helper Methods

- (void)loadWebDepiction {
    if (self.package.depictionURL == nil) return;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.package.depictionURL];
    [request setAllHTTPHeaderFields:[ZBDevice depictionHeaders]];
    self.webView._applicationNameForUserAgent = [ZBDevice depictionUserAgent];
    [self.webView.scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
//    [self.webView loadRequest:request];
}

- (IBAction)versionHistoryButtonTapped:(id)sender {
    ZBPackageChangelogTableViewController *changelog = [[ZBPackageChangelogTableViewController alloc] initWithPackage:self.package];
    [[self navigationController] pushViewController:changelog animated:YES];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
        webView.hidden = NO;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    // This is a pretty simple implementation now, it might cause problems later for depictions with ads but not sure at the moment.
    NSURL *url = navigationAction.request.URL;
    WKNavigationType type = navigationAction.navigationType;
    
    if ([url isEqual:self.webView.URL] || type == WKNavigationTypeOther) {
        decisionHandler(WKNavigationActionPolicyAllow);
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
        
        if (![[url absoluteString] isEqualToString:@"about:blank"] && ([[url scheme] isEqualToString:@"https"] || [[url scheme] isEqualToString:@"http"])) {
            [ZBDevice openURL:url sender:self];
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    [scrollView.pinchGestureRecognizer setEnabled:NO];
}

#pragma mark - WKWebView contentSize Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.webView.scrollView && [keyPath isEqual:@"contentSize"] && self.webViewHeightConstraint.constant != self.webView.scrollView.contentSize.height) {
        self.webViewHeightConstraint.constant = self.webView.scrollView.contentSize.height;
        [[self view] layoutIfNeeded];
    }
}

- (void)dealloc {
    if (self.package.depictionURL != nil) [self.webView.scrollView removeObserver:self forKeyPath:@"contentSize" context:nil];
}

@end
