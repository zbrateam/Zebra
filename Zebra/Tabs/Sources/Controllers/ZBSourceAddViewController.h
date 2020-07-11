//
//  ZBSourceAddViewController.h
//  Zebra
//
//  Created by Wilson Styres on 6/1/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Sources/Helpers/ZBSourceVerificationDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceAddViewController : UITableViewController <ZBSourceVerificationDelegate, UISearchControllerDelegate, UISearchResultsUpdating>
- (instancetype)initWithDelegate:(UIViewController *)delegate;
@end

NS_ASSUME_NONNULL_END
