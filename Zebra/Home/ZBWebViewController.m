//
//  ZBWebViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/27/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBWebViewController.h"
#import <Database/ZBRefreshViewController.h>
#import <ZBAppDelegate.h>
#import <sys/utsname.h>
#import <Repos/Helpers/ZBRepoManager.h>
#import <UIColor+GlobalColors.h>

@interface ZBWebViewController () {
    NSURL *_url;
    IBOutlet WKWebView *webView;
    IBOutlet UIProgressView *progressView;
}

@property (nonatomic, retain) ZBRepoManager *repoManager;

@end

@implementation ZBWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.repoManager = [[ZBRepoManager alloc] init];
    
    self.navigationController.navigationBar.tintColor = [UIColor tintColor];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"Zebra - %@", PACKAGE_VERSION];
    
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
    webView.tintColor = [UIColor tintColor];
    
    if (_url != NULL) {
        if (@available(iOS 11.0, *)) {
            self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
        }
        
        NSURLRequest *request = [NSURLRequest requestWithURL:_url];
        [webView loadRequest:request];
    }
    else {
        self.title = @"Home";
        
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"home" withExtension:@".html"];
        [webView loadFileURL:url allowingReadAccessToURL:[url URLByDeletingLastPathComponent]];
    }
    
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
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *model = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('neo').innerHTML = \"%@ - iOS %@ - Zebra %@\"", model, [[UIDevice currentDevice] systemVersion], PACKAGE_VERSION] completionHandler:nil];
#endif
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSArray *contents = [message.body componentsSeparatedByString:@"~"];
    NSString *destination = (NSString *)contents[0];
    NSString *action = contents[1];
    NSString *url;
    if ([contents count] == 3) {
        url = contents[2];
    }
    
    if ([destination isEqual:@"local"]) {
        if ([action isEqual:@"nuke"]) {
            [self nukeDatabase];
        }
        else if ([action isEqual:@"sendBug"]) {
            [self sendBugReport];
        }
        else if ([action isEqual:@"doc"]) {
            [self openDocumentsDirectory];
        }
    }
    else if ([destination isEqual:@"web"]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ZBWebViewController *webController = [storyboard instantiateViewControllerWithIdentifier:@"webController"];
        webController->_url = [NSURL URLWithString:action];
        
        [[self navigationController] pushViewController:webController animated:true];
    }
    else if ([destination isEqual:@"repo"]) {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Add Repository" message:[NSString stringWithFormat:@"Are you sure you want to add the repository \"%@\"?", action] preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *yes = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self handleRepoAdd:url local:false];
        }];
        UIAlertAction *no = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [controller dismissViewControllerAnimated:true completion:nil];
        }];
        
        [controller addAction:yes];
        [controller addAction:no];
        
        [self presentViewController:controller animated:true completion:nil];
    }
    else if ([destination isEqual:@"repo-local"]) {
        if ([contents count] == 2) {
            if (![ZBAppDelegate needsSimulation]) {
                UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Add Repositories" message:@"Are you sure you want to transfer repositories from Cydia?" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *yes = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self handleRepoAdd:@"transfer" local:true];
                }];
                UIAlertAction *no = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [controller dismissViewControllerAnimated:true completion:nil];
                }];
                
                [controller addAction:yes];
                [controller addAction:no];
                
                [self presentViewController:controller animated:true completion:nil];
            }
            else {
                UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Error" message:@"This action is not supported on non-jailbroken devices" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"😢" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [controller dismissViewControllerAnimated:true completion:nil];
                }];
                
                [controller addAction:ok];
                
                [self presentViewController:controller animated:true completion:nil];
            }
        }
        else {
            UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Add Repository" message:[NSString stringWithFormat:@"Are you sure you want to add the repository \"%@\"?", action] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *yes = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self handleRepoAdd:url local:true];
            }];
            UIAlertAction *no = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [controller dismissViewControllerAnimated:true completion:nil];
            }];
            
            [controller addAction:yes];
            [controller addAction:no];
            
            [self presentViewController:controller animated:true completion:nil];
        }
    }
}

- (void)handleRepoAdd:(NSString *)repo local:(BOOL)local {
//    NSLog(@"[Zebra] Handling repo add for method %@", repo);
    if (local) {
        NSArray *options = @[
                             @"transfer",
                             @"cydia",
                             @"electra",
                             @"uncover",
                             @"bigboss",
                             @"modmyi",
                             ];
        
        switch ([options indexOfObject:repo]) {
            case 0:
//                NSLog(@"[Zebra] Transferring repos");
                [self.repoManager transferFromCydia];
                break;
            case 1:
                [self.repoManager addDebLine:[NSString stringWithFormat:@"deb http://apt.saurik.com/ ios/%.2f main\n", kCFCoreFoundationVersionNumber]];
                break;
            case 2:
                [self.repoManager addDebLine:@"deb https://electrarepo64.coolstar.org/ ./\n"];
                break;
            case 3:
                [self.repoManager addDebLine:[NSString stringWithFormat:@"deb http://apt.bingner.com/ ios/%.2f main\n", kCFCoreFoundationVersionNumber]];
                break;
            case 4:
                [self.repoManager addDebLine:@"deb http://apt.thebigboss.org/repofiles/cydia/ stable main\n"];
                break;
            case 5:
                [self.repoManager addDebLine:@"deb http://apt.modmyi.com/ stable main\n"];
                break;
            default:
                return;
        }
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *console = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
        [self presentViewController:console animated:true completion:nil];
    }
    else {
        __weak typeof(self) weakSelf = self;
        
        [self.repoManager addSourceWithString:repo response:^(BOOL success, NSString * _Nonnull error, NSURL * _Nonnull url) {
            if (!success) {
                NSLog(@"[Zebra] Could not add source %@ due to error %@", url.absoluteString, error);
            }
            else {
                NSLog(@"[Zebra] Added source.");
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                UIViewController *console = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
                [weakSelf presentViewController:console animated:true completion:nil];
            }
        }];
    }
}

- (void)nukeDatabase {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZBRefreshViewController *refreshController = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
    refreshController.dropTables = TRUE;
    
    [self presentViewController:refreshController animated:true completion:nil];
}

- (void)sendBugReport {
    if ([MFMailComposeViewController canSendMail]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *databasePath = [paths[0] stringByAppendingPathComponent:@"zebra.db"];
        
        NSString *message = [NSString stringWithFormat:@"iOS: %@\nZebra Version: %@\nDatabase Location: %@\n\nPlease describe the bug you are experiencing or feature you are requesting below: \n\n", [[UIDevice currentDevice] systemVersion], PACKAGE_VERSION, databasePath];
        
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        [mail setSubject:@"Zebra Beta Bug Report"];
        [mail setMessageBody:message isHTML:NO];
        [mail setToRecipients:@[@"wilson@styres.me"]];
        
        [self presentViewController:mail animated:YES completion:NULL];
    }
    else
    {
        NSLog(@"[Zebra] This device cannot send email");
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)openDocumentsDirectory {
    NSString *documents = [ZBAppDelegate documentsDirectory];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"filza://view%@", documents]]];
}

- (IBAction)refreshPage:(id)sender {
    [webView reload];
}

- (void)dealloc {
    [webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) context:nil];
}

@end
