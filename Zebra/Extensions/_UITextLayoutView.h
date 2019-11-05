//
//  _UITextLayoutView.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 2/11/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

// TODO: Remove this hack once an Xcode update (> 11.2) has been released to fix this issue

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface _UITextLayoutView : UIView
@property(nonatomic, weak) UITextView *delegate;
@end

@interface UITextView (Private)
- (void)_layoutText;
@end

NS_ASSUME_NONNULL_END
