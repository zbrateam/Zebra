

//
//  ZBPackageDepictionViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/23/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageDepictionViewController.h"
#import "UICKeyChainStore.h"
#import <Queue/ZBQueue.h>
#import <Database/ZBDatabaseManager.h>
#import <SafariServices/SafariServices.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageActionsManager.h>
#import <Repos/Helpers/ZBRepo.h>
#import <ZBTabBarController.h>
#import <UIColor+GlobalColors.h>
#import <Home/ZBWebViewController.h>
#import <ZBAppDelegate.h>
#import <ZBDeviceHelper.h>

@interface ZBPackageDepictionViewController () {
    UIProgressView *progressView;
    WKWebView *webView;
    BOOL presented;
}
@end

@implementation ZBPackageDepictionViewController

@synthesize delegate;
@synthesize previewingGestureRecognizerForFailureRelationship;
@synthesize sourceRect;
@synthesize sourceView;
@synthesize package;

- (id)initWithPackageID:(NSString *)packageID {
    self = [super init];
    
    if (self) {
        ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
        
        presented = true;
        self.package = [databaseManager topVersionForPackageID:packageID];
        
        if (self.package) {
            ZBPackage *candidate = [self.package installableCandidate];
            if (candidate) {
                self.package = candidate;
            }
        }
        else {
            // Package not found, we resign
            return nil;
        }
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDepiction) name:@"darkMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDepiction) name:@"lightMode" object:nil];
    self.defaults = [NSUserDefaults standardUserDefaults];
    if (presented) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(goodbye)];
        self.navigationItem.leftBarButtonItem = closeButton;
    }
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    self.view.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.95 alpha:1.0];
    self.navigationController.view.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.95 alpha:1.0];
    self.navigationItem.title = package.name;
    
    self.navigationController.navigationBar.translucent = false;
    self.tabBarController.tabBar.translucent = false;
    
    self.navigationController.navigationBar.tintColor = [UIColor tintColor];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"Zebra (Cydia) ~ %@", PACKAGE_VERSION];
    
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
    
    [progressView setTintColor:[UIColor tintColor]];
    
    webView.navigationDelegate = self;
    webView.opaque = false;
    webView.backgroundColor = [UIColor clearColor];
    if ([self.defaults boolForKey:@"darkMode"]) {
        webView.scrollView.backgroundColor = [UIColor colorWithRed:0.09 green:0.09 blue:0.09 alpha:1.0];
    }
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"package_depiction" withExtension:@"html"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSString *version = [[UIDevice currentDevice] systemVersion];
    NSString *udid = [ZBDeviceHelper UDID];
    NSString *machineIdentifier = [ZBDeviceHelper machineID];
    
    [request setValue:udid forHTTPHeaderField:@"X-Cydia-ID"];
    if ([self.defaults boolForKey:@"darkMode"]) {
        [request setValue:@"Telesphoreo APT-HTTP/1.0.592 Dark" forHTTPHeaderField:@"User-Agent"];
        [request setValue:@"TRUE" forHTTPHeaderField:@"Dark"];
        [request setValue:@"dark" forHTTPHeaderField:@"prefers-color-scheme"];
    } else {
        [request setValue:@"Telesphoreo APT-HTTP/1.0.592" forHTTPHeaderField:@"User-Agent"];
        [request setValue:@"FALSE" forHTTPHeaderField:@"Dark"];
        [request setValue:@"light" forHTTPHeaderField:@"prefers-color-scheme"];
    }
    [request setValue:version forHTTPHeaderField:@"X-Firmware"];
    [request setValue:udid forHTTPHeaderField:@"X-Unique-ID"];
    [request setValue:machineIdentifier forHTTPHeaderField:@"X-Machine"];
    [request setValue:@"API" forHTTPHeaderField:@"Payment-Provider"];
    
    [request setValue:[[NSLocale preferredLanguages] firstObject] forHTTPHeaderField:@"Accept-Language"];
    
    
    [webView loadRequest:request];
    //    [webView loadFileURL:url allowingReadAccessToURL:[url URLByDeletingLastPathComponent]];
    
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

