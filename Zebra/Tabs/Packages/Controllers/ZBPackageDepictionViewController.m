

//
//  ZBPackageDepictionViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/23/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <ZBLog.h>
#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <ZBSettings.h>
#import "ZBPackageDepictionViewController.h"
#import "UICKeyChainStore.h"
#import <Queue/ZBQueue.h>
#import <Database/ZBDatabaseManager.h>
#import <SafariServices/SafariServices.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageActionsManager.h>
#import <Sources/Helpers/ZBSource.h>
#import <ZBTabBarController.h>
#import <UIColor+GlobalColors.h>
#import "ZBWebViewController.h"
#import "ZBPurchaseInfo.h"

@import SDWebImage;
@import Crashlytics;

typedef NS_ENUM(NSUInteger, ZBPackageInfoOrder) {
    ZBPackageInfoID = 0,
    ZBPackageInfoAuthor,
    ZBPackageInfoVersion,
    ZBPackageInfoSize,
    ZBPackageInfoRepo,
    ZBPackageInfoWishList,
    ZBPackageInfoMoreBy,
    ZBPackageInfoInstalledFiles
};

static const NSUInteger ZBPackageInfoOrderCount = 8;

@interface ZBPackageDepictionViewController () {
    NSMutableDictionary<NSNumber *, NSString *> *infos;
    UIProgressView *progressView;
    WKWebView *webView;
    BOOL presented;
    BOOL navButtonsBeingConfigured;
    CGFloat webViewSize;
}
@end

@implementation ZBPackageDepictionViewController

@synthesize delegate;
@synthesize previewingGestureRecognizerForFailureRelationship;
@synthesize sourceRect;
@synthesize sourceView;
@synthesize package;

- (id)initWithPackageID:(NSString *)packageID fromRepo:(ZBSource *_Nullable)repo {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"packageDepictionVC"];
    
    if (self) {
        ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
        
        self.package = [databaseManager topVersionForPackageID:packageID inRepo:repo];
        if (self.package == NULL) {
            return NULL;
        }
        presented = YES;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDepiction) name:@"darkMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureNavButton) name:@"ZBDatabaseCompletedUpdate" object:nil];
    if (presented) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:UIBarButtonItemStylePlain target:self action:@selector(goodbye)];
        self.navigationItem.leftBarButtonItem = closeButton;
    }
    
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    self.navigationItem.title = package.name;
    
    [self.tableView.tableHeaderView setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [self.packageIcon.layer setCornerRadius:20];
    [self.packageIcon.layer setMasksToBounds:YES];
    infos = [NSMutableDictionary new];
    [self setPackage];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    if ([ZBDevice darkModeEnabled]) {
        if ([ZBDevice darkModeOledEnabled]) {
            configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"Zebra (Cydia) Dark Oled ~ %@", PACKAGE_VERSION];
        } else {
            configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"Zebra (Cydia) Dark ~ %@", PACKAGE_VERSION];
        }
    } else {
        configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"Zebra (Cydia) Light ~ %@", PACKAGE_VERSION];
    }
    
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    [controller addScriptMessageHandler:self name:@"observe"];
    configuration.userContentController = controller;
    
    webViewSize = 0;
    webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 300) configuration:configuration];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.scrollView.scrollEnabled = NO;
    
    progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.tableView.tableHeaderView addSubview:progressView];
    [self.tableView setTableFooterView:webView];
    
    // Progress View Layout
    [progressView.trailingAnchor constraintEqualToAnchor:self.tableView.tableHeaderView.trailingAnchor].active = YES;
    [progressView.leadingAnchor constraintEqualToAnchor:self.tableView.tableHeaderView.leadingAnchor].active = YES;
    [progressView.topAnchor constraintEqualToAnchor:self.tableView.tableHeaderView.topAnchor].active = YES;
    
    [progressView setTintColor:[UIColor tintColor]];
    
    webView.navigationDelegate = self;
    webView.opaque = NO;
    webView.backgroundColor = [UIColor tableViewBackgroundColor];
    
    if ([package depictionURL]) {
        [self prepDepictionLoading:[package depictionURL]];
    } else {
        [self prepDepictionLoading:[[NSBundle mainBundle] URLForResource:@"package_depiction" withExtension:@"html"]];
    }
    
    CLS_LOG(@"%@ (%@) from %@", [package name], [package identifier], [[package repo] repositoryURI]);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    [self configureNavButton];
    
    [webView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];
    [webView.scrollView addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) options:NSKeyValueObservingOptionNew context:NULL];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) context:nil];
    [webView.scrollView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) context:nil];
}

