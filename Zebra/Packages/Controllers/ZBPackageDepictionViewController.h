//
//  ZBPackageDepictionViewController.h
//  Zebra
//
//  Created by Wilson Styres on 1/23/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class ZBPackage;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageDepictionViewController : UIViewController <WKNavigationDelegate, UIViewControllerPreviewing>
@property (nonatomic, strong) ZBPackage *package;
@property (nonatomic, weak) UIViewController *parent;
@end

NS_ASSUME_NONNULL_END
