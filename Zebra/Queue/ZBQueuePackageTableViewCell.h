//
//  ZBQueuePackageTableViewCell.h
//  Zebra
//
//  Created by Amy While on 01/06/2023.
//  Copyright © 2023 Zebra Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBPackage.h"
#import "ZBQueue.h"
#import "ZBAppDelegate.h"
#import "UIColor+GlobalColors.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBQueuePackageTableViewCell : UITableViewCell
-(void)setPackage:(ZBPackage *)package onQueue:(ZBQueue *)queue;
@end

NS_ASSUME_NONNULL_END
