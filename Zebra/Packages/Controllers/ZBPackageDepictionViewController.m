//
//  ZBPackageDepictionViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/23/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageDepictionViewController.h"
#import <Queue/ZBQueue.h>
#import <Database/ZBDatabaseManager.h>
#import <ZBAppDelegate.h>
#import <SafariServices/SafariServices.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Repos/Helpers/ZBRepo.h>
#import <ZBTabBarController.h>
#import <UIColor+GlobalColors.h>

@interface ZBPackageDepictionViewController () {
    UIProgressView *progressView;
    WKWebView *webView;
    NSArray *otherVersions;
    BOOL hasUpdate;
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
    
    self.navigationController.navigationBar.tintColor = [UIColor tintColor];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"Zebra (Cydia) ~ %@", PACKAGE_VERSION];
    
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
    
    [progressView setTintColor:[UIColor tintColor]];
    
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
    
    if (depictionURL != NULL && ![[depictionURL absoluteString] isEqualToString:@""])  {
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

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURLRequest *request = [navigationAction request];
    NSURL *url = [request URL];
    
    int type = navigationAction.navigationType;
    
    if ([navigationAction.request.URL isFileURL] || (type == -1 && [navigationAction.request.URL isEqual:[_package depictionURL]])) {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    else if (![navigationAction.request.URL isEqual:[NSURL URLWithString:@"about:blank"]]) {
        if (type != -1 && ([[url scheme] isEqualToString:@"http"] || [[url scheme] isEqualToString:@"https"])) {
            SFSafariViewController *sfVC = [[SFSafariViewController alloc] initWithURL:url];
            if (@available(iOS 10.0, *)) {
                sfVC.preferredControlTintColor = [UIColor tintColor];
            }
            [self presentViewController:sfVC animated:true completion:nil];
            decisionHandler(WKNavigationActionPolicyCancel);
        }
        else if ([[url scheme] isEqualToString:@"mailto"]) {
            [[UIApplication sharedApplication] openURL:url];
            decisionHandler(WKNavigationActionPolicyCancel);
        }
        else {
            decisionHandler(WKNavigationActionPolicyAllow);
        }
    }
    else {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void)configureNavButton {
    ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
//    NSLog(@"Package is installed %@ repoID %d", [databaseManager packageIsInstalled:_package] ? @"true" : @"false", [[_package repo] repoID]);
    if ([[_package repo] repoID] == 0 || [databaseManager packageIsInstalled:_package]) {
//        hasUpdate = [(ZBTabBarController *)self.tabBarController doesPackageIDHaveUpdate:[_package identifier]];
        
        sqlite3 *database;
        sqlite3_open([[ZBAppDelegate databaseLocation] UTF8String], &database);
        
        otherVersions = [databaseManager otherVersionsForPackage:_package inDatabase:database];
        if ([otherVersions count] > 1) { //Modify, reinstall, remove, downgrade (maybe)
            UIBarButtonItem *modifyButton = [[UIBarButtonItem alloc] initWithTitle:@"Modify" style:UIBarButtonItemStylePlain target:self action:@selector(modifyPackage)];
            self.navigationItem.rightBarButtonItem = modifyButton;
        }
        else { //Show remove, its just a local package
            UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithTitle:@"Remove" style:UIBarButtonItemStylePlain target:self action:@selector(removePackage)];
            self.navigationItem.rightBarButtonItem = removeButton;
        }
        
        sqlite3_close(database);
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

- (void)modifyPackage {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[_package name] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *remove = [UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        ZBQueue *queue = [ZBQueue sharedInstance];
        [queue addPackage:self->_package toQueue:ZBQueueTypeRemove];
        
        [alert dismissViewControllerAnimated:true completion:nil];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        UINavigationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"queueController"];
        [self presentViewController:vc animated:true completion:nil];
    }];
    
    [alert addAction:remove];
    
    UIAlertAction *reinstall = [UIAlertAction actionWithTitle:@"Reinstall" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        ZBQueue *queue = [ZBQueue sharedInstance];
        [queue addPackage:self->_package toQueue:ZBQueueTypeReinstall];
        
        [alert dismissViewControllerAnimated:true completion:nil];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        UINavigationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"queueController"];
        [self presentViewController:vc animated:true completion:nil];
    }];
    
    [alert addAction:reinstall];
    
    if ([otherVersions count] > 2) {
        UIAlertAction *downgrade = [UIAlertAction actionWithTitle:@"Downgrade" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:true completion:nil];
            [self downgradePackage];
        }];
        
        [alert addAction:downgrade];
    }
    
    if (hasUpdate) {
        UIAlertAction *upgrade = [UIAlertAction actionWithTitle:@"Upgrade" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ZBQueue *queue = [ZBQueue sharedInstance];
            [queue addPackage:self->_package toQueue:ZBQueueTypeUpgrade];
            
            [alert dismissViewControllerAnimated:true completion:nil];
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
            UINavigationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"queueController"];
            [self presentViewController:vc animated:true completion:nil];
        }];
        
        [alert addAction:upgrade];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:true completion:nil];
    }];
    
    [alert addAction:cancel];
    
    alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    
    [self presentViewController:alert animated:true completion:nil];
}

- (void)downgradePackage {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Downgrade %@", [_package name]] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (ZBPackage *downPackage in otherVersions) {
        if ([[downPackage repo] repoID] == 0 || [[downPackage version] isEqualToString:[_package version]]) {
            continue;
        }
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:[downPackage version] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ZBQueue *queue = [ZBQueue sharedInstance];
            [queue addPackage:downPackage toQueue:ZBQueueTypeInstall];
            
//            NSLog(@"Package repoID %d", [[downPackage repo] repoID]);
            
            [alert dismissViewControllerAnimated:true completion:nil];
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
            UINavigationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"queueController"];
            [self presentViewController:vc animated:true completion:nil];
        }];
        
        [alert addAction:action];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:true completion:nil];
    }];
    
    [alert addAction:cancel];
    
    alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    
    [self presentViewController:alert animated:true completion:nil];
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
