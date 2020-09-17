//
//  ZBSourceSectionsListTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 3/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Extensions/ZBTableViewController.h>
#import "UICKeyChainStore.h"
#import <Tabs/Packages/Helpers/ZBPackageInfoController.h>

@class ZBSource;
@class ZBPackage;

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceSectionsListTableViewController : ZBTableViewController <ZBPackageInfoController, UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) ZBSource *source;
- (id)initWithSource:(ZBSource *)source editOnly:(BOOL)edit;
- (id)initWithPackage:(ZBPackage *)package;
- (void)accountButtonPressed:(id)sender;
@end

NS_ASSUME_NONNULL_END
