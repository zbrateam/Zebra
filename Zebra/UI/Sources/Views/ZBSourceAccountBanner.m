//
//  ZBSourceAccountBanner.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-03-21.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourceAccountBanner.h"
#import "Zebra-Swift.h"
#import "ZBSourceInfo.h"
#import "ZBUserInfo.h"
#import "ZBAppDelegate.h"
#import "ZBSourceViewController.h"

@interface ZBSourceAccountBanner () {
    BOOL hideUDID;
}
@end

@implementation ZBSourceAccountBanner

@synthesize source;
@synthesize owner;
@synthesize sourceInfo;

- (id)initWithSource:(ZBSource *)source andOwner:(ZBSourceViewController *)owner {
    self = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] objectAtIndex:0];
    self.source = source;
    self.owner = owner;
//    [self.source getSourceInfo:^(ZBSourceInfo * _Nonnull info, NSError * _Nonnull error) {
//        if (info && !error) {
//            self.sourceInfo = info;
//        }
//        
//        [self updateText];
//    }];
    
    [self.button addTarget:owner action:@selector(accountButtonPressed:) forControlEvents:UIControlEventTouchDown];
    
    [self applyStyle];
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateText) name:@"ZBSourcesAccountBannerNeedsUpdate" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideSensitiveInformation) name:ZBUserWillTakeScreenshotNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSensitiveInformation) name:ZBUserDidTakeScreenshotNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideSensitiveInformation) name:ZBUserStartedScreenCaptureNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSensitiveInformation) name:ZBUserEndedScreenCaptureNotification object:nil];
}

- (void)hideSensitiveInformation {
    hideEmail = YES;
    [self updateText];
}

- (void)showSensitiveInformation {
    hideEmail = NO;
    [self updateText];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateText {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.activityIndicatorView startAnimating];
//        if ([self->source isSignedIn]) {
//            [self.button setTitle:NSLocalizedString(@"My Account", @"") forState:UIControlStateNormal];
//            [self->source getUserInfo:^(ZBUserInfo * _Nonnull info, NSError * _Nonnull error) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (info && !error) {
//                        if (self->hideEmail) {
//                            self.descriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Signed in as %@", @""), info.user.name];
//                        }
//                        else {
//                            self.descriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Signed in as %@ (%@)", @""), info.user.name, info.user.email];
//                        }
//                    }
//                    else {
//                        self.descriptionLabel.text = NSLocalizedString(@"An Error Occurred", @"");
//                    }
//                    [self.activityIndicatorView stopAnimating];
//                });
//            }];
//        } else {
//            [self.button setTitle:NSLocalizedString(@"Sign In", @"") forState:UIControlStateNormal];
//            if (self->sourceInfo) {
//                self.descriptionLabel.text = self->sourceInfo.authenticationBanner.message;
//            } else {
//                self.descriptionLabel.text = NSLocalizedString(@"An Error Occurred", @"");
//            }
//            [self.activityIndicatorView stopAnimating];
//        }
//    });
}

- (void)applyStyle {
    self.backgroundColor = [[UIColor systemGroupedBackgroundColor] colorWithAlphaComponent:0.6];
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurEffectView.frame = self.bounds;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self insertSubview:blurEffectView atIndex:0];
    self.descriptionLabel.textColor = [UIColor labelColor];
    self.button.tintColor = [UIColor accentColor];
    self.button.layer.cornerRadius = 14;
}

@end
