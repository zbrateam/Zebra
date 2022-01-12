//
//  ZBConsoleViewController.h
//  Zebra
//
//  Created by Wilson Styres on 2/6/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#define COMMAND_START 1

@class ZBQueue;

#import <UIKit/UIKit.h>
#import "ZBDownloadDelegate.h"
#import "ZBDatabaseDelegate.h"
#import "ZBConsoleCommandDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBConsoleViewController : UIViewController <ZBDownloadDelegate, ZBDatabaseDelegate, ZBConsoleCommandDelegate, UIGestureRecognizerDelegate>
@end

NS_ASSUME_NONNULL_END