- (void)goodbye {
    if ([self presentingViewController]) {
        [self dismissViewControllerAnimated:true completion:nil];
    }
}

- (void)escape:(NSMutableString *)s {
    [s replaceOccurrencesOfString:@"\r" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, s.length)];
    [s replaceOccurrencesOfString:@"\n" withString:@"<br>" options:NSLiteralSearch range:NSMakeRange(0, s.length)];
    [s replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0, s.length)];
    [s replaceOccurrencesOfString:@"\'" withString:@"\\\'" options:NSLiteralSearch range:NSMakeRange(0, s.length)];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSArray *contents = [message.body componentsSeparatedByString:@"~"];
    NSString *destination = (NSString *)contents[0];
    NSString *action = contents[1];
    
    if ([destination isEqual:@"local"]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ZBWebViewController *filesController = [storyboard instantiateViewControllerWithIdentifier:@"webController"];
        filesController.navigationDelegate = self;
        filesController.navigationItem.title = @"Installed Files";
        NSURL *url = [[NSBundle mainBundle] URLForResource:action withExtension:@".html"];
        [filesController setValue:url forKey:@"_url"];
        
        [[self navigationController] pushViewController:filesController animated:true];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (package == nil)
        return;
    // DarkMode
    if ([self.defaults boolForKey:@"darkMode"]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"ios7dark" ofType:@"css"];
        NSString *cssData = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
        cssData = [cssData stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        cssData = [cssData stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        NSString *jsString = [NSString stringWithFormat:@"var style = document.createElement('style'); \
                              style.innerHTML = '%@'; \
                              document.head.appendChild(style)",
                              cssData];
        [webView evaluateJavaScript:jsString
                  completionHandler:^(id _Nullable result, NSError *_Nullable error) {
                      if (error) {
                          NSLog(@"[Zebra] Error setting web dark mode: %@", error.localizedDescription);
                      }
                  }];
    }
    
    NSURL *depictionURL = [package depictionURL];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *sectionImage = [UIImage imageNamed:self.package.sectionImageName];
        if (sectionImage == NULL) {
            sectionImage = [UIImage imageNamed:@"Other"];
        }
        
        NSString *iconURL = @"";
        if (self.package.iconPath) {
            iconURL = [self.package iconPath];
        }
        else {
            iconURL = [NSString stringWithFormat:@"data:image/png;base64,%@", [UIImagePNGRepresentation(sectionImage) base64EncodedStringWithOptions:0]];
        }
        
        if (iconURL.length > 0) {
            [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('package-icon').src = \"%@\";", iconURL] completionHandler:nil];
            [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('package-name').innerHTML = '%@';", [self.package name]] completionHandler:nil];
            [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('package').innerHTML = '%@';", [self.package identifier]] completionHandler:nil];
        } else {
            [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('package').innerHTML = '%@ (%@)';", [self.package name], [self.package identifier]] completionHandler:nil];
        }
    });
    
    NSString *versionString;
    if (![package isInstalled:NO] || [package installedVersion] == nil) {
        versionString = [NSString stringWithFormat:@"Version: %@", [package version]];
    }
    else {
        versionString = [NSString stringWithFormat:@"Version: %@<br\\>Installed Version: %@", [package version], [package installedVersion]];
    }
    [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('version').innerHTML = '%@';", versionString] completionHandler:nil];
    
    NSMutableArray *sizeString = [NSMutableArray array];
    NSString *size = [package size];
    if (size) {
        [sizeString addObject:[NSString stringWithFormat:@"Size: %@", size]];
    }
    NSString *installedSize = [package installedSize];
    if (installedSize) {
        [sizeString addObject:[NSString stringWithFormat:@"Installed-Size: %@", installedSize]];
    }
    if (sizeString.count) {
        [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('size').innerHTML = '%@';", [sizeString componentsJoinedByString:@"<br>"]] completionHandler:nil];
    }
    else {
        [webView evaluateJavaScript:@"document.getElementById('size').parentElement.outerHTML = '';" completionHandler:nil];
    }
    NSMutableString *repoName = [NSMutableString string];
    [repoName appendString:[package repo].origin];
    [self escape:repoName];
    if (repoName) {
        [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('repo').innerHTML = \"Source: %@\";", repoName] completionHandler:nil];
    }
    else {
        [webView evaluateJavaScript:@"document.getElementById('repo').parentElement.outerHTML = '';" completionHandler:nil];
    }
    
    if (depictionURL != NULL && ![[depictionURL absoluteString] isEqualToString:@""])  {
        [webView evaluateJavaScript:@"var element = document.getElementById('desc-holder').outerHTML = '';" completionHandler:nil];
        [webView evaluateJavaScript:@"var element = document.getElementById('main-holder').style.marginBottom = '0px';" completionHandler:nil];
        NSString *command = [NSString stringWithFormat:@"document.getElementById('depiction-src').src = '%@';", [depictionURL absoluteString]];
        [webView evaluateJavaScript:command completionHandler:nil];
    }
    else if (![[package shortDescription] isEqualToString:@""] && [package shortDescription] != NULL) {
        [webView evaluateJavaScript:@"var element = document.getElementById('depiction-src').outerHTML = '';" completionHandler:nil];
        
        NSString *originalDescription = [package longDescription];
        NSMutableString *description = [NSMutableString stringWithCapacity:originalDescription.length];
        [description appendString:originalDescription];
        
        [self escape:description];
        
        NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        NSArray *matches = [linkDetector matchesInString:description options:0 range:NSMakeRange(0, description.length)];
        NSUInteger rangeShift = 0;
        for (NSTextCheckingResult *result in matches) {
            NSString *urlString = result.URL.absoluteString;
            NSUInteger before = result.range.length;
            NSString *anchor = [NSString stringWithFormat:@"<a href=\\\"%@\\\">%@</a>", urlString, urlString];
            [description replaceCharactersInRange:NSMakeRange(result.range.location + rangeShift, result.range.length) withString:anchor];
            rangeShift += anchor.length - before;
        }
        
        [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('desc').innerHTML = \"%@\";", description] completionHandler:nil];
    }
    else {
        [webView evaluateJavaScript:@"var element = document.getElementById('desc-holder').outerHTML = '';" completionHandler:nil];
    }
    
    if ([package isInstalled:NO]) {
        [webView evaluateJavaScript:@"document.getElementById('installed-files').innerHTML = 'Installed Files';" completionHandler:nil];
        [webView evaluateJavaScript:@"document.getElementById('installed-files').setAttribute('role', 'button');" completionHandler:nil];
        [webView evaluateJavaScript:@"document.getElementById('installed-files').onclick = function () { window.webkit.messageHandlers.observe.postMessage('local~installed_files'); };" completionHandler:nil];
    }
    
    NSArray *installedFiles = [ZBPackage filesInstalled:package.identifier];
    installedFiles = [installedFiles sortedArrayUsingSelector:@selector(compare:)];
    
    for (int i = 0; i < installedFiles.count; i++) {
        NSString *file = installedFiles[i];
        if ([file isEqualToString:@"/."] || file.length == 0) {
            continue;
        }
        
        NSArray *components = [file componentsSeparatedByString:@"/"];
        NSMutableString *displayStr = [NSMutableString new];
        for (int b = 0; b < components.count - 2; b++) {
            [displayStr appendString:@"&emsp;"]; //add tab character
        }
        [displayStr appendString:components[components.count - 1]];
        
        [webView evaluateJavaScript:[NSString stringWithFormat:@"addFile(\"%@\");", displayStr] completionHandler:nil];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURLRequest *request = [navigationAction request];
    NSURL *url = [request URL];
    
    WKNavigationType type = navigationAction.navigationType;
    
    if ([navigationAction.request.URL isFileURL] || (type == -1 && [navigationAction.request.URL isEqual:[package depictionURL]])) {
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
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    if ([package isInstalled:false]) {
        if ([package isReinstallable]) {
            UIBarButtonItem *modifyButton = [[UIBarButtonItem alloc] initWithTitle:@"Modify" style:UIBarButtonItemStylePlain target:self action:@selector(modifyPackage)];
            self.navigationItem.rightBarButtonItem = modifyButton;
        }
        else {
            UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithTitle:[[ZBQueue sharedInstance] queueToKey:ZBQueueTypeRemove] style:UIBarButtonItemStylePlain target:self action:@selector(removePackage)];
            self.navigationItem.rightBarButtonItem = removeButton;
        }
    }
    else if ([package isPaid] && [keychain[[keychain stringForKey:[package repo].baseURL]] length] != 0) {
        [self determinePaidPackage];
    }
    else {
        UIBarButtonItem *installButton = [[UIBarButtonItem alloc] initWithTitle:[[ZBQueue sharedInstance] queueToKey:ZBQueueTypeInstall] style:UIBarButtonItemStylePlain target:self action:@selector(installPackage)];
        installButton.enabled = ![[ZBQueue sharedInstance] containsPackage:package queue:ZBQueueTypeInstall];
        self.navigationItem.rightBarButtonItem = installButton;
    }
}

- (void)determinePaidPackage {
    UIActivityIndicatorView *uiBusy = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    uiBusy.hidesWhenStopped = YES;
    [uiBusy startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:uiBusy];
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    if ([keychain[[keychain stringForKey:[package repo].baseURL]] length] != 0) {
        if ([package isPaid]) {
            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
            
            NSDictionary *test = @{ @"token": keychain[[keychain stringForKey:[package repo].baseURL]],
                                    @"udid": [ZBDeviceHelper UDID],
                                    @"device": [ZBDeviceHelper deviceModelID] };
            NSData *requestData = [NSJSONSerialization dataWithJSONObject:test options:(NSJSONWritingOptions)0 error:nil];
            
            NSMutableURLRequest *request = [NSMutableURLRequest new];
            [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@package/%@/info", [keychain stringForKey:[package repo].baseURL], package.identifier]]];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
            [request setHTTPBody: requestData];
            [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSString *title = [[ZBQueue sharedInstance] queueToKey:ZBQueueTypeInstall];
                SEL selector = @selector(installPackage);
                if (data) {
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    NSLog(@"[Zebra] Package purchase status response: %@", json);
                    BOOL purchased = [json[@"purchased"] boolValue];
                    BOOL available = [json[@"available"] boolValue];
                    if (!purchased && available) {
                        title = json[@"price"];
                        selector = @selector(purchasePackage);
                    } else if (purchased && available) {
                        self->package.sileoDownload = TRUE;
                    }
                }
                UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:selector];
                button.enabled = ![[ZBQueue sharedInstance] containsPackage:self->package queue:ZBQueueTypeInstall];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.navigationItem setRightBarButtonItem:button animated:YES];
                    [uiBusy stopAnimating];
                });
                
            }] resume];
        }
    }
}

