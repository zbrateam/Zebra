//
//  ZBPackageTableViewCell.h
//  Zebra
//
//  Created by Andrew Abosh on 2019-05-01.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class PLPackage;

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageTableViewCell : UITableViewCell
@property BOOL showSize;
@property BOOL showVersion;
@property (nonatomic) BOOL showBadges;
- (void)setPackage:(PLPackage *)package;
@end

NS_ASSUME_NONNULL_END
