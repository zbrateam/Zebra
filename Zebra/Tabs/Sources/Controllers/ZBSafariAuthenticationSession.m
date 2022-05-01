//
//  ZBSafariAuthenticationSession.m
//  Zebra
//
//  Created by Adam Demasi on 30/4/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import "ZBSafariAuthenticationSession.h"
#import "UIColor+GlobalColors.h"

NSString *const ZBSafariAuthenticationErrorDomain = @"ZBSafariAuthenticationErrorDomain";

static ZBSafariAuthenticationSession *currentSession = nil;

@interface ZBSafariAuthenticationSession () <SFSafariViewControllerDelegate>

@end

@implementation ZBSafariAuthenticationSession {
    NSURL *_url;
    NSString *_callbackURLScheme;
    SFAuthenticationCompletionHandler _completionHandler;
    id _session;
    SFSafariViewController *_safariViewController;
}

+ (void)handleCallbackURL:(NSURL *)url {
    [currentSession _handleCallbackURL:url error:nil];
}

- (instancetype)initWithURL:(NSURL *)url callbackURLScheme:(nullable NSString *)callbackURLScheme completionHandler:(SFAuthenticationCompletionHandler)completionHandler {
    self = [super init];
    if (self) {
        _url = url;
        _callbackURLScheme = callbackURLScheme;
        _completionHandler = [completionHandler copy];
    }
    return self;
}

- (void)start {
    if (@available(iOS 11, *)) {
        SFAuthenticationSession *session = [[SFAuthenticationSession alloc] initWithURL:_url
                                                                      callbackURLScheme:_callbackURLScheme
                                                                      completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
            if (error) {
                // Rebuild the error with our error domain.
                error = [NSError errorWithDomain:ZBSafariAuthenticationErrorDomain code:error.code userInfo:error.userInfo];
            }
            [self _handleCallbackURL:callbackURL error:error];
        }];
        [session start];
        _session = session;
        return;
    }

    _safariViewController = [[SFSafariViewController alloc] initWithURL:_url entersReaderIfAvailable:NO];
    _safariViewController.delegate = self;
    _safariViewController.modalPresentationStyle = UIModalPresentationFormSheet;

    UIColor *tintColor = [UIColor accentColor] ?: [UIColor systemBlueColor];
    if (@available(iOS 10, *)) {
        _safariViewController.preferredBarTintColor = [UIColor groupedTableViewBackgroundColor];
        _safariViewController.preferredControlTintColor = tintColor;
    } else {
        _safariViewController.view.tintColor = tintColor;
    }

    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:_safariViewController animated:YES completion:nil];
    currentSession = self;
}

- (void)_handleCallbackURL:(NSURL *)url error:(NSError *)error {
    currentSession = nil;
    if (_safariViewController) {
        [_safariViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            self->_completionHandler(url, error);
        }];
    } else {
        _completionHandler(url, error);
    }
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    // User cancelled by tapping Done or swiping back.
    if (_completionHandler) {
        _completionHandler(nil, [NSError errorWithDomain:ZBSafariAuthenticationErrorDomain code:ZBSafariAuthenticationErrorCanceledLogin userInfo:nil]);
    }
    currentSession = nil;
}

- (NSArray<UIActivity *> *)safariViewController:(SFSafariViewController *)controller activityItemsForURL:(NSURL *)URL title:(NSString *)title {
    return @[];
}

@end
