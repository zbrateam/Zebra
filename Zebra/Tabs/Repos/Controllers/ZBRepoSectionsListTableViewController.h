//
//  ZBRepoSectionsListTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 3/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UICKeyChainStore.h"

@class ZBRepo;
@class ZBDatabaseManager;

NS_ASSUME_NONNULL_BEGIN

@interface ZBRepoSectionsListTableViewController : UITableViewController <SFSafariViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource>
@property (strong, nonatomic) IBOutlet UICollectionView *featuredCollection;
@property (nonatomic, strong) ZBDatabaseManager *databaseManager;
@property (nonatomic, strong) ZBRepo *repo;
@property (nonatomic, strong) NSDictionary *sectionReadout;
@property (nonatomic, strong) NSArray *sectionNames;
@property (nonatomic, strong) NSString *repoEndpoint;
@property (nonatomic, strong) NSArray *featuredPackages;
@property (nonatomic, strong) NSDictionary *fullJSON;
@property UICKeyChainStore *keychain;
@property UIBarButtonItem *purchased;
@property UIBarButtonItem *login;
@end

NS_ASSUME_NONNULL_END
