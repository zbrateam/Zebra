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

@interface ZBSourcesAccountBanner : UIView {
    BOOL hideEmail;
}
@property (nonatomic, strong) ZBSource *source;
@property (nonatomic, strong) ZBSourceInfo *sourceInfo;
@property (nonatomic, assign) ZBSourceSectionsListTableViewController *owner;

@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *seperatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

- (id)initWithSource:(ZBSource *)source andOwner:(ZBSourceSectionsListTableViewController *)owner;
@end

NS_ASSUME_NONNULL_END
