//
//  ZBCreditsTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 10/25/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBTableViewController.h"

@import SafariServices;

@class ZBCreditsSection;

NS_ASSUME_NONNULL_BEGIN

@interface ZBCreditsTableViewController : ZBTableViewController <SFSafariViewControllerDelegate>
@property (nonatomic, strong, nullable) NSArray <ZBCreditsSection *> *credits;
@end

NS_ASSUME_NONNULL_END
