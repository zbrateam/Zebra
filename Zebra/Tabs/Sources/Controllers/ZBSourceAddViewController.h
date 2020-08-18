//
//  ZBSourceAddViewController.h
//  Zebra
//
//  Created by Wilson Styres on 6/1/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import UIKit;
#import <Tabs/Sources/Helpers/ZBSourceVerificationDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceAddViewController : UITableViewController <ZBSourceVerificationDelegate, UISearchControllerDelegate, UISearchResultsUpdating>

@end

NS_ASSUME_NONNULL_END
