//
//  ZBSourcePurchasedPackagesTableViewController.h
//  Zebra
//
//  Created by midnightchips on 5/11/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Extensions/ZBTableViewController.h>

@class ZBSource;

@interface ZBSourceAccountTableViewController : ZBTableViewController <UIViewControllerPreviewingDelegate>
@property (nonatomic, strong) ZBSource *source;
- (id)initWithSource:(ZBSource *)source;
@end
