//
//  ZBPackageViewController.h
//  Zebra
//
//  Created by Wilson Styres on 1/23/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLPackage;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>
- (id)initWithPackage:(PLPackage *)package;
@end

NS_ASSUME_NONNULL_END
