//
//  ZBSettingsSelectionTableViewController.h
//  Zebra
//
//  Created by Louis on 02/11/2019.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBSettingsSelectionTableViewController : ZBTableViewController
@property (nonatomic, copy) void (^settingChanged)(void);

@property (nonatomic, strong) NSString *settingsKey;
@property (nonatomic, strong) NSArray <NSString *> *footerText;
@property (nonatomic, strong) NSArray <NSString *> *options;

- (id)initWithOptions:(NSArray *)selectionOptions getter:(SEL)getter setter:(SEL)setter settingChangedCallback:(nullable void (^)(void))callback;
@end

NS_ASSUME_NONNULL_END
