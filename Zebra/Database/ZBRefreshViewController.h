//
//  ZBRefreshViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ZBLogLevelDescript,
    ZBLogLevelInfo,
    ZBLogLevelWarning,
    ZBLogLevelError
} ZBLogLevel;

@interface ZBRefreshViewController : UIViewController
@property (nonatomic) BOOL dropTables;
@end