- (void)prepDepictionLoading:(NSURL *)url {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    webView.scrollView.backgroundColor = [UIColor tableViewBackgroundColor];
    NSString *version = [[UIDevice currentDevice] systemVersion];
    NSString *udid = [ZBDevice UDID];
    NSString *machineIdentifier = [ZBDevice machineID];
    
    [request setValue:udid forHTTPHeaderField:@"X-Cydia-ID"];
    if ([ZBDevice darkModeEnabled]) {
        [request setValue:@"YES" forHTTPHeaderField:@"Dark"];
        if ([ZBDevice darkModeOledEnabled]) {
            [request setValue:@"YES" forHTTPHeaderField:@"Oled"];
            [request setValue:@"Telesphoreo APT-HTTP/1.0.592 Oled" forHTTPHeaderField:@"User-Agent"];
        } else {
            [request setValue:@"Telesphoreo APT-HTTP/1.0.592 Dark" forHTTPHeaderField:@"User-Agent"];
        }
    } else {
        [request setValue:@"Telesphoreo APT-HTTP/1.0.592 Light" forHTTPHeaderField:@"User-Agent"];
    }
    [request setValue:version forHTTPHeaderField:@"X-Firmware"];
    [request setValue:udid forHTTPHeaderField:@"X-Unique-ID"];
    [request setValue:machineIdentifier forHTTPHeaderField:@"X-Machine"];
    [request setValue:@"API" forHTTPHeaderField:@"Payment-Provider"];
    [request setValue:[UIColor hexStringFromColor:[UIColor tintColor]] forHTTPHeaderField:@"Tint-Color"];
    [request setValue:[[NSLocale preferredLanguages] firstObject] forHTTPHeaderField:@"Accept-Language"];
    
    [webView loadRequest:request];
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
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))]) {
        CGFloat newSize = [(UIScrollView *)object contentSize].height;
        if (newSize != webViewSize) {
            webViewSize = newSize;
            [self layoutDepictionWebView:webView];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)goodbye {
    if ([self presentingViewController]) {
        [self dismissViewControllerAnimated:YES completion:nil];
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
        filesController.navigationItem.title = NSLocalizedString(@"Installed Files", @"");
        NSURL *url = [[NSBundle mainBundle] URLForResource:action withExtension:@".html"];
        [filesController setValue:url forKey:@"_url"];
        
        [[self navigationController] pushViewController:filesController animated:YES];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (package == nil)
        return;
    
    [self performSelector:@selector(layoutDepictionWebView:) withObject:webView afterDelay:1.0];
    
    NSString *js = @"var meta = document.createElement('meta'); meta.name = 'viewport'; meta.content = 'initial-scale=1, maximum-scale=1, user-scalable=0'; var head = document.getElementsByTagName('head')[0]; head.appendChild(meta);";
    [webView evaluateJavaScript:js completionHandler:nil];
    
    if ([webView.URL.absoluteString isEqualToString:[[NSBundle mainBundle] URLForResource:@"package_depiction" withExtension:@"html"].absoluteString]) {
        if ([ZBDevice darkModeEnabled]) {
            NSString *path;
            if ([ZBDevice darkModeOledEnabled]) {
                path = [[NSBundle mainBundle] pathForResource:@"ios7oled" ofType:@"css"];
            } else {
                path = [[NSBundle mainBundle] pathForResource:@"ios7dark" ofType:@"css"];
            }
            
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
                              ZBLog(@"[Zebra] Error setting web dark mode: %@", error.localizedDescription);
                          }
                      }];
        }
        
        if (![[package shortDescription] isEqualToString:@""] && [package shortDescription] != NULL) {
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
        } else {
            [webView evaluateJavaScript:@"var element = document.getElementById('desc-holder').outerHTML = '';" completionHandler:nil];
        }
    }
}

