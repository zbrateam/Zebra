//
//  ZBHomeTableViewController.h
//  Zebra
//
//  Created by midnightchips on 7/1/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIColor+GlobalColors.h"
#import "ZBDevice.h"
#import "ZBStoresListTableViewController.h"
#import "ZBSettingsTableViewController.h"
#import "ZBWishListTableViewController.h"
#import "ZBDatabaseManager.h"
#import "ZBSource.h"
#import "ZBNoScrollHeaderTableView.h"
#import "ZBFeaturedCollectionViewCell.h"
@import SDWebImage;

@class ZBFeaturedBanner;

@interface ZBHomeTableViewController : UITableViewController <UICollectionViewDelegate, UICollectionViewDataSource, UIAdaptivePresentationControllerDelegate, SFSafariViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UIBarButtonItem *darkModeButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *settingsButton;
@property (strong, nonatomic) IBOutlet UIView *footerView;
@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutlet UILabel *footerLabel;
@property (strong, nonatomic) IBOutlet UILabel *udidLabel;
@property (strong, nonatomic) IBOutlet UICollectionView *featuredCollection;
@property (nonatomic, strong) NSMutableArray <ZBFeaturedBanner *> *allFeatured;
@property (nonatomic, strong) NSMutableArray <ZBFeaturedBanner *> *selectedFeatured;
@property (nonatomic) NSInteger cellNumber;
@property (nonatomic, strong) NSUserDefaults *defaults;
@end
