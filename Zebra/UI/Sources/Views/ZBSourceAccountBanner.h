//
//  ZBSourceAccountBanner.h
//  Zebra
//
//  Created by Andrew Abosh on 2020-03-21.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@class ZBSource;
@class ZBSourceViewController;
@class ZBSourceInfo;

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceAccountBanner : UIView {
    BOOL hideEmail;
}
@property (nonatomic, strong) ZBSource *source;
@property (nonatomic, strong) ZBSourceInfo *sourceInfo;
@property (nonatomic, assign) ZBSourceViewController *owner;

@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *seperatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

- (id)initWithSource:(ZBSource *)source andOwner:(ZBSourceViewController *)owner;
@end

NS_ASSUME_NONNULL_END