- (void)layoutDepictionWebView:(WKWebView *)webView {
    if (webView) {
        [webView evaluateJavaScript:@"document.readyState" completionHandler:^(id _Nullable completed, NSError * _Nullable error) {
            if (error) {
                CLS_LOG(@"Error when getting depiction height: %@", error.localizedDescription);
            }
            else {
                if ([completed isEqualToString:@"complete"]) {
                    //body.scrollHeight, body.offsetHeight, html.clientHeight, html.scrollHeight, html.offsetHeight
                    NSString *question = @"var body = document.body, html = document.documentElement; var height = Math.max(body.scrollHeight, body.offsetHeight, html.clientHeight, html.scrollHeight, html.offsetHeight); height";
                    [webView evaluateJavaScript:question completionHandler:^(id _Nullable height, NSError * _Nullable error) {
                        [self layoutDepictionWebView:webView height:[height floatValue]];
                    }];
                }
            }
        }];
    }
}

- (void)layoutDepictionWebView:(WKWebView *)webView height:(CGFloat)height {
    dispatch_async(dispatch_get_main_queue(), ^{
        [webView setFrame:CGRectMake(webView.frame.origin.x, webView.frame.origin.y, webView.frame.size.width, height)];
        [self.tableView beginUpdates];
        [self.tableView setTableFooterView:webView];
        [self.tableView endUpdates];
    });
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURLRequest *request = [navigationAction request];
    NSURL *url = [request URL];
    
    WKNavigationType type = navigationAction.navigationType;
    
    if ([navigationAction.request.URL isFileURL] || (type == -1 && [navigationAction.request.URL isEqual:[package depictionURL]])) {
        decisionHandler(WKNavigationActionPolicyAllow);
    } else if (![navigationAction.request.URL isEqual:[NSURL URLWithString:@"about:blank"]]) {
        if (type != -1 && ([[url scheme] isEqualToString:@"http"] || [[url scheme] isEqualToString:@"https"])) {
            [ZBDevice openURL:url delegate:self];
            decisionHandler(WKNavigationActionPolicyCancel);
        } else if ([[url scheme] isEqualToString:@"mailto"]) {
            [[UIApplication sharedApplication] openURL:url];
            decisionHandler(WKNavigationActionPolicyCancel);
        } else {
            decisionHandler(WKNavigationActionPolicyAllow);
        }
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    [self prepDepictionLoading:[[NSBundle mainBundle] URLForResource:@"package_depiction" withExtension:@"html"]];
}

- (void)addModifyButton {
    UIBarButtonItem *modifyButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Modify", @"") style:UIBarButtonItemStylePlain target:self action:@selector(modifyPackage)];
    self.navigationItem.rightBarButtonItem = modifyButton;
}

- (void)configureNavButton {
    if (self->navButtonsBeingConfigured)
        return;
    self->navButtonsBeingConfigured = YES;
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    NSString *baseURL = [keychain stringForKey:package.repo.repositoryURI];
    if ([package isInstalled:NO]) {
        if ([package isReinstallable]) {
            if ([package isPaid] && [keychain[baseURL] length] != 0) {
                [self determinePaidPackage];
            } else {
                [self addModifyButton];
            }
        } else {
            UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithTitle:[[ZBQueue sharedQueue] displayableNameForQueueType:ZBQueueTypeRemove useIcon:false] style:UIBarButtonItemStylePlain target:self action:@selector(removePackage)];
            removeButton.enabled = package.repo.repoID != -1;
            self.navigationItem.rightBarButtonItem = removeButton;
        }
    } else if ([package isPaid] && [keychain[baseURL] length] != 0) {
        [self determinePaidPackage];
    } else {
        if ([package essential]) { //The package is marked as essential, display "Modify" so they can ignore updates if they don't wish to CONFIRM
            UIBarButtonItem *modifyButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Modify", @"") style:UIBarButtonItemStylePlain target:self action:@selector(ignoredModify)];
            self.navigationItem.rightBarButtonItem = modifyButton;
        }
        else {
            UIBarButtonItem *installButton = [[UIBarButtonItem alloc] initWithTitle:[[ZBQueue sharedQueue] displayableNameForQueueType:ZBQueueTypeInstall useIcon:false] style:UIBarButtonItemStylePlain target:self action:@selector(installPackage)];
            installButton.enabled = ![[ZBQueue sharedQueue] contains:package inQueue:ZBQueueTypeInstall];
            self.navigationItem.rightBarButtonItem = installButton;
        }
    }
    self->navButtonsBeingConfigured = NO;
}

