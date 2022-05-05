//
//  ZBLabelTextView.h
//  Zebra
//
//  Created by Adam Demasi on 7/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZBLabelTextViewLinkHandler)(NSURL *url);

@interface ZBLabelTextView : UITextView

@property (nonatomic, copy) ZBLabelTextViewLinkHandler linkHandler;

@end

NS_ASSUME_NONNULL_END
