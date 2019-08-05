

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
#import "ZBWebViewController.h"
@import SDWebImage;


enum ZBPackageInfoOrder {
    ZBPackageInfoID = 0,
    ZBPackageInfoAuthor,
    ZBPackageInfoVersion,
    ZBPackageInfoSize,
    ZBPackageInfoRepo,
    ZBPackageInfoWishList,
    ZBPackageInfoMoreBy,
    ZBPackageInfoInstalledFiles
};

@interface ZBPackageDepictionViewController () {
    NSMutableDictionary *infos;
    UIProgressView *progressView;
    WKWebView *webView;
    BOOL presented;
    BOOL navButtonsBeingConfigured;
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
        presented = YES;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDepiction) name:@"darkMode" object:nil];
    if (presented) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(goodbye)];
        self.navigationItem.leftBarButtonItem = closeButton;
    }
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    // self.navigationController.view.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.95 alpha:1.0];
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
    
    webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 600) configuration:configuration];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    
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
    [webView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    [self configureNavButton];
}

- (void)prepDepictionLoading:(NSURL *)url {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    webView.scrollView.backgroundColor = [UIColor tableViewBackgroundColor];
    NSString *version = [[UIDevice currentDevice] systemVersion];
    NSString *udid = [ZBDevice UDID];
    NSString *machineIdentifier = [ZBDevice machineID];
    
    [request setValue:udid forHTTPHeaderField:@"X-Cydia-ID"];
    if ([ZBDevice darkModeEnabled]) {
        [request setValue:@"TRUE" forHTTPHeaderField:@"Dark"];
        if([ZBDevice darkModeOledEnabled]) {
            // These headers must be "TRUE" no one change these to "YES" or else some repos will not be able to detect it.
            [request setValue:@"TRUE" forHTTPHeaderField:@"Oled"];
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
        filesController.navigationItem.title = @"Installed Files";
        NSURL *url = [[NSBundle mainBundle] URLForResource:action withExtension:@".html"];
        [filesController setValue:url forKey:@"_url"];
        
        [[self navigationController] pushViewController:filesController animated:YES];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (package == nil)
        return;
    [webView evaluateJavaScript:@"document.readyState" completionHandler:^(id _Nullable completed, NSError * _Nullable error) {
        if (completed != nil) {
            [webView evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(id _Nullable height, NSError * _Nullable error) {
                [webView setFrame:CGRectMake(webView.frame.origin.x, webView.frame.origin.y, webView.frame.size.width, [height floatValue])];
                /*self.tableView.tableFooterView.frame = CGRectMake(webView.frame.origin.x, webView.frame.origin.y, webView.frame.size.width, [height floatValue]);*/
                [self.tableView beginUpdates];
                [self.tableView setTableFooterView:webView];
                [self.tableView endUpdates];
                ZBLog(@"DONE");
            }];
        }
    }];
    // webView.frame = CGRectMake(webView.frame.origin.x, webView.frame.origin.y, webView.frame.size.width, [webView evaluateJavaScript:@"document.height" completionHandler:nil]);
    
    NSString *js = @"var meta = document.createElement('meta'); meta.name = 'viewport'; meta.content = 'initial-scale=1, maximum-scale=1, user-scalable=0'; var head = document.getElementsByTagName('head')[0]; head.appendChild(meta);";
    [webView evaluateJavaScript:js completionHandler:nil];
    
    if ([webView.URL.absoluteString isEqualToString:[[NSBundle mainBundle] URLForResource:@"package_depiction" withExtension:@"html"].absoluteString]) {
        
        [webView setFrame:CGRectMake(webView.frame.origin.x, webView.frame.origin.y, webView.frame.size.width, 200)];
        /*self.tableView.tableFooterView.frame = CGRectMake(webView.frame.origin.x, webView.frame.origin.y, webView.frame.size.width, [height floatValue]);*/
        [self.tableView beginUpdates];
        [self.tableView setTableFooterView:webView];
        [self.tableView endUpdates];
        
        if ([ZBDevice darkModeEnabled]) {
            NSString *path;
            if([ZBDevice darkModeOledEnabled]) {
                path = [[NSBundle mainBundle] pathForResource:@"ios7oled" ofType:@"css"];
            }else {
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
        }
        else {
            [webView evaluateJavaScript:@"var element = document.getElementById('desc-holder').outerHTML = '';" completionHandler:nil];
        }
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
                [sfVC setPreferredBarTintColor:[UIColor tableViewBackgroundColor]];
                [sfVC setPreferredControlTintColor:[UIColor tintColor]];
            } else {
                [sfVC.view setTintColor:[UIColor tintColor]];
            }
            [self presentViewController:sfVC animated:YES completion:nil];
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

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    [self prepDepictionLoading:[[NSBundle mainBundle] URLForResource:@"package_depiction" withExtension:@"html"]];
}

- (void)addModifyButton {
    UIBarButtonItem *modifyButton = [[UIBarButtonItem alloc] initWithTitle:@"Modify" style:UIBarButtonItemStylePlain target:self action:@selector(modifyPackage)];
    self.navigationItem.rightBarButtonItem = modifyButton;
}

- (void)configureNavButton {
    if (self->navButtonsBeingConfigured) {
        return;
    }
    self->navButtonsBeingConfigured = YES;
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    if ([package isInstalled:NO]) {
        if ([package isReinstallable]) {
            if ([package isPaid] && [keychain[[keychain stringForKey:[package repo].baseURL]] length] != 0) {
                [self determinePaidPackage];
            } else {
                [self addModifyButton];
            }
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
    self->navButtonsBeingConfigured = NO;
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
                                    @"udid": [ZBDevice UDID],
                                    @"device": [ZBDevice deviceModelID] };
            NSData *requestData = [NSJSONSerialization dataWithJSONObject:test options:(NSJSONWritingOptions)0 error:nil];
            
            NSMutableURLRequest *request = [NSMutableURLRequest new];
            [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@package/%@/info", [keychain stringForKey:[package repo].baseURL], package.identifier]]];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
            [request setValue:[NSString stringWithFormat:@"Zebra/%@ iOS/%@ (%@)", PACKAGE_VERSION, [[UIDevice currentDevice] systemVersion], [ZBDevice deviceType]] forHTTPHeaderField:@"User-Agent"];
            [request setHTTPBody: requestData];
            [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSString *title = [[ZBQueue sharedInstance] queueToKey:ZBQueueTypeInstall];
                SEL selector = @selector(installPackage);
                if (data) {
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    ZBLog(@"[Zebra] Package purchase status response: %@", json);
                    BOOL purchased = [json[@"purchased"] boolValue];
                    BOOL available = [json[@"available"] boolValue];
                    BOOL installed = [self->package isInstalled:NO];
                    if (installed) {
                        BOOL set = NO;
                        if (purchased) {
                            self->package.sileoDownload = YES;
                            self.purchased = YES;
                            if (available && ![self->package isReinstallable]) {
                                title = [[ZBQueue sharedInstance] queueToKey:ZBQueueTypeRemove];
                                selector = @selector(removePackage);
                                set = YES;
                            }
                        }
                        if (!set) {
                            title = @"Modify";
                            selector = @selector(modifyPackage);
                        }
                    }
                    else if (available) {
                        if (purchased) {
                            self->package.sileoDownload = YES;
                            self.purchased = YES;
                        }
                        else {
                            title = json[@"price"];
                            selector = @selector(purchasePackage);
                        }
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
                keychain.authenticationPrompt = @"Authenticate to initiate purchase.";
                secret = keychain[idThing];
                dispatch_semaphore_signal(sema);
                if (error) {
                    ZBLog(@"[Zebra] Package purchase error: %@", error.localizedDescription);
                }
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            // Continue
            if ([secret length] != 0) {
                NSDictionary *requestJSON = @{ @"token": keychain[[keychain stringForKey:[package repo].baseURL]],
                                               @"payment_secret": secret,
                                               @"udid": [ZBDevice UDID],
                                               @"device": [ZBDevice deviceModelID] };
                NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestJSON options:(NSJSONWritingOptions)0 error:nil];
                
                NSMutableURLRequest *request = [NSMutableURLRequest new];
                [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@package/%@/purchase",[keychain stringForKey:[package repo].baseURL], package.identifier]]];
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
                        }
                        else {
                            [self configureNavButton];
                        }
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
    if (link == nil) {
        [ZBAppDelegate sendErrorToTabController:[NSString stringWithFormat:@"Please relogin your account that is used to purchase this package (Possibly %@)", package.repo.origin]];
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
                           
                           NSError *error;
                           // [self->_keychain setString:token forKey:self.repoEndpoint error:&error];
                           if (error) {
                               ZBLog(@"[Zebra] Error initializing purchase page: %@", error.localizedDescription);
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
        if (@available(iOS 10.0, *)) {
            [safariVC setPreferredBarTintColor:[UIColor tableViewBackgroundColor]];
            [safariVC setPreferredControlTintColor:[UIColor tintColor]];
        } else {
            [safariVC.view setTintColor:[UIColor tintColor]];
        }
        [self presentViewController:safariVC animated:YES completion:nil];
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
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)dealloc {
    [webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) context:nil];
}

- (void)presentQueue {
    [ZBPackageActionsManager presentQueue:self parent:_parent];
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
    [self prepDepictionLoading:webView.URL];
    webView.backgroundColor = [UIColor tableViewBackgroundColor];
    [self.tableView reloadData];
    [self.navigationController.navigationBar setBarTintColor:[UIColor tableViewBackgroundColor]];
    [self.tableView setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [self.tableView.tableHeaderView setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [self.tableView.tableFooterView setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [self.packageName setTextColor:[UIColor cellPrimaryTextColor]];
}

#pragma mark TableView

- (CGFloat)rowHeight {
    return 45;
}

- (NSArray *)packageInfoOrder {
    static NSArray *packageInfoOrder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        packageInfoOrder = @[
                             @"packageID",
                             @"Author",
                             @"Version",
                             @"Size",
                             @"Repo",
                             @"wishList",
                             @"moreBy",
                             @"Installed Files"
                             ];
    });
    return packageInfoOrder;
}

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
        }
        else {
            iconURL = [NSString stringWithFormat:@"data:image/png;base64,%@", [UIImagePNGRepresentation(sectionImage) base64EncodedStringWithOptions:0]];
        }
        
        if (iconURL.length) {
            [self.packageIcon sd_setImageWithURL:[NSURL URLWithString:iconURL] placeholderImage:sectionImage];
        }
    });
}

- (void)readPackageID:(ZBPackage *)package {
    if (package.identifier) {
        infos[@"packageID"] = package.identifier;
    }
    else {
        [infos removeObjectForKey:@"packageID"];
    }
}

- (void)checkWishList:(ZBPackage *)package {
    NSArray *wishList = [[NSUserDefaults standardUserDefaults] objectForKey:@"wishList"];
    if ([wishList containsObject:package.identifier]) {
        infos[@"wishList"] = @"Remove from Wish List";
    } else {
        infos[@"wishList"] = @"Add to Wish List";
    }
}

- (void)setMoreByText:(ZBPackage *)package {
    if (package.author) {
        infos[@"moreBy"] = @"More by this Developer";
    } else {
        [infos removeObjectForKey:@"moreBy"];
    }
}

- (void)readVersion:(ZBPackage *)package {
    if (![package isInstalled:NO] || [package installedVersion] == nil) {
        infos[@"Version"] = [package version];
    }
    else {
        infos[@"Version"] = [NSString stringWithFormat:@"%@ (Installed Version: %@)", [package version], [package installedVersion]];
    }
}

- (void)readSize:(ZBPackage *)package {
    NSString *size = [package size];
    NSString *installedSize = [package installedSize];
    if (size && installedSize) {
        infos[@"Size"] = [NSString stringWithFormat:@"%@ (Installed Size: %@)", size, installedSize];
    }
    else if (size) {
        infos[@"Size"] = size;
    }
    else {
        [infos removeObjectForKey:@"Size"];
    }
}

- (void)readRepo:(ZBPackage *)package {
    NSString *repoName = [[package repo] origin];
    if (repoName) {
        infos[@"Repo"] = repoName;
    }
    else {
        [infos removeObjectForKey:@"Repo"];
    }
}

- (void)readFiles:(ZBPackage *)package {
    if ([package isInstalled:NO]) {
        infos[@"Installed Files"] = @"";
    }
    else {
        [infos removeObjectForKey:@"Installed Files"];
    }
}

- (void)readAuthor:(ZBPackage *)package {
    NSString *authorName = [package author];
    if (authorName) {
        infos[@"Author"] = [self stripEmailFromAuthor];
    } else {
        [infos removeObjectForKey:@"Author"];
    }
}

- (void)setPackage{
    [self readIcon:package];
    [self readAuthor:package];
    [self readVersion:package];
    [self readSize:package];
    [self readRepo:package];
    [self readFiles:package];
    [self readPackageID:package];
    [self checkWishList:package];
    [self setMoreByText:package];
    [self.tableView reloadData];
}

- (NSUInteger)rowCount {
    return infos.count;
}

- (void)generateWishlist {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *wishList = [[defaults objectForKey:@"wishList"] mutableCopy];
    if (!wishList) {
        wishList = [NSMutableArray new];
    }
    if ([wishList containsObject:package.identifier]) {
        [wishList removeObject:package.identifier];
        [defaults setObject:wishList forKey:@"wishList"];
        [defaults synchronize];
        [self checkWishList:package];
        [self.tableView reloadData];
    } else {
        [wishList addObject:package.identifier];
        [defaults setObject:wishList forKey:@"wishList"];
        [defaults synchronize];
        [self checkWishList:package];
        [self.tableView reloadData];
    }
}

- (NSString *)stripEmailFromAuthor {
    NSArray *authorName = [package.author componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSMutableArray *cleanedStrings = [NSMutableArray new];
    for(NSString *cut in authorName) {
        if (![cut hasPrefix:@"<"] && ![cut hasSuffix:@">"]) {
            [cleanedStrings addObject:cut];
        } else {
            NSString *cutCopy = [cut copy];
            cutCopy = [cut substringFromIndex:1];
            cutCopy = [cutCopy substringWithRange:NSMakeRange(0, cutCopy.length - 1)];
            self.authorEmail = cutCopy;
        }
    }
    
    return [cleanedStrings componentsJoinedByString:@" "];
}

- (void)sendEmailToDeveloper {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        [mail.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
        NSString *subject = [NSString stringWithFormat:@"Zebra %@: %@ Support (%@)", PACKAGE_VERSION, package.name, package.version];
        [mail setSubject:subject];
        NSString *body = [NSString stringWithFormat:@"%@: %@\n%@", [ZBDevice deviceModelID], [[UIDevice currentDevice] systemVersion], [ZBDevice UDID]];
        [mail setMessageBody:body isHTML:NO];
        [mail setToRecipients:@[self.authorEmail]];
        
        [self presentViewController:mail animated:YES completion:NULL];
    } else {
        NSString *email = [NSString stringWithFormat:@"mailto:%@?subject=%@ Support Zebra %@", self.authorEmail, package.name, @"Arbitrary Number"];
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
    NSString *property = [self packageInfoOrder][indexPath.row];
    NSString *value = infos[property];
    return value ? [self rowHeight] : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"PackageInfoTableViewCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    NSString *property = [self packageInfoOrder][indexPath.row];
    NSString *value = infos[property];
    
    if (indexPath.row == ZBPackageInfoInstalledFiles) {
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = property;
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
    }
    else if (indexPath.row == ZBPackageInfoMoreBy || indexPath.row == ZBPackageInfoWishList) {
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = value;
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
    }
    else if (indexPath.row == ZBPackageInfoID) {
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        cell.textLabel.text = value;
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    else if (indexPath.row == ZBPackageInfoAuthor) {
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        cell.textLabel.text = value;
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        if (self.authorEmail) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
    }
    else {
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        if (value) {
            cell.textLabel.text = property;
            cell.detailTextLabel.text = value;
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            cell.detailTextLabel.textColor = [UIColor cellSecondaryTextColor];
        }
        else {
            cell.textLabel.text = nil;
            cell.detailTextLabel.text = nil;
        }
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self packageInfoOrder].count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == ZBPackageInfoInstalledFiles) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ZBInstalledFilesTableViewController *filesController = [storyboard instantiateViewControllerWithIdentifier:@"installedFilesController"];
        filesController.navigationItem.title = @"Installed Files";
        [filesController setPackage:package];
        [[self navigationController] pushViewController:filesController animated:YES];
    }
    else if (indexPath.row == ZBPackageInfoWishList) {
        [self generateWishlist];
    } else if (indexPath.row == ZBPackageInfoMoreBy) {
        [self performSegueWithIdentifier:@"seguePackageDepictionToMorePackages" sender:[self stripEmailFromAuthor]];
    } else if (indexPath.row == ZBPackageInfoAuthor && self.authorEmail) {
        [self sendEmailToDeveloper];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// More By author button
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"seguePackageDepictionToMorePackages"]) {
        ZBPackagesByAuthorTableViewController *destination = (ZBPackagesByAuthorTableViewController *)[segue destinationViewController];
        NSString *authorName = sender;
        destination.package = self.package;
        destination.developerName = authorName;
    }
}

@end
