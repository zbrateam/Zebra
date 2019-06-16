//
//  ZBWebViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/27/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBWebViewController.h"
#import "ZBAlternateIconController.h"
#import <Database/ZBRefreshViewController.h>
#import <ZBAppDelegate.h>
#import <Repos/Helpers/ZBRepoManager.h>
#import <UIColor+GlobalColors.h>
#import <Stores/Controllers/ZBStoresListTableViewController.h>
#import <ZBDeviceHelper.h>
@import SDWebImage;

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetWebView) name:@"darkMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetWebView) name:@"lightMode" object:nil];
    self.defaults = [NSUserDefaults standardUserDefaults];
    self.repoManager = [[ZBRepoManager alloc] init];

    if ([self.defaults boolForKey:@"darkMode"]) {
        [self.darkModeButton setImage:[UIImage imageNamed:@"Dark"]];
    } else {
        [self.darkModeButton setImage:[UIImage imageNamed:@"Light"]];
    }
    // self.navigationController.navigationBar.tintColor = [UIColor tintColor];

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
    
    webView.navigationDelegate = self.navigationDelegate ? self.navigationDelegate : self;
    webView.tintColor = [UIColor tintColor];
    
    if ([self.defaults boolForKey:@"darkMode"]) {
        webView.scrollView.backgroundColor = [UIColor colorWithRed:0.09 green:0.09 blue:0.09 alpha:1.0];
    }
    
    if (_url != NULL) {
        [webView setAllowsBackForwardNavigationGestures:true];
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

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURLRequest *request = [navigationAction request];
    NSURL *url = [request URL];
    
    WKNavigationType type = navigationAction.navigationType;
    
    if (![navigationAction.request.URL isEqual:[NSURL URLWithString:@"about:blank"]]) {
        if (type != -1 && ([[url scheme] isEqualToString:@"http"] || [[url scheme] isEqualToString:@"https"])) {
            SFSafariViewController *sfVC = [[SFSafariViewController alloc] initWithURL:url];
            if (@available(iOS 10.0, *)) {
                sfVC.preferredControlTintColor = [UIColor tintColor];
            }
            [self presentViewController:sfVC animated:true completion:nil];
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

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.navigationItem setTitle:[webView title]];
    if ([self.defaults boolForKey:@"darkMode"]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"ios7dark" ofType:@"css"];
        NSString *cssData = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
        cssData = [cssData stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        cssData = [cssData stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        NSString *jsString = [NSString stringWithFormat:@"var style = document.createElement('style'); style.innerHTML = '%@'; document.head.appendChild(style)", cssData];
        [webView evaluateJavaScript:jsString completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (error) {
                NSLog(@"[Zebra] Error setting web dark mode: %@", error.localizedDescription);
            }
        }];
    }
    
#if TARGET_OS_SIMULATOR
    [webView evaluateJavaScript:@"document.getElementById('neo').innerHTML = 'Wake up, Neo...'" completionHandler:nil];
#else
    [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('neo').innerHTML = \"%@ - iOS %@ - Zebra %@\"", [ZBDeviceHelper deviceModelID], [[UIDevice currentDevice] systemVersion], PACKAGE_VERSION] completionHandler:nil];
#endif
    
    if ([[[webView URL] lastPathComponent] isEqualToString:@"repos.html"]) {
        NSLog(@"Hi Everybody!");
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Sileo.app"] && ![[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"]) {
            [webView evaluateJavaScript:@"document.getElementById('transfergroup').outerHTML = \'\'" completionHandler:nil];
            [webView evaluateJavaScript:@"document.getElementById('transferfooter').outerHTML = \'\'" completionHandler:nil];
        }
        else {
            if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Sileo.app"]) {
                [webView evaluateJavaScript:@"document.getElementById('sileotransfer').outerHTML = \'\'" completionHandler:nil];
            }
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"]) {
                [webView evaluateJavaScript:@"document.getElementById('cydiatransfer').outerHTML = \'\'" completionHandler:nil];
            }
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/chimera"]) {
            [webView evaluateJavaScript:@"document.getElementById('uncover').outerHTML = \'\'" completionHandler:nil];
            [webView evaluateJavaScript:@"document.getElementById('electra').outerHTML = \'\'" completionHandler:nil];
            [webView evaluateJavaScript:@"document.getElementById('cydia').outerHTML = \'\'" completionHandler:nil];
        }
        else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/jb"]) { //uncover
            [webView evaluateJavaScript:@"document.getElementById('chimera').outerHTML = \'\'" completionHandler:nil];
            [webView evaluateJavaScript:@"document.getElementById('electra').outerHTML = \'\'" completionHandler:nil];
            [webView evaluateJavaScript:@"document.getElementById('cydia').outerHTML = \'\'" completionHandler:nil];
        }
        else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/electra"]) { //electra
            [webView evaluateJavaScript:@"document.getElementById('uncover').outerHTML = \'\'" completionHandler:nil];
            [webView evaluateJavaScript:@"document.getElementById('chimera').outerHTML = \'\'" completionHandler:nil];
            [webView evaluateJavaScript:@"document.getElementById('cydia').outerHTML = \'\'" completionHandler:nil];
        }
        else { //cydia
            [webView evaluateJavaScript:@"document.getElementById('uncover').outerHTML = \'\'" completionHandler:nil];
            [webView evaluateJavaScript:@"document.getElementById('electra').outerHTML = \'\'" completionHandler:nil];
            [webView evaluateJavaScript:@"document.getElementById('chimera').outerHTML = \'\'" completionHandler:nil];
        }
    }
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
        else if ([action isEqual:@"cache"]) {
            [self resetImageCache];
        }
        else if ([action isEqual:@"keychain"]) {
            [self clearKeychain];
        }
        else if ([action isEqual:@"icon"]) {
            [self changeIcon];
        } else if ([action isEqual:@"stores"]) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ZBStoresListTableViewController *webController = [storyboard instantiateViewControllerWithIdentifier:@"storesController"];
            [[self navigationController] pushViewController:webController animated:true];
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
        UIAlertAction *no = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:NULL];
        
        [controller addAction:no];
        [controller addAction:yes];
        
        [self presentViewController:controller animated:true completion:nil];
    }
    else if ([destination isEqual:@"repo-local"]) {
        if ([contents count] == 2) {
            if (![ZBAppDelegate needsSimulation]) {
                UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Add Repositories" message:@"Are you sure you want to transfer repositories?" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *yes = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self handleRepoAdd:contents[1] local:true];
                }];
                UIAlertAction *no = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:NULL];
                [controller addAction:no];
                [controller addAction:yes];
                
                [self presentViewController:controller animated:true completion:nil];
            }
            else {
                UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Error" message:@"This action is not supported on non-jailbroken devices" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"😢" style:UIAlertActionStyleDefault handler:NULL];
                
                [controller addAction:ok];
                
                [self presentViewController:controller animated:true completion:nil];
            }
        }
        else {
            UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Add Repository" message:[NSString stringWithFormat:@"Are you sure you want to add the repository \"%@\"?", action] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *yes = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self handleRepoAdd:url local:true];
            }];
            UIAlertAction *no = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:NULL];
            
            [controller addAction:no];
            [controller addAction:yes];
            
            [self presentViewController:controller animated:true completion:nil];
        }
    }
}

