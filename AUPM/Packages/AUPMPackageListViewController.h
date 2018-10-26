//
//  AUPMPackageListViewController.h
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>

@class AUPMRepo;

NS_ASSUME_NONNULL_BEGIN

@interface AUPMPackageListViewController : UITableViewController
- (id)initWithRepo:(AUPMRepo *)repo;
- (void)refreshTable;
@end

NS_ASSUME_NONNULL_END