- (void)determinePaidPackage {
    UIActivityIndicatorView *uiBusy = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    uiBusy.hidesWhenStopped = YES;
    [uiBusy startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:uiBusy];
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    NSString *baseURL = [keychain stringForKey:package.repo.repositoryURI];
    if ([keychain[baseURL] length] != 0) {
        if ([package isPaid]) {
            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
            
            NSDictionary *test = @{ @"token": keychain[baseURL],
                                    @"udid": [ZBDevice UDID],
                                    @"device": [ZBDevice deviceModelID] };
            NSData *requestData = [NSJSONSerialization dataWithJSONObject:test options:kNilOptions error:nil];
            
            NSMutableURLRequest *request = [NSMutableURLRequest new];
            [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@package/%@/info", baseURL, package.identifier]]];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
            [request setValue:[NSString stringWithFormat:@"Zebra/%@ iOS/%@ (%@)", PACKAGE_VERSION, [[UIDevice currentDevice] systemVersion], [ZBDevice deviceType]] forHTTPHeaderField:@"User-Agent"];
            [request setHTTPBody: requestData];
            [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSString *title = [[ZBQueue sharedQueue] displayableNameForQueueType:ZBQueueTypeInstall useIcon:true];
                SEL selector = @selector(installPackage);
                ZBPurchaseInfo *purchaseInfo = nil;
                if (data) {
                    /*json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    ZBLog(@"[Zebra] Package purchase status response: %@", json);
                    purchased = [json[@"purchased"] boolValue];
                    available = [json[@"available"] boolValue];*/
                    NSError *err;
                    purchaseInfo = [ZBPurchaseInfo fromData:data error:&err];
                    /*purchased = [purchaseInfo.purchased boolValue];
                    available = [purchaseInfo.available boolValue];*/
                }
                BOOL installed = [self->package isInstalled:NO];
                if (installed) {
                    BOOL set = NO;
                    if (purchaseInfo.purchased != nil && [purchaseInfo.purchased boolValue]) {
                        self->package.sileoDownload = YES;
                        self.purchased = YES;
                        if ([purchaseInfo.available boolValue] && ![self->package isReinstallable]) {
                            title = [[ZBQueue sharedQueue] displayableNameForQueueType:ZBQueueTypeRemove useIcon:true];
                            selector = @selector(removePackage);
                            set = YES;
                        }
                    }
                    if (!set) {
                        title = NSLocalizedString(@"Modify", @"");
                        selector = @selector(modifyPackage);
                    }
                } else if ([purchaseInfo.available boolValue]) {
                    if ([purchaseInfo.purchased boolValue]) {
                        self->package.sileoDownload = YES;
                        self.purchased = YES;
                    } else if (purchaseInfo) {
                        title = purchaseInfo.price;
                        selector = @selector(purchasePackage);
                    }
                }
                UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:selector];
                button.enabled = ![[ZBQueue sharedQueue] contains:self->package inQueue:ZBQueueTypeInstall];
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
    [self configureNavButton];
}

- (void)purchasePackage {
    UIActivityIndicatorView *uiBusy = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    uiBusy.hidesWhenStopped = YES;
    [uiBusy startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:uiBusy];
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    if ([keychain[[keychain stringForKey:[package repo].repositoryURI]] length] != 0) {
        if ([package isPaid] && [package repo].supportSileoPay) {
            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
            NSString *idThing = [NSString stringWithFormat:@"%@payment", [keychain stringForKey:[package repo].repositoryURI]];
#if ZB_DEBUG
            NSString *token = keychain[[keychain stringForKey:[package repo].baseURL]];
            ZBLog(@"[Zebra] Package purchase token: %@", token);
#endif
            __block NSString *secret;
            // Wait on getting key
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSError *error = nil;
                [keychain setAccessibility:UICKeyChainStoreAccessibilityWhenPasscodeSetThisDeviceOnly
                      authenticationPolicy:UICKeyChainStoreAuthenticationPolicyUserPresence];
                keychain.authenticationPrompt = NSLocalizedString(@"Authenticate to initiate purchase.", @"");
                secret = keychain[idThing];
                dispatch_semaphore_signal(sema);
                if (error) {
                    ZBLog(@"[Zebra] Package purchase error: %@", error.localizedDescription);
                }
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            // Continue
            if ([secret length] != 0) {
                NSDictionary *requestJSON = @{ @"token": keychain[[keychain stringForKey:[package repo].repositoryURI]],
                                               @"payment_secret": secret,
                                               @"udid": [ZBDevice UDID],
                                               @"device": [ZBDevice deviceModelID] };
                NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestJSON options:(NSJSONWritingOptions)0 error:nil];
                
                NSMutableURLRequest *request = [NSMutableURLRequest new];
                [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@package/%@/purchase",[keychain stringForKey:[package repo].repositoryURI], package.identifier]]];
                [request setHTTPMethod:@"POST"];
                [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
                [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
                [request setHTTPBody: requestData];
                [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (data) {
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                        ZBLog(@"[Zebra] Package purchase response: %@", json);
                        if ([json[@"status"] boolValue]) {
                            [uiBusy stopAnimating];
                            [self initPurchaseLink:json[@"url"]];
                        } else {
                            [self configureNavButton];
                        }
                    }
                }] resume];
            } else {
                [self configureNavButton];
            }
        }
    }
}

- (void)initPurchaseLink:(NSString *)link {
    if (link == nil) {
        [ZBAppDelegate sendErrorToTabController:[NSString stringWithFormat:NSLocalizedString(@"Please relogin your account that is used to purchase this package (Possibly %@)", @""), package.repo.origin]];
        return;
    }
    NSURL *destinationUrl = [NSURL URLWithString:link];
    if (@available(iOS 11.0, *)) {
        static SFAuthenticationSession *session;
        session = [[SFAuthenticationSession alloc]
                   initWithURL:destinationUrl
                   callbackURLScheme:@"sileo"
                   completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
                       // TODO: Nothing to do here?
                       ZBLog(@"[Zebra] Purchase callback URL: %@", callbackURL);
                       if (callbackURL) {
                           NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:callbackURL resolvingAgainstBaseURL:NO];
                           NSArray *queryItems = urlComponents.queryItems;
                           NSMutableDictionary *queryByKeys = [NSMutableDictionary new];
                           for (NSURLQueryItem *q in queryItems) {
                               [queryByKeys setValue:[q value] forKey:[q name]];
                           }
                           // NSString *token = queryByKeys[@"token"];
                           // NSString *payment = queryByKeys[@"payment_secret"];
                           
                           NSError *error = NULL;
                           // [self->_keychain setString:token forKey:self.repoEndpoint error:&error];
                           if (error) {
                               ZBLog(@"[Zebra] Error initializing purchase page: %@", error.localizedDescription);
                           }
                           
                       } else {
                           [self configureNavButton];
                           return;
                       }
                       
                       
                   }];
        [session start];
    } else {
        [ZBDevice openURL:destinationUrl delegate:self];
    }
}

- (void)removePackage {
    if (package.repo.repoID == -1) {
        return;
    }
    ZBQueue *queue = [ZBQueue sharedQueue];
    [queue addPackage:package toQueue:ZBQueueTypeRemove];
    [self presentQueue];
}

- (void)modifyPackage {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@)", package.name, package.version] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (UIAlertAction *action in [ZBPackageActionsManager alertActionsForPackage:package viewController:self parent:_parent]) {
        [alert addAction:action];
    }
    alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)ignoredModify {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@)", package.name, package.version] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *installAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Install", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self installPackage];
    }];
    [alert addAction:installAction];
    
    if ([package ignoreUpdates]) {
        UIAlertAction *unignore = [UIAlertAction actionWithTitle:NSLocalizedString(@"Show Updates", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self->package setIgnoreUpdates:NO];
        }];
        
        [alert addAction:unignore];
    } else {
        UIAlertAction *ignore = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ignore Updates", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self->package setIgnoreUpdates:YES];
        }];
        
        [alert addAction:ignore];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:true completion:nil];
    }];
    [alert addAction:cancelAction];
    
    alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentQueue {
    if ([self presentingViewController]) {
        [self dismissViewControllerAnimated:true completion:^{
            [[ZBAppDelegate tabBarController] openQueue:YES];
        }];
    } else {
        [[ZBAppDelegate tabBarController] openQueue:YES];
    }
}

