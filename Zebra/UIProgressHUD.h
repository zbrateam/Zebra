//
//  UIProgressHUD.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 21/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#ifndef UIProgressHUD_h
#define UIProgressHUD_h

#import <UIKit/UIKit.h>

@interface UIProgressHUD : UIView
- (instancetype)initWithWindow:(UIWindow *)window;
- (void)hide;
- (void)done;
- (void)showInView:(UIView *)view;
- (void)setText:(NSString *)text;
@end

#endif /* UIProgressHUD_h */
