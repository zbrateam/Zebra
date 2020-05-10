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

@interface UINavigationBar ()
@property (assign,setter=_setBackgroundOpacity:,nonatomic) double _backgroundOpacity;
@property (nonatomic,copy) NSArray * backgroundEffects;  
@end

@interface ZBPackageDepictionViewController : UIViewController <WKNavigationDelegate, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>
- (id)initWithPackage:(ZBPackage *)package;
@end

NS_ASSUME_NONNULL_END