// 3D Touch Actions

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
    UIColor *tableViewBackgroundColor = [UIColor tableViewBackgroundColor];
    [self prepDepictionLoading:webView.URL];
    webView.backgroundColor = tableViewBackgroundColor;
    [self.tableView reloadData];
    self.navigationController.navigationBar.barTintColor = tableViewBackgroundColor;
    self.tableView.backgroundColor = tableViewBackgroundColor;
    self.tableView.tableHeaderView.backgroundColor = tableViewBackgroundColor;
    self.tableView.tableFooterView.backgroundColor = tableViewBackgroundColor;
    self.packageName.textColor = [UIColor cellPrimaryTextColor];
}

//Dummy method to search for pirated tweakcompatible copies. Will be removed in a future version
- (NSArray *)packageInfoOrder {
    NSString *message = [NSString stringWithFormat:@"A tweak is calling -packageInfoOrder for ZBPackageDepictionViewController. Please report this issue and remove or update the incompatible tweak (most likely a tweak that hooks into Zebra). Last Call: %@ %@ %@", [NSThread callStackSymbols][0], [NSThread callStackSymbols][1], [NSThread callStackSymbols][2]];
    UIAlertController *deprecationAlert = [UIAlertController alertControllerWithTitle:@"Incompatible Tweak" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Ok :(" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [deprecationAlert dismissViewControllerAnimated:true completion:nil];
    }];
    
    [deprecationAlert addAction:action];
    [self presentViewController:deprecationAlert animated:true completion:nil];
    
    return NULL;
}

