//
//  ZBDarkModeHelper.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 14/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBDarkModeHelper : NSObject
+ (BOOL)darkModeEnabled;
+ (void)setDarkModeEnabled:(BOOL)enabled;
+ (void)configureDark;
+ (void)configureLight;
+ (void)applySettings;
+ (void)refreshViews;
@end

NS_ASSUME_NONNULL_END
