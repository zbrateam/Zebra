

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
#import <Keychain/UICKeyChainStore.h>
#import <Queue/ZBQueue.h>
#import <Database/ZBDatabaseManager.h>
#import <SafariServices/SafariServices.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageActionsManager.h>
#import <Sources/Helpers/ZBSource.h>
#import <ZBTabBarController.h>
#import <UIColor+GlobalColors.h>
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
    
    UIBarButtonItem *busyButton;
    UIBarButtonItem *previousButton;
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

- (id)initWithPackage:(ZBPackage *)package {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"packageDepictionVC"];
    
    if (self) {
        self.package = package;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDepiction) name:@"darkMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureNavButton) name:@"ZBUpdateNavigationButtons" object:nil];
    if (presented) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:UIBarButtonItemStylePlain target:self action:@selector(goodbye)];
        self.navigationItem.leftBarButtonItem = closeButton;
    }
    
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    self.navigationItem.title = package.name;
    
    [self.tableView.tableHeaderView setBackgroundColor:[UIColor groupedTableViewBackgroundColor]];
    [self.packageIcon.layer setCornerRadius:20];
    [self.packageIcon.layer setMasksToBounds:YES];
    infos = [NSMutableDictionary new];
    [self setPackage];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    
    switch ([ZBSettings interfaceStyle]) {
        case ZBInterfaceStyleLight:
            configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"Cydia/1.1.32 Zebra/%@ (%@; iOS/%@) Light", PACKAGE_VERSION, [ZBDevice deviceType], [[UIDevice currentDevice] systemVersion]];
        case ZBInterfaceStyleDark:
            configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"Cydia/1.1.32 Zebra/%@ (%@; iOS/%@) Dark", PACKAGE_VERSION, [ZBDevice deviceType], [[UIDevice currentDevice] systemVersion]];
        case ZBInterfaceStylePureBlack:
            configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"Cydia/1.1.32 Zebra/%@ (%@; iOS/%@) Pure-Black", PACKAGE_VERSION, [ZBDevice deviceType], [[UIDevice currentDevice] systemVersion]];
    }
    
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
    
    [progressView setTintColor:[UIColor accentColor] ?: [UIColor systemBlueColor]];
    
    webView.navigationDelegate = self;
    webView.opaque = NO;
    webView.backgroundColor = [UIColor tableViewBackgroundColor];
    
    if ([package depictionURL]) {
        [self prepDepictionLoading:[package depictionURL]];
    } else {
        [self prepDepictionLoading:[[NSBundle mainBundle] URLForResource:@"package_depiction" withExtension:@"html"]];
    }
    [webView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];
    [webView.scrollView addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) options:NSKeyValueObservingOptionNew context:NULL];
    
    CLS_LOG(@"%@ (%@) from %@", [package name], [package identifier], [[package repo] repositoryURI]);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    [self configureNavButton];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)prepDepictionLoading:(NSURL *)url {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    webView.scrollView.backgroundColor = [UIColor tableViewBackgroundColor];
    NSString *version = [[UIDevice currentDevice] systemVersion];
    NSString *udid = [ZBDevice UDID];
    NSString *machineIdentifier = [ZBDevice machineID];
    
    [request setValue:udid forHTTPHeaderField:@"X-Cydia-ID"];

    //Set theme settings and user agent
    switch ([ZBSettings interfaceStyle]) {
        case ZBInterfaceStyleLight: {
            [request setValue:@"Light" forHTTPHeaderField:@"Theme"];
            [request setValue:[NSString stringWithFormat:@"Cydia/1.1.32 Zebra/%@ (%@; iOS/%@) Light", PACKAGE_VERSION, [ZBDevice deviceType], [[UIDevice currentDevice] systemVersion]] forHTTPHeaderField:@"User-Agent"];
        }
        case ZBInterfaceStyleDark: {
            [request setValue:@"Dark" forHTTPHeaderField:@"Theme"];
            [request setValue:[NSString stringWithFormat:@"Cydia/1.1.32 Zebra/%@ (%@; iOS/%@) Dark", PACKAGE_VERSION, [ZBDevice deviceType], [[UIDevice currentDevice] systemVersion]] forHTTPHeaderField:@"User-Agent"];
        }
        case ZBInterfaceStylePureBlack: {
            [request setValue:@"Pure-Black" forHTTPHeaderField:@"Theme"];
            [request setValue:[NSString stringWithFormat:@"Cydia/1.1.32 Zebra/%@ (%@; iOS/%@) Pure-Black", PACKAGE_VERSION, [ZBDevice deviceType], [[UIDevice currentDevice] systemVersion]] forHTTPHeaderField:@"User-Agent"];
        }
    }
    
    [request setValue:version forHTTPHeaderField:@"X-Firmware"];
    [request setValue:udid forHTTPHeaderField:@"X-Unique-ID"];
    [request setValue:machineIdentifier forHTTPHeaderField:@"X-Machine"];
    [request setValue:@"API" forHTTPHeaderField:@"Payment-Provider"];
// FIXME: This is causing crashese with hexStringFromColor for some reason?
    [request setValue:[UIColor hexStringFromColor:[UIColor accentColor]] forHTTPHeaderField:@"Tint-Color"];
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

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (package == nil)
        return;
    
    [self performSelector:@selector(layoutDepictionWebView:) withObject:webView afterDelay:1.0];
    
    NSString *js = @"var meta = document.createElement('meta'); meta.name = 'viewport'; meta.content = 'initial-scale=1, maximum-scale=1, user-scalable=0'; var head = document.getElementsByTagName('head')[0]; head.appendChild(meta);";
    [webView evaluateJavaScript:js completionHandler:nil];
    
    if ([webView.URL.absoluteString isEqualToString:[[NSBundle mainBundle] URLForResource:@"package_depiction" withExtension:@"html"].absoluteString]) {
        if ([ZBSettings interfaceStyle] >= ZBInterfaceStyleDark) {
            NSString *path = [[NSBundle mainBundle] pathForResource:[ZBSettings interfaceStyle] == ZBInterfaceStylePureBlack ? @"ios7oled" : @"ios7dark" ofType:@"css"];

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

- (void)configureNavButton {
    if (navButtonsBeingConfigured) return;
    
    navButtonsBeingConfigured = YES;
    if ([package isInstalled:NO]) { //Show "Modify" button
        if ([package isReinstallable]) {
            if ([package isPaid]) {
                [package purchaseInfo:^(ZBPurchaseInfo * _Nonnull info) {
                    if (info && info.purchased && info.available) {
                        self.purchased = YES;
                        self->package.sileoDownload = YES;
                        [self showModifyButton:YES];
                    }
                    else {
                        [self showRemoveButton];
                    }
                }];
            }
            else {
                navButtonsBeingConfigured = NO;
                [self showModifyButton:YES];
            }
        }
        else {
            navButtonsBeingConfigured = NO;
            [self showModifyButton:YES];
        }
    }
    else if ([package isPaid]) { //Could be a package that needs Payment API verification, lets check it out
        [self setNavigationButtonBusy:YES];
        [package purchaseInfo:^(ZBPurchaseInfo *_Nullable info) {
            if (info) {
                self.package.sileoDownload = YES;
                self.purchased = info.purchased;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (info.price && !(info.error || info.recoveryURL)) {
                        NSString *buttonText = info.purchased ? NSLocalizedString(@"Install", @"") : info.price;
                        self->previousButton = [[UIBarButtonItem alloc] initWithTitle:buttonText style:UIBarButtonItemStylePlain target:self action:@selector(installPackage)];
                        self->previousButton.enabled = info.available && ![[ZBQueue sharedQueue] contains:self->package inQueue:ZBQueueTypeInstall];
                        [self setNavigationButtonBusy:NO];
                        
                        self->navButtonsBeingConfigured = NO;
                    }
                    else {
                        //This behavior is NOT intended I don't think, packages should be available without logging in...
                        self->previousButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Sign In", @"") style:UIBarButtonItemStylePlain target:self action:@selector(signIn)];
                        self->previousButton.enabled = true;
                        [self setNavigationButtonBusy:NO];
                        
                        self->navButtonsBeingConfigured = NO;
                    }
                });
            }
            else {
                self->navButtonsBeingConfigured = NO;
                [self showInstallButton];
            }
        }];
    }
    else {
        // Show the modify button as a last resort
        self->navButtonsBeingConfigured = NO;
        [self showModifyButton:NO];
    }
}

- (void)showInstallButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIBarButtonItem *installButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Install", @"") style:UIBarButtonItemStylePlain target:self action:@selector(installPackage)];
        
        installButton.enabled = ![[ZBQueue sharedQueue] contains:self->package inQueue:ZBQueueTypeInstall];
        self.navigationItem.rightBarButtonItem = installButton;
    });
}

