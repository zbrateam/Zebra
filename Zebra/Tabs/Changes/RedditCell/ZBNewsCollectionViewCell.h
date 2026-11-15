//
//  ZBNewsCollectionViewCell.h
//  Zebra
//
//  Created by midnightchips on 7/8/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZBNewsCollectionViewCell : UICollectionViewCell
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (strong, nonatomic) IBOutlet UILabel *postTag;
@property (strong, nonatomic) IBOutlet UILabel *postTitle;
@property (nonatomic, strong) NSURL *redditLink;
@property (nonatomic, strong) NSString *redditID;
@property (nonatomic, strong) CAGradientLayer *gradient;
@end
