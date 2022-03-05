//
//  ZBAppDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const ZBUserWillTakeScreenshotNotification;
extern NSString * const ZBUserDidTakeScreenshotNotification;

extern NSString * const ZBUserStartedScreenCaptureNotification;
extern NSString * const ZBUserEndedScreenCaptureNotification;

@interface ZBAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, UIDropInteractionDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