- (void)receivedData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];

    if (data.length) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        CLS_LOG(@"TweakCompat %@", str);
    }
}

- (void)receivedErrorData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];

    if (data.length) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        CLS_LOG(@"TweakCompat %@", str);
    }
}

#pragma mark TableView

- (void)readIcon:(ZBPackage *)package {
    self.packageName.text = package.name;
    self.packageName.textColor = [UIColor cellPrimaryTextColor];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *sectionImage = [UIImage imageNamed:package.sectionImageName];
        if (sectionImage == NULL) {
            sectionImage = [UIImage imageNamed:@"Other"];
        }
        
        NSString *iconURL = @"";
        if (package.iconPath) {
            iconURL = [package iconPath];
        } else {
            iconURL = [NSString stringWithFormat:@"data:image/png;base64,%@", [UIImagePNGRepresentation(sectionImage) base64EncodedStringWithOptions:0]];
        }
        
        if (iconURL.length) {
            [self.packageIcon sd_setImageWithURL:[NSURL URLWithString:iconURL] placeholderImage:sectionImage];
        }
    });
}

- (void)readPackageID:(ZBPackage *)package {
    if (package.identifier) {
        infos[@(ZBPackageInfoID)] = package.identifier;
    } else {
        [infos removeObjectForKey:@(ZBPackageInfoID)];
    }
}

