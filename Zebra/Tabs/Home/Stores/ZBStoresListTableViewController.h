//
//  ZBStoresListTableViewController.h
//  Zebra
//
//  Created by va2ron1 on 6/2/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UICKeyChainStore.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBStoresListTableViewController : UITableViewController <SFSafariViewControllerDelegate>
@property (nonatomic, retain) NSMutableArray *tableData;
@property UICKeyChainStore *keychain;
@end

NS_ASSUME_NONNULL_END
