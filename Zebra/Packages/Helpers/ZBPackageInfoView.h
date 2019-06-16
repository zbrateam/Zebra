//
//  ZBPackageInfo.h
//  Zebra
//
//  Created by midnightchips on 6/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Packages/Helpers/ZBPackage.h>

@interface ZBPackageInfoView : UIView <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIImageView *packageIcon;
@property (weak, nonatomic) IBOutlet UILabel *packageName;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property UIViewController *parentVC;
+ (CGFloat)rowHeight;
- (NSUInteger)rowCount;
- (void)setPackage:(ZBPackage *)package;
@end