- (void)setMoreByText:(ZBPackage *)package {
    if (package.author) {
        infos[@(ZBPackageInfoMoreBy)] = NSLocalizedString(@"More by this Developer", @"");
    } else {
        [infos removeObjectForKey:@(ZBPackageInfoMoreBy)];
    }
}

- (void)readVersion:(ZBPackage *)package {
    if (![package isInstalled:NO] || [package installedVersion] == nil) {
        infos[@(ZBPackageInfoVersion)] = package.version;
    } else {
        infos[@(ZBPackageInfoVersion)] = [NSString stringWithFormat:NSLocalizedString(@"%@ (Installed Version: %@)", @""), package.version, [package installedVersion]];
    }
}

- (void)readSize:(ZBPackage *)package {
    NSString *size = [package downloadSizeString];
    NSString *installedSize = [package installedSizeString];
    if (size && installedSize) {
        infos[@(ZBPackageInfoSize)] = [NSString stringWithFormat:NSLocalizedString(@"%@ (Installed Size: %@)", @""), size, installedSize];
    } else if (size) {
        infos[@(ZBPackageInfoSize)] = size;
    } else {
        infos[@(ZBPackageInfoSize)] = @"-";
    }
}

- (void)readRepo:(ZBPackage *)package {
    NSString *repoName = [[package repo] origin];
    if (repoName) {
        infos[@(ZBPackageInfoRepo)] = repoName;
    } else {
        [infos removeObjectForKey:@(ZBPackageInfoRepo)];
    }
}

- (void)readFiles:(ZBPackage *)package {
    if ([package isInstalled:NO]) {
        infos[@(ZBPackageInfoInstalledFiles)] = @"";
    } else {
        [infos removeObjectForKey:@(ZBPackageInfoInstalledFiles)];
    }
}

- (void)readAuthor:(ZBPackage *)package {
    NSString *authorName = [package author];
    if (authorName) {
        infos[@(ZBPackageInfoAuthor)] = [self stripEmailFromAuthor];
    } else {
        [infos removeObjectForKey:@(ZBPackageInfoAuthor)];
    }
}

- (void)setPackage {
    [self readIcon:package];
    [self readAuthor:package];
    [self readVersion:package];
    [self readSize:package];
    [self readRepo:package];
    [self readFiles:package];
    [self readPackageID:package];
    [self setMoreByText:package];
    infos[@(ZBPackageInfoWishList)] = @"";
    [self.tableView reloadData];
}

- (NSUInteger)rowCount {
    return infos.count;
}

- (NSString *)stripEmailFromAuthor {
    if (package.author != NULL && package.author.length > 0) {
        if ([package.author containsString:@"<"] && [package.author containsString:@">"]) {
            NSArray *components = [package.author componentsSeparatedByString:@" <"];
            if ([components count] <= 1) components = [package.author componentsSeparatedByString:@"<"];
            if ([components count] > 1) {
                self.authorEmail = [components[1] stringByReplacingOccurrencesOfString:@">" withString:@""];
                
                return components[0];
            }
        }
        
        return package.author;
    }
    else {
        return NULL;
    }
}

