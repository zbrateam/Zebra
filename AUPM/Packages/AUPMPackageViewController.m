//
//  AUPMPackageViewController.m
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "AUPMPackageViewController.h"
#import "AUPMPackage.h"
#import "AUPMConsoleViewController.h"
#import "AUPMQueue.h"
#import "AUPMQueueViewController.h"
#import "AUPMWebViewController.h"
#import "MobileGestalt.h"
#include <sys/sysctl.h>

@interface AUPMPackageViewController () {
    BOOL _isFinishedLoading;
    WKWebView *_webView;
    AUPMPackage *_package;
    UIProgressView *_progressBar;
    NSTimer *_progressTimer;
    BOOL loadFailed;
}

@end

@implementation AUPMPackageViewController

//- (void)viewDidLoad {
//    [super viewDidLoad];
//    // Do any additional setup after loading the view.
//}

- (id)initWithPackage:(AUPMPackage *)package {
    _package = package;
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self configureNavButton];
}

- (void)loadView {
    [super loadView];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0]];
    CGFloat height = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height + self.tabBarController.tabBar.frame.size.height;
    _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height - height)];
    _webView.customUserAgent = @"Cydia/ButActuallyAUPM";
    _webView.opaque = false;
    _webView.backgroundColor = [UIColor clearColor];
    [_webView setNavigationDelegate:self];
    NSURL *depictionURL = [NSURL URLWithString: [_package depictionURL]];
    
    if (depictionURL != NULL) {
        [_webView loadRequest:[[NSURLRequest alloc] initWithURL:depictionURL]];
    }
    else {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"package_depiction" withExtension:@".html"];
        [_webView loadFileURL:url allowingReadAccessToURL:[url URLByDeletingLastPathComponent]];
    }
    
    _webView.allowsBackForwardNavigationGestures = true;
    _progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 9)];
    [_webView addSubview:_progressBar];
    [self.view addSubview:_webView];
    
    self.title = [_package packageName];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURLRequest *request = [navigationAction request];
    NSURL *url = [request URL];
    
    if ([[url absoluteString] isEqualToString:[_package depictionURL]] || [_package depictionURL] == NULL || loadFailed) {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    else {
        AUPMWebViewController *webViewController = [[AUPMWebViewController alloc] initWithURL:url];
        [[self navigationController] pushViewController:webViewController animated:true];
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self->_webView.frame = self.view.frame;
    } completion:nil];
}

- (NSString *)generateDepiction {
    NSError *error;
    NSString *rawDepiction = [NSString stringWithContentsOfFile:@"/Applications/AUPM.app/package_depiction.html" encoding:NSUTF8StringEncoding error:&error];
    
    if (error != nil) {
        NSLog(@"[AUPM] Error reading file: %@", error);
    }
    
    NSString *html = [NSString stringWithFormat:rawDepiction, [_package packageName], [_package packageName], [_package packageIdentifier], [_package version], [_package packageDescription]];
    
    return html;
}

- (void)configureNavButton {
    if ([_package isInvalidated]) {
        NSLog(@"[AUPM] Object Invalidated!");
        [[self navigationController] popViewControllerAnimated:true];
    }
    else {
        if ([_package isInstalled]) {
            if ([_package isFromRepo]) {
                UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithTitle:@"Modify" style:UIBarButtonItemStylePlain target:self action:@selector(modifyPackage)];
                self.navigationItem.rightBarButtonItem = removeButton;
            }
            else {
                UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithTitle:@"Remove" style:UIBarButtonItemStylePlain target:self action:@selector(removePackage)];
                self.navigationItem.rightBarButtonItem = removeButton;
            }
        }
        else {
            UIBarButtonItem *installButton = [[UIBarButtonItem alloc] initWithTitle:@"Install" style:UIBarButtonItemStylePlain target:self action:@selector(installPackage)];
            self.navigationItem.rightBarButtonItem = installButton;
        }
    }
}