- (void)installPackage {
    [ZBPackageActionsManager installPackage:package purchased:self.purchased];
    [self presentQueue];
}

- (void)purchasePackage {
    UIActivityIndicatorView *uiBusy = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    uiBusy.hidesWhenStopped = YES;
    [uiBusy startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:uiBusy];
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    if ([keychain[[keychain stringForKey:[package repo].baseURL]] length] != 0) {
        if ([package isPaid] && [package repo].supportSileoPay) {
            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
            NSString *idThing = [NSString stringWithFormat:@"%@payment", [keychain stringForKey:[package repo].baseURL]];
            NSString *token = keychain[[keychain stringForKey:[package repo].baseURL]];
            NSLog(@"[Zebra] Package purchase token: %@", token);
            __block NSString *secret;
            //Wait on getting key
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSError *error = nil;
                [keychain setAccessibility:UICKeyChainStoreAccessibilityWhenPasscodeSetThisDeviceOnly
                      authenticationPolicy:UICKeyChainStoreAuthenticationPolicyUserPresence];
                keychain.authenticationPrompt = @"Authenticate to initiate purchase.";
                secret = keychain[idThing];
                dispatch_semaphore_signal(sema);
                if (error) {
                    NSLog(@"[Zebra] Package purchase error: %@", error.localizedDescription);
                }
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            //Continue
            if ([secret length] != 0) {
                NSDictionary *requestJSON = @{ @"token": keychain[[keychain stringForKey:[package repo].baseURL]],
                                               @"payment_secret": secret,
                                               @"udid": [ZBDeviceHelper UDID],
                                               @"device": [ZBDeviceHelper deviceModelID] };
                NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestJSON options:(NSJSONWritingOptions)0 error:nil];
                
                NSMutableURLRequest *request = [NSMutableURLRequest new];
                [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@package/%@/purchase",[keychain stringForKey:[package repo].baseURL], package.identifier]]];
                [request setHTTPMethod:@"POST"];
                [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
                [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
                [request setHTTPBody: requestData];
                [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    NSLog(@"[Zebra] Package purchase response: %@",json);
                    if ([json[@"status"] boolValue]) {
                        [uiBusy stopAnimating];
                        [self initPurchaseLink:json[@"url"]];
                    }
                    else {
                        [self configureNavButton];
                    }
                }] resume];
            }
            else {
                [self configureNavButton];
            }
        }
    }
}

