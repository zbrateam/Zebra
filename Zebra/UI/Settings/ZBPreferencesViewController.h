//
//  ZBPreferencesViewController.h
//  Zebra
//
//  Created by absidue on 20-06-22.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ZBPreferencesCellType) {
    ZBPreferencesCellTypeText,
    ZBPreferencesCellTypeDisclosure,
    ZBPreferencesCellTypeButton,
    ZBPreferencesCellTypeSwitch,
    ZBPreferencesCellTypeSelection
};

NS_ASSUME_NONNULL_BEGIN

@interface ZBPreferencesViewController : UITableViewController
@property (nonatomic, readonly) NSArray <NSArray <NSDictionary *> *> *specifiers;
@property (nonatomic, readonly) NSArray <NSString *> *headers;
@property (nonatomic, readonly) NSArray <NSString *> *footers;
@property NSMutableDictionary <NSNumber *, NSNumber *> *selectedRows;
@end

NS_ASSUME_NONNULL_END