- (void)handleRepoAdd:(NSString *)repo local:(BOOL)local {
    //    NSLog(@"[Zebra] Handling repo add for method %@", repo);
    if (local) {
        NSArray *options = @[
                             @"transfercydia",
                             @"transfersileo",
                             @"cydia",
                             @"electra",
                             @"uncover",
                             @"bigboss",
                             @"modmyi",
                             ];
        
        switch ([options indexOfObject:repo]) {
            case 0:
                [self.repoManager transferFromCydia];
                break;
            case 1:
                [self.repoManager transferFromSileo];
                break;
            case 2:
                [self.repoManager addDebLine:[NSString stringWithFormat:@"deb http://apt.saurik.com/ ios/%.2f main\n", kCFCoreFoundationVersionNumber]];
                break;
            case 3:
                [self.repoManager addDebLine:@"deb https://electrarepo64.coolstar.org/ ./\n"];
                break;
            case 4:
                [self.repoManager addDebLine:[NSString stringWithFormat:@"deb http://apt.bingner.com/ ios/%.2f main\n", kCFCoreFoundationVersionNumber]];
                break;
            case 5:
                [self.repoManager addDebLine:@"deb http://apt.thebigboss.org/repofiles/cydia/ stable main\n"];
                break;
            case 6:
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
                [weakSelf showRefreshView:@(NO)];
            }
        }];
    }
}