- (void)initPurchaseLink:(NSString *)link {
    NSURL *destinationUrl = [NSURL URLWithString:link];
    if (@available(iOS 11.0, *)) {
        static SFAuthenticationSession *session;
        session = [[SFAuthenticationSession alloc]
                   initWithURL:destinationUrl
                   callbackURLScheme:@"sileo"
                   completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
                       // TODO: Nothing to do here?
                       NSLog(@"[Zebra] Purchase callback URL: %@", callbackURL);
                       if (callbackURL) {
                           NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:callbackURL resolvingAgainstBaseURL:NO];
                           NSArray *queryItems = urlComponents.queryItems;
                           NSMutableDictionary *queryByKeys = [NSMutableDictionary new];
                           for (NSURLQueryItem *q in queryItems) {
                               [queryByKeys setValue:[q value] forKey:[q name]];
                           }
                           //NSString *token = queryByKeys[@"token"];
                           //NSString *payment = queryByKeys[@"payment_secret"];
                           
                           NSError *error;
                           //[self->_keychain setString:token forKey:self.repoEndpoint error:&error];
                           if (error) {
                               NSLog(@"[Zebra] Error initializing purchase page: %@", error.localizedDescription);
                           }
                           
                       }
                       else {
                           [self configureNavButton];
                           return;
                       }
                       
                       
                   }];
        [session start];
    }
    else {
        SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:destinationUrl];
        safariVC.delegate = self;
        [self presentViewController:safariVC animated:TRUE completion:nil];
    }
}

- (void)removePackage {
    ZBQueue *queue = [ZBQueue sharedInstance];
    [queue addPackage:package toQueue:ZBQueueTypeRemove];
    [self presentQueue];
}

- (void)modifyPackage {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@)", package.name, package.version] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (UIAlertAction *action in [ZBPackageActionsManager alertActionsForPackage:package viewController:self parent:_parent]) {
        [alert addAction:action];
    }
    
    alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    
    [self presentViewController:alert animated:true completion:nil];
}

- (void)dealloc {
    [webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) context:nil];
}

- (void)presentQueue {
    [ZBPackageActionsManager presentQueue:self parent:_parent];
}

//3D Touch Actions

- (NSArray *)previewActionItems {
    return [ZBPackageActionsManager previewActionsForPackage:package viewController:self parent:_parent];
}
- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully {
    // Load finished
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    // Done button pressed
}

- (void)reloadDepiction {
    [webView reloadFromOrigin];
}
@end
