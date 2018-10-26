//
//  AUPMTabBarController.h
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AUPMTabBarController : UITabBarController
- (void)performBackgroundRefresh:(BOOL)requested;
//- (void)updatePackageTableView;
@end

NS_ASSUME_NONNULL_END
