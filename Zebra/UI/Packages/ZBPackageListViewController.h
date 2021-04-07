//
//  ZBPackageListViewController.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <UI/Common/Delegates/ZBFilterDelegate.h>

@class PLSource;
@class PLPackage;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageListViewController : UITableViewController <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UIViewControllerTransitioningDelegate, ZBFilterDelegate>
@property PLSource *source;
@property NSString *_Nullable section;
@property NSArray <PLPackage *> *packages;
@property NSArray <NSString *> *_Nullable identifiers;
#pragma mark - Initializers
- (instancetype)initWithSource:(PLSource *)source section:(NSString *_Nullable)section;
- (instancetype)initWithPackages:(NSArray <PLPackage *> *)packages;
- (instancetype)initWithPackageIdentifiers:(NSArray <NSString *> *)identifiers;
@end

NS_ASSUME_NONNULL_END
