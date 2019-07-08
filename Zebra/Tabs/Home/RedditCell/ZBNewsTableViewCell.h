//
//  ZBNewsTableViewCell.h
//  Zebra
//
//  Created by midnightchips on 7/8/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
@import SafariServices;

@interface ZBNewsTableViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SFSafariViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property NSMutableArray *redditPosts;
@property UIViewController *parentVC;
- (void)setupCollectionView:(NSArray *)dict;
@end
