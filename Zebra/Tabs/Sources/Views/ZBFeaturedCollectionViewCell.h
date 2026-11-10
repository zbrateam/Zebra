//
//  ZBFeaturedCollectionViewCell.h
//  Zebra
//
//  Created by midnightchips on 5/25/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZBFeaturedCollectionViewCell : UICollectionViewCell
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) NSString *packageID;
@end
