//
//  ZBNewsCollectionViewCell.h
//  Zebra
//
//  Created by midnightchips on 7/8/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@import UIKit;

@interface ZBNewsCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UILabel *postTag;
@property (weak, nonatomic) IBOutlet UILabel *postTitle;
@property NSURL *redditLink;
@property NSString *redditID;
@property CAGradientLayer *gradient;
@end
