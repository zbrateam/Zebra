//
//  TableViewController.h
//  Zebra
//
//  Created by midnightchips on 6/18/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBTableViewController.h"

@interface ZBWishListTableViewController : ZBTableViewController <UIToolbarDelegate>
@property (nonatomic, strong) NSMutableArray *wishedPackages;
@property (nonatomic, strong) NSMutableArray *wishedPackageIdentifiers;
@end
