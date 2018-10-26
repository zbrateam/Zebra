//
//  AUPMSearchViewController.h
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

@class AUPMPackage;

@interface AUPMSearchViewController : UITableViewController <UISearchBarDelegate>
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) RLMResults<AUPMPackage *> *results;
@end

NS_ASSUME_NONNULL_END