- (void)showRefreshView:(NSNumber *)dropTables {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(showRefreshView:) withObject:dropTables waitUntilDone:false];
    }
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ZBRefreshViewController *console = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
        console.dropTables = [dropTables boolValue];
        [self presentViewController:console animated:true completion:nil];
    }
}

- (void)nukeDatabase {
    [self showRefreshView:@(YES)];
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

- (void)resetImageCache {
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
}

- (void)clearKeychain {
    NSArray *secItemClasses = @[(__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecClassInternetPassword,
                                (__bridge id)kSecClassCertificate,
                                (__bridge id)kSecClassKey,
                                (__bridge id)kSecClassIdentity];
    for (id secItemClass in secItemClasses) {
        NSDictionary *spec = @{(__bridge id)kSecClass: secItemClass};
        SecItemDelete((__bridge CFDictionaryRef)spec);
    }
}

- (void)changeIcon {
    if (@available(iOS 10.3, *)) {
        [self performSegueWithIdentifier:@"segueHomeToAltIcons" sender:nil];
    } else {
        return;
    }
}

- (IBAction)refreshPage:(id)sender {
    [self hapticButton];
    [webView reload];
}

- (IBAction)toggleDarkMode:(id)sender {
    [self hapticButton];
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (![self.defaults boolForKey:@"darkMode"]) {
            //Want Darkmode
            [self darkMode];
        } else {
            //Want Light
            [self lightMode];
        }
    } completion:nil];
}

-(void)hapticButton{
    if (@available(iOS 10.0, *)) {
        UISelectionFeedbackGenerator *feedback = [[UISelectionFeedbackGenerator alloc] init];
        [feedback prepare];
        [feedback selectionChanged];
        feedback = nil;
    } else {
        return;// Fallback on earlier versions
    }
}

- (void)darkMode{
    [self.defaults setBool:TRUE forKey:@"darkMode"];
    [self.defaults synchronize];
    [self resetWebView];
    [self.darkModeButton setImage:[UIImage imageNamed:@"Dark"]];
    [ZBAppDelegate configureDark];
    [ZBAppDelegate refreshViews];
    [self setNeedsStatusBarAppearanceUpdate];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"darkMode" object:self];
}

- (void)lightMode{
    [self.defaults setBool:FALSE forKey:@"darkMode"];
    [self.defaults synchronize];
    [self resetWebView];
    [self.darkModeButton setImage:[UIImage imageNamed:@"Light"]];
    [ZBAppDelegate configureLight];
    [ZBAppDelegate refreshViews];
    [self setNeedsStatusBarAppearanceUpdate];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"lightMode" object:self];
}

-(void)resetWebView{
    if (_url != NULL) {
        [webView setAllowsBackForwardNavigationGestures:true];
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
    
    if ([self.defaults boolForKey:@"darkMode"]) {
        [self.darkModeButton setImage:[UIImage imageNamed:@"Dark"]];
    } else {
        [self.darkModeButton setImage:[UIImage imageNamed:@"Light"]];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if ([self.defaults boolForKey:@"darkMode"]) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

- (void)dealloc {
    [webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) context:nil];
}

@end
