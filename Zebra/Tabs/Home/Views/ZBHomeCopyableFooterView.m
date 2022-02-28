//
//  ZBHomeCopyableFooterView.m
//  Zebra
//
//  Created by Adam Demasi on 27/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import "ZBHomeCopyableFooterView.h"
#import "ZBDevice.h"

@implementation ZBHomeCopyableFooterView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerFired:)]];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // Yeah, layoutSubviews, because UITableViewHeaderFooterView sucks.
    self.textLabel.textAlignment = NSTextAlignmentCenter;
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(copyDeviceInfo:) || action == @selector(copyUDID:)) {
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)copyDeviceInfo:(id)sender {
    [UIPasteboard generalPasteboard].string = [NSString stringWithFormat:@"%@ - iOS %@ - Zebra %@", [ZBDevice deviceModelID], [[UIDevice currentDevice] systemVersion], PACKAGE_VERSION];
}

- (void)copyUDID:(id)sender {
    [UIPasteboard generalPasteboard].string = [ZBDevice UDID];
}

#pragma mark - Events

- (void)tapGestureRecognizerFired:(UITapGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateEnded) {
        return;
    }

    UIMenuController *menuController = [UIMenuController sharedMenuController];
    if (self.isFirstResponder && menuController.isMenuVisible) {
        [self resignFirstResponder];
        if (@available(iOS 13, *)) {
            [menuController hideMenu];
        } else {
            [menuController setMenuVisible:NO animated:YES];
        }
    } else {
        [self becomeFirstResponder];
        menuController.menuItems = @[
            [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Device Info", @"") action:@selector(copyDeviceInfo:)],
            [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy UDID", @"") action:@selector(copyUDID:)]
        ];
        if (@available(iOS 13, *)) {
            [menuController showMenuFromView:self rect:self.bounds];
        } else {
            [menuController setTargetRect:self.bounds inView:self];
            [menuController setMenuVisible:YES animated:YES];
        }
    }
}

@end
