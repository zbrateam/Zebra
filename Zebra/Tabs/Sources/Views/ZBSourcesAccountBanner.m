//
//  ZBSourcesAccountBanner.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-03-21.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourcesAccountBanner.h"
#import "UIColor+GlobalColors.h"
#import <ZBSource.h>
#import <ZBSourceInfo.h>
#import <ZBUserInfo.h>
#import "ZBRepoSectionsListTableViewController.h"

@implementation ZBSourcesAccountBanner

@synthesize source;
@synthesize owner;
@synthesize sourceInfo;

- (id)initWithSource:(ZBSource *)source andOwner:(ZBRepoSectionsListTableViewController *)owner {
    self = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] objectAtIndex:0];
    self.source = source;
    [self.source getSourceInfo:^(ZBSourceInfo * _Nonnull info, NSError * _Nonnull error) {
        if (info && !error) {
            self.sourceInfo = info;
        }
        
        [self updateText];
    }];
    
    
    self.owner = owner;
    
    [self.button addTarget:owner action:@selector(accountButtonPressed:) forControlEvents:UIControlEventTouchDown];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateText) name:@"ZBSourcesAccountBannerNeedsUpdate" object:nil];
    
    [self applyStyle];
    
    return self;
}

- (void)updateText {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self->source isSignedIn]) {
            [self->source getUserInfo:^(ZBUserInfo * _Nonnull info, NSError * _Nonnull error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (info && !error) {
                        self.descriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Logged in as %@ (%@)", @""), info.user.name, info.user.email];
                        [self.button setTitle:NSLocalizedString(@"My Account", @"") forState:UIControlStateNormal];
                    }
                    else {
                        self.descriptionLabel.text = NSLocalizedString(@"An Error Ocurred", @"");
                        [self.button setTitle:NSLocalizedString(@"Sign In", @"") forState:UIControlStateNormal];
                    }
                });
            }];

        } else if (self->sourceInfo) {
            self.descriptionLabel.text = self->sourceInfo.authenticationBanner.message;
            [self.button setTitle:NSLocalizedString(@"Sign In", @"") forState:UIControlStateNormal];
        }
        else {
            self.descriptionLabel.text = NSLocalizedString(@"An Error Ocurred", @"");
            [self.button setTitle:NSLocalizedString(@"Sign In", @"") forState:UIControlStateNormal];
        }
    });
}

- (void)applyStyle {
    self.backgroundColor = [[UIColor tableViewBackgroundColor] colorWithAlphaComponent:0.6];
    if (@available(iOS 10.0, *)) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = self.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self insertSubview:blurEffectView atIndex:0];
    }
    self.descriptionLabel.textColor = [UIColor primaryTextColor];
    self.button.tintColor = [UIColor accentColor];
    self.button.layer.cornerRadius = 14;
    self.seperatorView.backgroundColor = [UIColor cellSeparatorColor];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ZBSourcesAccountBannerNeedsUpdate" object:nil];
}

@end
