//
//  ZBSourcePurchasedPackagesTableViewController.h
//  Zebra
//
//  Created by midnightchips on 5/11/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZBSource;

@interface ZBSourceAccountTableViewController : UITableViewController
@property (nonatomic, strong) ZBSource *source;
- (id)initWithSource:(ZBSource *)source;
@end
