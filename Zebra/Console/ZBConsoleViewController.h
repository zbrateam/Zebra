//
//  ZBConsoleViewController.h
//  Zebra
//
//  Created by Wilson Styres on 2/6/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ZBLogLevelDescript,
    ZBLogLevelInfo,
    ZBLogLevelWarning,
    ZBLogLevelError
} ZBLogLevel;

NS_ASSUME_NONNULL_BEGIN

@interface ZBConsoleViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