- (void)showModifyButton:(BOOL)installed {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIBarButtonItem *modifyButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Modify", @"") style:UIBarButtonItemStylePlain target:self action:installed ? @selector(modifyPackage) : @selector(ignoredModify)];
        self.navigationItem.rightBarButtonItem = modifyButton;
    });
}

- (void)showRemoveButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Remove", @"") style:UIBarButtonItemStylePlain target:self action:@selector(removePackage)];
        removeButton.enabled = self->package.repo.repoID != -1;
        
        self.navigationItem.rightBarButtonItem = removeButton;
    });
}

- (void)setNavigationButtonBusy:(BOOL)busy {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (busy && self.navigationItem.rightBarButtonItem != nil && self.navigationItem.rightBarButtonItem == self->busyButton) return;
        
        if (!self->busyButton) {
            UIActivityIndicatorView *uiBusy = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [uiBusy startAnimating];
            
            self->busyButton = [[UIBarButtonItem alloc] initWithCustomView:uiBusy];
        }
        
        if (busy) {
            //Save the current button into self.previousButton and set busyButton to rightBarButtonItem
            UIActivityIndicatorView *uiBusy = self->busyButton.customView;
            if ([ZBSettings interfaceStyle] >= ZBInterfaceStyleDark) {
                uiBusy.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
            }
            else {
                uiBusy.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
            }
            
            self->previousButton = self.navigationItem.rightBarButtonItem;
            self.navigationItem.rightBarButtonItem = self->busyButton;
        }
        else {
            //Otherwise we can set the previousbutton back to where it was.
            self.navigationItem.rightBarButtonItem = self->previousButton;
        }
    });
}

