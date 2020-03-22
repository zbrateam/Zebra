//
//  ZBSourcesAccountBanner.h
//  Zebra
//
//  Created by Andrew Abosh on 2020-03-21.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ZBSource.h>
#import "ZBRepoSectionsListTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourcesAccountBanner : UIView
@property (nonatomic, strong) ZBSource *source;
@property (nonatomic, assign) ZBRepoSectionsListTableViewController* owner;
- (id)initWithSource:(ZBSource *)source andOwner:(ZBRepoSectionsListTableViewController *)owner;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *seperatorView;
@end

NS_ASSUME_NONNULL_END
