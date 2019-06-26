//
//  ZBPackageInfo.h
//  Zebra
//
//  Created by midnightchips on 6/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Packages/Helpers/ZBPackage.h>
#import "ZBDevice.h"
@import MessageUI;

@interface ZBPackageInfoView : UIView <UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *packageIcon;
@property (weak, nonatomic) IBOutlet UILabel *packageName;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property UIViewController *parentVC;
@property ZBPackage *depictionPackage;
@property NSString *authorEmail;
+ (CGFloat)rowHeight;
- (NSUInteger)rowCount;
- (void)setPackage:(ZBPackage *)package;
@end
