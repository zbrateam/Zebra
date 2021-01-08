//
//  ZBCommunityNewsTableView.h
//  Zebra
//
//  Created by Wilson Styres on 1/7/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBCommunityNewsTableView : UITableView <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) NSArray *posts;
- (void)fetch;
@end

NS_ASSUME_NONNULL_END