- (void)signIn {
    ZBSource *source = [package repo];
    if (source && [source paymentVendorURL]) {
        [source authenticate:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self configureNavButton];
            });
        }];
    }
}

- (void)installPackage {
    if (package.sileoDownload && !self.purchased) {
        [self purchasePackage];
    }
    else {
        [ZBPackageActionsManager installPackage:package purchased:self.purchased];
        [self presentQueue];
        [self configureNavButton];
    }
}

- (void)purchasePackage {
    [self setNavigationButtonBusy:YES];
    
    ZBSource *source = [package repo];
    NSString *repositoryURL = [source repositoryURI];
    
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:[ZBAppDelegate bundleID] accessGroup:nil];
    if ([keychain stringForKey:repositoryURL]) { //Check if we have an access token
        if ([source paymentVendorURL] && [package isPaid]) { //Just a small double check to make sure the package is paid and the repo supports payment
            NSString *secret = [source paymentSecret];
            
            if (secret) {
                NSURL *purchaseURL = [[source paymentVendorURL] URLByAppendingPathComponent:[NSString stringWithFormat:@"package/%@/purchase", [package identifier]]];
                
                NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:purchaseURL];
                
                NSDictionary *requestJSON = @{@"token": [keychain stringForKey:[[package repo] repositoryURI]], @"payment_secret": secret, @"udid": [ZBDevice UDID], @"device": [ZBDevice deviceModelID]};
                NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestJSON options:(NSJSONWritingOptions)0 error:nil];
                
                [request setHTTPMethod:@"POST"];
                [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
                [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
                [request setHTTPBody:requestData];
                
                NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    [self setNavigationButtonBusy:NO];
                    
                    NSHTTPURLResponse *httpReponse = (NSHTTPURLResponse *)response;
                    NSInteger statusCode = [httpReponse statusCode];
                    
                    if (statusCode == 200 && !error) {
                        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                        NSInteger status = [result[@"status"] integerValue];
                        switch (status) {
                            case -1: { //Failure
                                [ZBAppDelegate sendAlertFrom:self message:NSLocalizedString(@"Could not complete purchase", @"")];
                            }
                            case 0: { //Immediate Success
                                [self configureNavButton];
                            }
                            case 1: { //Interaction required
                                [self initPurchaseLink:[NSURL URLWithString:result[@"url"]]];
                            }
                        }
                    }
                }];
                
                [task resume];
            } else {
                [self setNavigationButtonBusy:NO];
                [ZBAppDelegate sendAlertFrom:self message:NSLocalizedString(@"Could not complete purchase, no payment secret was found", @"")];
            }
        }
    }
    else if (source && [source paymentVendorURL]) { //If not, lets log in
        [source authenticate:^(BOOL success, NSError * _Nullable error) {
            [self purchasePackage];
        }];
    }
}

