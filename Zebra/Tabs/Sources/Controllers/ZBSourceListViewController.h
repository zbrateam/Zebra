//
//  ZBSourceListTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 12/3/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@import UIKit;

#import <Database/ZBDatabaseManager.h>
#import <Extensions/ZBRefreshableTableViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceListViewController : ZBRefreshableTableViewController <ZBSourceDelegate, UISearchResultsUpdating, UISearchControllerDelegate> {
    NSMutableArray <ZBSource *> *sources;
    NSArray <ZBSource *> *filteredSources;
}
@end

NS_ASSUME_NONNULL_END
