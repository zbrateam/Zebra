//
//  ZBPackageDepictionViewController.h
//  Zebra
//
//  Created by Wilson Styres on 1/23/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "ZBPackagesByAuthorTableViewController.h"
#import "ZBInstalledFilesTableViewController.h"
#import "ZBConsoleCommandDelegate.h"

@import SafariServices;

#import <MessageUI/MessageUI.h>

@class ZBPackage;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageDepictionViewController : UIViewController <WKNavigationDelegate, UIViewControllerPreviewing, SFSafariViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, ZBConsoleCommandDelegate>
@property (nonatomic, strong) ZBPackage *package;
@property (weak, nonatomic) IBOutlet UIImageView *packageIcon;
@property (weak, nonatomic) IBOutlet UILabel *packageName;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, weak) UITableViewController *parent;
- (id)initWithPackage:(ZBPackage *)package;
- (NSArray *)contextMenuActionItemsInTableView:(UITableView *_Nullable)tableview;
@end

NS_ASSUME_NONNULL_END