- (void)modifyPackage {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *removeAction = [UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [alert dismissViewControllerAnimated:true completion:nil];

        AUPMQueue *queue = [AUPMQueue sharedInstance];
        [queue addPackage:self->_package toQueueWithAction:AUPMQueueActionRemove];

        AUPMQueueViewController *queueVC = [[AUPMQueueViewController alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:queueVC];
        [self presentViewController:navController animated:true completion:nil];
    }];

    UIAlertAction *reinstallAction = [UIAlertAction actionWithTitle:@"Reinstall" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [alert dismissViewControllerAnimated:true completion:nil];

        AUPMQueue *queue = [AUPMQueue sharedInstance];
        [queue addPackage:self->_package toQueueWithAction:AUPMQueueActionReinstall];

        AUPMQueueViewController *queueVC = [[AUPMQueueViewController alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:queueVC];
        [self presentViewController:navController animated:true completion:nil];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        [alert dismissViewControllerAnimated:true completion:nil];
    }];

    [alert addAction:removeAction];
    [alert addAction:reinstallAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)installPackage {
    AUPMQueue *queue = [AUPMQueue sharedInstance];
    [queue addPackage:_package toQueueWithAction:AUPMQueueActionInstall];

    AUPMQueueViewController *queueVC = [[AUPMQueueViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:queueVC];
    [self presentViewController:navController animated:true completion:nil];
}

- (void)removePackage {
    AUPMQueue *queue = [AUPMQueue sharedInstance];
    [queue addPackage:_package toQueueWithAction:AUPMQueueActionRemove];
    
    AUPMQueueViewController *queueVC = [[AUPMQueueViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:queueVC];
    [self presentViewController:navController animated:true completion:nil];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [_progressTimer invalidate];
    _progressBar.hidden = false;
    _progressBar.alpha = 1.0;
    _progressBar.progress = 0;
    _progressBar.trackTintColor = [UIColor clearColor];
    _isFinishedLoading = false;
    _progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01667 target:self selector:@selector(refreshProgress) userInfo:nil repeats:YES];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    _isFinishedLoading = TRUE;
    
    NSURL *depictionURL = [NSURL URLWithString:[_package depictionURL]];
    if (depictionURL == NULL || loadFailed) {
        [_webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('package').innerHTML = '%@ (%@)';", [_package packageName], [_package packageIdentifier]] completionHandler:nil];
        [_webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('version').innerHTML = 'Version %@';", [_package version]] completionHandler:nil];
        
        NSLog(@"%@", [_package packageDescription]);
        if ([_package packageDescription] == NULL || [[_package packageDescription] isEqual:@""])  {
            [_webView evaluateJavaScript:@"var element = document.getElementById('desc');element.parentNode.parentNode.outerHTML = '';" completionHandler:nil];
        }
        else {
            [_webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('desc').innerHTML = \"%@\";", [_package packageDescription]] completionHandler:nil];
        }
//        NSString *command = [NSString stringWithFormat:@"document.getElementById('depiction-src').src = '%@';", [depictionURL absoluteString]];
//        [_webView evaluateJavaScript:command completionHandler:^(id Result, NSError * error) {
//            NSLog(@"[AUPM] Error: %@", error);
//        }];
    }
}

-(void)refreshProgress {
    if (_isFinishedLoading) {
        if (_progressBar.progress >= 1) {
            [UIView animateWithDuration:0.3 delay:0.3 options:0 animations:^{
                self->_progressBar.alpha = 0.0;
            } completion:^(BOOL finished) {
                [self->_progressTimer invalidate];
                self->_progressTimer = nil;
            }];
        }
        else {
            _progressBar.progress += 0.1;
        }
    }
    else {
        if (_progressBar.progress >= _webView.estimatedProgress) {
            _progressBar.progress = _webView.estimatedProgress;
        }
        else {
            _progressBar.progress += 0.005;
        }
        
        if (_progressBar.progress == 1.0) {
            loadFailed = true;
            NSURL *url = [[NSBundle mainBundle] URLForResource:@"package_depiction" withExtension:@".html"];
            [_webView loadFileURL:url allowingReadAccessToURL:[url URLByDeletingLastPathComponent]];
        }
    }
}

@end
