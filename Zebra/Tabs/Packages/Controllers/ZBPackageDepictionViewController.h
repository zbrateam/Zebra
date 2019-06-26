//
//  ZBPackageDepictionViewController.h
//  Zebra
//
//  Created by Wilson Styres on 1/23/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <Packages/Views/ZBPackageInfoView.h>
#import <Packages/Controllers/ZBPackagesByAuthorTableViewController.h>
@import SafariServices;

@class ZBPackage;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageDepictionViewController : UIViewController <WKNavigationDelegate, WKScriptMessageHandler, UIViewControllerPreviewing, SFSafariViewControllerDelegate>
@property (nonatomic, strong) ZBPackage *package;
@property (strong, nonatomic) IBOutlet ZBPackageInfoView *packageInfoView;
@property BOOL purchased;
@property (nonatomic, weak) UIViewController *parent;
- (id)initWithPackageID:(NSString *)packageID;
@end

NS_ASSUME_NONNULL_END
