//
//  ZBActionButton.h
//  Zebra
//
//  Created by Andrew Abosh on 2020-05-11.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBActionButton : UIButton
- (void)showActivityLoader;
- (void)hideActivityLoader;
@end

NS_ASSUME_NONNULL_END