- (void)sendEmailToDeveloper {
    NSString *subject = [NSString stringWithFormat:@"Zebra/APT(Z): %@ (%@)", package.name, package.version]; //don't really know what the (Z) is for but Sileo uses (M) and Cydia uses (A) so i figured (Z) was cool
    NSString *body = [NSString stringWithFormat:@"%@-%@: %@", [ZBDevice deviceModelID], [[UIDevice currentDevice] systemVersion], [ZBDevice UDID]];
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        [mail.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
        [mail setSubject:subject];
        [mail setMessageBody:body isHTML:NO];
        [mail setToRecipients:@[self.authorEmail]];
        
        [self presentViewController:mail animated:YES completion:NULL];
    } else {
        NSString *email = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@", self.authorEmail, subject, body];
        NSString *url = [email stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication]  openURL: [NSURL URLWithString: url]];
        }
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    // handle any error
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return infos[@(indexPath.row)] == nil ? 0 : 45;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"PackageInfoTableViewCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];

    NSString *value = infos[@(indexPath.row)];
    
    if (cell == nil) {
        if (indexPath.row == ZBPackageInfoSize || indexPath.row == ZBPackageInfoVersion || indexPath.row == ZBPackageInfoRepo) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
        } else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
    }

    cell.textLabel.text = nil;
    cell.textLabel.textColor = [UIColor cellPrimaryTextColor];

    cell.detailTextLabel.text = nil;
    cell.detailTextLabel.textColor = [UIColor cellSecondaryTextColor];
    
    switch ((ZBPackageInfoOrder)indexPath.row) {
        case ZBPackageInfoID:
            cell.textLabel.text = value;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        case ZBPackageInfoAuthor:
            cell.textLabel.text = value;
            cell.accessoryType = self.authorEmail ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellSelectionStyleNone;
            break;
        case ZBPackageInfoVersion:
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = NSLocalizedString(@"Version", @"");
            cell.detailTextLabel.text = value;
            break;
        case ZBPackageInfoSize:
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = NSLocalizedString(@"Size", @"");
            cell.detailTextLabel.text = value;
            break;
        case ZBPackageInfoRepo:
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = NSLocalizedString(@"Repo", @"");
            cell.detailTextLabel.text = value;
            break;
        case ZBPackageInfoWishList: {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            BOOL inWishList = [[defaults objectForKey:wishListKey] containsObject:package.identifier];
            cell.textLabel.text = NSLocalizedString(inWishList ? @"Remove from Wish List" : @"Add to Wish List", @"");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        } case ZBPackageInfoMoreBy:
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = value;
            break;
        case ZBPackageInfoInstalledFiles:
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = NSLocalizedString(@"Installed Files", @"");
            break;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row == ZBPackageInfoID;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return (action == @selector(copy:));
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        [pasteBoard setString:cell.textLabel.text];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    assert(section == 0);
    return ZBPackageInfoOrderCount;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBPackageInfoOrder row = indexPath.row;
    switch (row) {
        case ZBPackageInfoID:
            break;
        case ZBPackageInfoAuthor:
            if (self.authorEmail) {
                [self sendEmailToDeveloper];
            }
            break;
        case ZBPackageInfoVersion:
        case ZBPackageInfoSize:
        case ZBPackageInfoRepo:
            break;
        case ZBPackageInfoWishList: {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSMutableArray *wishList = [[defaults objectForKey:wishListKey] mutableCopy];
            BOOL inWishList = [wishList containsObject:package.identifier];
            if (inWishList) {
                [wishList removeObject:package.identifier];
                [defaults setObject:wishList forKey:wishListKey];
            } else {
                [wishList addObject:package.identifier];
                [defaults setObject:wishList forKey:wishListKey];
            }
            [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            break;
        } case ZBPackageInfoMoreBy:
            [self performSegueWithIdentifier:@"seguePackageDepictionToMorePackages" sender:[self stripEmailFromAuthor]];
            break;
        case ZBPackageInfoInstalledFiles: {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            ZBInstalledFilesTableViewController *filesController = [storyboard instantiateViewControllerWithIdentifier:@"installedFilesController"];
            filesController.navigationItem.title = NSLocalizedString(@"Installed Files", @"");
            [filesController setPackage:package];
            [[self navigationController] pushViewController:filesController animated:YES];
            break;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"seguePackageDepictionToMorePackages"]) {
        ZBPackagesByAuthorTableViewController *destination = [segue destinationViewController];
        NSString *authorName = sender;
        destination.package = self.package;
        destination.developerName = authorName;
    }
}

@end
