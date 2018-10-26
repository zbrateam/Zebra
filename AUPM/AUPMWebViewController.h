//
//  AUPMWebViewController.h
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <MessageUI/MessageUI.h>
#import <Realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

@interface AUPMWebViewController : UIViewController <WKNavigationDelegate, WKScriptMessageHandler, MFMailComposeViewControllerDelegate>
- (id)initWithURL:(NSURL *)url;
@end

NS_ASSUME_NONNULL_END
