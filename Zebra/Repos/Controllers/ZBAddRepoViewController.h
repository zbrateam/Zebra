//
//  ZBAddRepoViewController.h
//  Zebra
//
//  Created by shiftcmdk on 04/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBAddRepoDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBAddRepoViewController : UIViewController

@property (nonatomic, copy) NSString *text;
@property (nonatomic, weak) id <ZBAddRepoDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
