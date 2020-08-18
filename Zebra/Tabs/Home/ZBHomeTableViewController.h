//
//  ZBHomeTableViewController.h
//  Zebra
//
//  Created by midnightchips on 7/1/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Extensions/UIColor+GlobalColors.h>
#import <ZBDevice.h>
#import "Stores/ZBStoresListTableViewController.h"
#import "Settings/ZBMainSettingsTableViewController.h"
#import "Wish List/ZBWishListTableViewController.h"
#import <Database/ZBDatabaseManager.h>
#import <Tabs/Sources/Helpers/ZBSource.h>
#import "Helpers/ZBNoScrollHeaderTableView.h"
#import "ZBFeaturedCollectionViewCell.h"
#import <Extensions/UIImage+UIKitImage.h>

@import SDWebImage;
@import SafariServices;
@import UIKit;

@interface ZBHomeTableViewController : UITableViewController <UICollectionViewDelegate, UICollectionViewDataSource, UIAdaptivePresentationControllerDelegate, SFSafariViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *darkModeButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;
@property (weak, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *footerLabel;
@property (weak, nonatomic) IBOutlet UILabel *udidLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *featuredCollection;
@property NSMutableArray *allFeatured;
@property NSMutableArray *selectedFeatured;
@property NSInteger cellNumber;
@property NSUserDefaults *defaults;
@end
