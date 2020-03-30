//
//  ZBPackageDepictionViewController.h
//  Zebra
//
//  Created by Wilson Styres on 1/23/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <Packages/Controllers/ZBPackagesByAuthorTableViewController.h>
#import "ZBInstalledFilesTableViewController.h"
#import <Console/ZBConsoleCommandDelegate.h>

@import SafariServices;
@import MessageUI;

@class ZBPackage;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageDepictionViewController : UIViewController <WKNavigationDelegate, UIViewControllerPreviewing, SFSafariViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, ZBConsoleCommandDelegate>
@property (nonatomic, strong) ZBPackage *package;
@property (weak, nonatomic) IBOutlet UIImageView *packageIcon;
@property (weak, nonatomic) IBOutlet UILabel *packageName;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property BOOL purchased;
@property (nonatomic, weak) UIViewController *parent;
- (id)initWithPackageID:(NSString *)packageID fromRepo:(ZBSource *_Nullable)repo;
- (id)initWithPackage:(ZBPackage *)package;
- (NSArray *)contextMenuActionItemsForIndexPath:(NSIndexPath *)indexPath;
@end

NS_ASSUME_NONNULL_END
