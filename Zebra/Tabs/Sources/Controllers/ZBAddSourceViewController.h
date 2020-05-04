//
//  ZBAddSourceViewController.h
//  Zebra
//
//  Created by shiftcmdk on 04/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBSourceVerificationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBAddSourceViewController : UIViewController <UITextViewDelegate>
+ (UINavigationController *)controllerWithText:(NSString *_Nullable)text delegate:(id <ZBSourceVerificationDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
