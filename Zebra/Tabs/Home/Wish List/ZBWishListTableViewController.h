//
//  TableViewController.h
//  Zebra
//
//  Created by midnightchips on 6/18/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Extensions/ZBTableViewController.h>

@interface ZBWishListTableViewController : ZBTableViewController <UIToolbarDelegate>
@property NSMutableArray *wishedPackages;
@property NSMutableArray *wishedPackageIdentifiers;
@end
