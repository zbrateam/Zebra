//
//  ZBCreditsTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 10/25/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Extensions/ZBTableViewController.h>

@import SafariServices;

NS_ASSUME_NONNULL_BEGIN

@interface ZBCreditsTableViewController : ZBTableViewController <SFSafariViewControllerDelegate>
@property (nonatomic, strong) NSArray <NSDictionary <NSString *, id> *> *credits;
@end

NS_ASSUME_NONNULL_END
