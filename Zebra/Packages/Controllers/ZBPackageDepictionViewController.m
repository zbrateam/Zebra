//
//  ZBPackageDepictionViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/23/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageDepictionViewController.h"
#import <Queue/ZBQueue.h>

@interface ZBPackageDepictionViewController () {
    UIProgressView *progressView;
    WKWebView *webView;
}
@property (nonatomic, strong) ZBPackage *package;
@end

@implementation ZBPackageDepictionViewController

- (id)initWithPackage:(ZBPackage *)package {
    if (!self) {
        self = [super init];
    }
    
    self.package = package;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self configureNavButton];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.95 alpha:1.0];
    self.navigationController.view.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.95 alpha:1.0];
    self.navigationItem.title = _package.name;
    
    self.navigationController.navigationBar.translucent = false;
    self.tabBarController.tabBar.translucent = false;
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"Zebra (Cydia) ~ %@", PACKAGE_VERSION];
    
//    WKUserContentController *controller = [[WKUserContentController alloc] init];
//    [controller addScriptMessageHandler:self name:@"observe"];
//    configuration.userContentController = controller;
    
    webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:webView];
    
    progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [webView addSubview:progressView];
    
    //Web View Layout
    
    [webView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
    [webView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor].active = YES;
    [webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    
    //Progress View Layout
    
    [progressView.trailingAnchor constraintEqualToAnchor:webView.trailingAnchor].active = YES;
    [progressView.leadingAnchor constraintEqualToAnchor:webView.leadingAnchor].active = YES;
    [progressView.topAnchor constraintEqualToAnchor:webView.topAnchor].active = YES;
    
    [progressView setTintColor:[UIColor colorWithRed:0.4 green:0.5 blue:0.97 alpha:1.0]];
    
    webView.navigationDelegate = self;
    webView.opaque = false;
    webView.backgroundColor = [UIColor clearColor];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"package_depiction" withExtension:@"html"];
    [webView loadFileURL:url allowingReadAccessToURL:[url URLByDeletingLastPathComponent]];
    
    [webView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == webView) {
        [progressView setAlpha:1.0f];
        [progressView setProgress:webView.estimatedProgress animated:YES];
        
        if (webView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self->progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self->progressView setProgress:0.0f animated:NO];
            }];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSURL *depictionURL = [_package depictionURL];
    
    [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('package').innerHTML = '%@ (%@)';", [_package name], [_package identifier]] completionHandler:nil];
    [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('version').innerHTML = 'Version %@';", [_package version]] completionHandler:nil];
    
    NSLog(@"[Zebra] Package Description: %@, Depiction URL: %@", [_package desc], [_package depictionURL]);
    if ([_package depictionURL] != NULL && ![[[_package depictionURL] absoluteString] isEqualToString:@""])  {
        [webView evaluateJavaScript:@"var element = document.getElementById('desc-holder').outerHTML = '';" completionHandler:nil];
        [webView evaluateJavaScript:@"var element = document.getElementById('main-holder').style.marginBottom = '0px';" completionHandler:nil];
        NSString *command = [NSString stringWithFormat:@"document.getElementById('depiction-src').src = '%@';", [depictionURL absoluteString]];
        [webView evaluateJavaScript:command completionHandler:nil];
    }
    else if (![[_package desc] isEqualToString:@""] && [_package desc] != NULL) {
        [webView evaluateJavaScript:@"var element = document.getElementById('depiction-src').outerHTML = '';" completionHandler:nil];
        [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('desc').innerHTML = \"%@\";", [_package desc]] completionHandler:nil];
    }
    else {
        [webView evaluateJavaScript:@"var element = document.getElementById('desc-holder').outerHTML = '';" completionHandler:nil];
    }
}

- (void)configureNavButton {
    if (_package.installed) {
        UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithTitle:@"Remove" style:UIBarButtonItemStylePlain target:self action:@selector(removePackage)];
        self.navigationItem.rightBarButtonItem = removeButton;
    }
    else {
        UIBarButtonItem *installButton = [[UIBarButtonItem alloc] initWithTitle:@"Install" style:UIBarButtonItemStylePlain target:self action:@selector(installPackage)];
        self.navigationItem.rightBarButtonItem = installButton;
    }
}
    
- (void)installPackage {
    ZBQueue *queue = [ZBQueue sharedInstance];
    [queue addPackage:_package toQueue:ZBQueueTypeInstall];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UINavigationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"queueController"];
    [self presentViewController:vc animated:true completion:nil];
}

- (void)removePackage {
    ZBQueue *queue = [ZBQueue sharedInstance];
    [queue addPackage:_package toQueue:ZBQueueTypeRemove];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UINavigationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"queueController"];
    [self presentViewController:vc animated:true completion:nil];
}

- (void)dealloc {
    [webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) context:nil];
}

@end
