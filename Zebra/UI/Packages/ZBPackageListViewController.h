//
//  ZBPackageListViewController.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@import UIKit;

@class ZBSource;
@class ZBPackage;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageListViewController : UITableViewController
@property ZBSource *source;
@property NSString *_Nullable section;
@property NSArray <ZBPackage *> *packages;
#pragma mark - Initializers
- (instancetype)initWithSource:(ZBSource *)source;
- (instancetype)initWithSource:(ZBSource *)source section:(NSString *_Nullable)section;
- (instancetype)initWithPackages:(NSArray <ZBPackage *> *)packages;
@end

NS_ASSUME_NONNULL_END
