//
//  ZBAppIconSettingsViewController.h
//  Zebra
//
//  Created by Wilson Styres on 5/14/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBPreferencesViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBAppIconSettingsViewController : ZBPreferencesViewController {
    NSArray <NSDictionary *> *icons;
    NSArray <UIImage *> *iconImages;
}
@end

NS_ASSUME_NONNULL_END