- (void)initPurchaseLink:(NSURL *)url {
    if (@available(iOS 11.0, *)) {
        static SFAuthenticationSession *session;
        session = [[SFAuthenticationSession alloc]
                   initWithURL:url
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
        [ZBDevice openURL:url delegate:self];
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
    NSUInteger originalActions = package.possibleActions;
    [package _setPossibleActions:ZBQueueTypeInstall];
    [self modifyPackage];
    [package _setPossibleActions:originalActions];
}

- (void)dealloc {
    [webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) context:nil];
    [webView.scrollView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) context:nil];
}

- (void)presentQueue {
    if ([self presentingViewController]) {
        [self dismissViewControllerAnimated:YES completion:^{
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

// Haptic Touch Actions

- (NSArray *)contextMenuActionItemsForIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(13.0)) {
    return [ZBPackageActionsManager contextMenuActionsForPackage:package indexPath:indexPath viewController:self parent:_parent];
}

- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully {
    // Load finished
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    // Done button pressed
}

- (void)reloadDepiction {
    UIColor *tableViewBackgroundColor = [UIColor groupedTableViewBackgroundColor];
    [self prepDepictionLoading:webView.URL];
    webView.backgroundColor = tableViewBackgroundColor;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    self.navigationController.navigationBar.barTintColor = tableViewBackgroundColor;
    self.tableView.backgroundColor = tableViewBackgroundColor;
    self.tableView.tableHeaderView.backgroundColor = tableViewBackgroundColor;
    self.tableView.tableFooterView.backgroundColor = tableViewBackgroundColor;
    self.packageName.textColor = [UIColor primaryTextColor];
}

- (NSArray *)packageInfoOrder {
    return NULL;
}

#pragma mark TableView

- (void)readIcon:(ZBPackage *)package {
    self.packageName.text = package.name;
    self.packageName.textColor = [UIColor primaryTextColor];
    
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
    if (package.authorName) {
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
    NSString *authorName = [package authorName];
    if (authorName) {
        infos[@(ZBPackageInfoAuthor)] = authorName;
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
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (NSUInteger)rowCount {
    return infos.count;
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
        [mail setToRecipients:@[self.package.authorEmail]];
        
        [self presentViewController:mail animated:YES completion:NULL];
    } else {
        NSString *email = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@", self.package.authorEmail, subject, body];
        NSString *url = [email stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
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
    cell.textLabel.textColor = [UIColor primaryTextColor];

    cell.detailTextLabel.text = nil;
    cell.detailTextLabel.textColor = [UIColor secondaryTextColor];
    
    switch ((ZBPackageInfoOrder)indexPath.row) {
        case ZBPackageInfoID:
            cell.textLabel.text = value;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        case ZBPackageInfoAuthor:
            cell.textLabel.text = value;
            cell.accessoryType = self.package.authorEmail ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellSelectionStyleNone;
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
            BOOL inWishList = [[ZBSettings wishlist] containsObject:package.identifier];
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
            if (self.package.authorEmail) {
                [self sendEmailToDeveloper];
            }
            break;
        case ZBPackageInfoVersion:
        case ZBPackageInfoSize:
        case ZBPackageInfoRepo:
            break;
        case ZBPackageInfoWishList: {
            NSMutableArray *wishList = [[ZBSettings wishlist] mutableCopy];
            BOOL inWishList = [wishList containsObject:package.identifier];
            if (inWishList) {
                [wishList removeObject:package.identifier];
            } else {
                [wishList addObject:package.identifier];
            }
            [ZBSettings setWishlist:wishList];
            
            [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:ZBPackageInfoWishList inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            break;
        } case ZBPackageInfoMoreBy:
            [self performSegueWithIdentifier:@"seguePackageDepictionToMorePackages" sender:self.package.authorName];
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
