//
//  ZBSettingsSelectionTableViewController.h
//  Zebra
//
//  Created by Louis on 02/11/2019.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSettingsSelectionTableViewController : UITableViewController
@property void (^settingChanged)(void);

@property NSString *settingsKey;
@property NSArray <NSString *> *footerText;
@property NSArray <NSString *> *options;

- (id)initWithOptions:(NSArray *)selectionOptions getter:(SEL)getter setter:(SEL)setter settingChangedCallback:(nullable void (^)(void))callback;
@end

NS_ASSUME_NONNULL_END
