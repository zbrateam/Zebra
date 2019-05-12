//
//  ZBRepoPurchases.h
//  Zebra
//
//  Created by midnightchips on 5/11/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UICKeyChainStore.h"

@interface ZBRepoPurchases : UITableViewController
@property NSString *repoName;
@property NSString *repoEndpoint;
@property NSString *userName;
@property NSString *userEmail;
@property UIImage *repoImage;
@property NSArray *packages;
@property UICKeyChainStore *keychain;
@property UIBarButtonItem *logOut;
@end
