//
//  ZBConsoleViewController.h
//  Zebra
//
//  Created by Wilson Styres on 2/6/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBQueue;

#import <UIKit/UIKit.h>
#import <Downloads/ZBDownloadDelegate.h>
#import <Database/ZBDatabaseDelegate.h>
#import <ZBLogLevel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBConsoleViewController : UIViewController <ZBDownloadDelegate, ZBDatabaseDelegate>
@property (strong, nonatomic) IBOutlet UITextView *consoleView;
@property (strong, nonatomic) IBOutlet UIButton *completeButton;
@property (strong, nonatomic) ZBQueue *queue;
@property (nonatomic) BOOL externalInstall;
@property (strong, nonatomic) NSString *externalFilePath;
@end

NS_ASSUME_NONNULL_END
