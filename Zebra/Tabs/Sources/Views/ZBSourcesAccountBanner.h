//
//  ZBSourcesAccountBanner.h
//  Zebra
//
//  Created by Andrew Abosh on 2020-03-21.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@class ZBSource;
@class ZBSourceSectionsListTableViewController;
@class ZBSourceInfo;

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourcesAccountBanner : UIView
@property (nonatomic, strong) ZBSource *source;
@property (nonatomic, strong) ZBSourceInfo *sourceInfo;
@property (nonatomic, weak) ZBSourceSectionsListTableViewController *owner;

@property (strong, nonatomic) IBOutlet UIButton *button;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UIView *seperatorView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

- (id)initWithSource:(ZBSource *)source andOwner:(ZBSourceSectionsListTableViewController *)owner;
@end

NS_ASSUME_NONNULL_END
