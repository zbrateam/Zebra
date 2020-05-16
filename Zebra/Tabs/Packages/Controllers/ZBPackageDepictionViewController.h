//
//  ZBPackageDepictionViewController.h
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-16.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class ZBPackage;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageDepictionViewController : UIViewController <WKNavigationDelegate, UIScrollViewDelegate>
- (id)initWithPackage:(ZBPackage *)package;
@end

NS_ASSUME_NONNULL_END
