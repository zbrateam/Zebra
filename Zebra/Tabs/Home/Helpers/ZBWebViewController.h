//
//  ZBWebViewController.h
//  Zebra
//
//  Created by Wilson Styres on 12/27/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <MessageUI/MessageUI.h>
@import SafariServices;

NS_ASSUME_NONNULL_BEGIN

@interface ZBWebViewController : UIViewController <WKNavigationDelegate, WKScriptMessageHandler, MFMailComposeViewControllerDelegate, SFSafariViewControllerDelegate>
@property (nonatomic, strong) id<WKNavigationDelegate> navigationDelegate;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *darkModeButton;
@end

NS_ASSUME_NONNULL_END
