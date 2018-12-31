//
//  ZBHomepageViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/27/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBHomepageViewController.h"
#import <Database/ZBRefreshViewController.h>

@interface ZBHomepageViewController () {
    IBOutlet WKWebView *webView;
    IBOutlet UIProgressView *progressView;
}
@end

@implementation ZBHomepageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.applicationNameForUserAgent = @"AUPM/BETA";
    
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    [controller addScriptMessageHandler:self name:@"observe"];
    configuration.userContentController = controller;
    
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
    
    webView.navigationDelegate = self;
    webView.opaque = false;
    webView.backgroundColor = [UIColor clearColor];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"home" withExtension:@".html"];
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
    [self.navigationItem setTitle:[webView title]];
#if TARGET_OS_SIMULATOR
    [webView evaluateJavaScript:@"document.getElementById('neo').innerHTML = 'Wake up, Neo...'" completionHandler:nil];
#else
    [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('neo').innerHTML = \"You are running AUPM Version %@\"", @"BETA"] completionHandler:nil];
#endif
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSArray *contents = [message.body componentsSeparatedByString:@"~"];
    NSString *destination = (NSString *)contents[0];
    NSString *action = contents[1];
    
    if ([destination isEqual:@"local"]) {
        if ([action isEqual:@"nuke"]) {
            NSLog(@"war games");
            [self nukeDatabase];
        }
        else if ([action isEqual:@"sendBug"]) {
            NSLog(@"raid");
            [self sendBugReport];
        }
    }
    else if ([destination isEqual:@"web"]) {
        NSLog(@"go somewere else");
        
//        AUPMWebViewController *_webViewController = [[AUPMWebViewController alloc] initWithURL:[NSURL URLWithString:action]];
//        [[self navigationController] pushViewController:_webViewController animated:true];
    }
    else if ([destination isEqual:@"repo"]) {
        NSLog(@"repo yo!");
//        [self handleRepoAdd:action local:false];
    }
    else if ([destination isEqual:@"repo-local"]) {
        NSLog(@"repo but local yo.");
//        [self handleRepoAdd:action local:true];
    }
}

- (void)nukeDatabase {
    ZBRefreshViewController *refreshViewController = [[ZBRefreshViewController alloc] init];
    
    [[UIApplication sharedApplication] keyWindow].rootViewController = refreshViewController;
}

- (void)sendBugReport {
    if ([MFMailComposeViewController canSendMail]) {
        NSString *iosVersion = [NSString stringWithFormat:@"%@ running iOS %@", [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]];
        NSString *message = [NSString stringWithFormat:@"iOS Version: %@\nAUPM Version: %@\nAUPM Database Location: %@\n\nPlease describe the bug you are experiencing or feature you are requesting below: \n\n", iosVersion, @"BETA", @"somewhere"];
        
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        [mail setSubject:@"AUPM Beta Bug Report"];
        [mail setMessageBody:message isHTML:NO];
        [mail setToRecipients:@[@"wilson@styres.me"]];
        
        [self presentViewController:mail animated:YES completion:NULL];
    }
    else
    {
        NSLog(@"[AUPM] This device cannot send email");
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)refreshPage:(id)sender {
    [webView reload];
}

@end
