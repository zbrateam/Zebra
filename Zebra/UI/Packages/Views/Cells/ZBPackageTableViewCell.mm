//
//  ZBPackageTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-05-01.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageTableViewCell.h"

#import <Plains/Plains.h>

#import <Extensions/UIColor+GlobalColors.h>
#import <Tabs/Packages/Helpers/ZBPackageActions.h>
#import <Queue/ZBQueue.h>
#import <SDWebImage/SDWebImage.h>

@interface ZBPackageTableViewCell ()
@property (weak, nonatomic) IBOutlet UIView *backgroundContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *packageLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *isFavoritedImageView;
@property (weak, nonatomic) IBOutlet UIImageView *isPaidImageView;
@property (weak, nonatomic) IBOutlet UIImageView *isInstalledImageView;
@property (weak, nonatomic) IBOutlet UIView *queueStatusBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *queueStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@end

@implementation ZBPackageTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.isInstalledImageView.hidden = YES;
    self.isInstalledImageView.tintColor = [UIColor accentColor];
    
    self.isPaidImageView.hidden = YES;
    self.isFavoritedImageView.hidden = YES;
    
    self.queueStatusBackgroundView.hidden = YES;
    self.queueStatusBackgroundView.layer.cornerRadius = 5.0;
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    self.iconImageView.layer.cornerRadius = self.iconImageView.frame.size.height * 0.2237;
    self.iconImageView.layer.borderWidth = 1;
    self.iconImageView.layer.borderColor = [[UIColor imageBorderColor] CGColor];
    self.iconImageView.layer.masksToBounds = YES;
    
    self.packageLabel.textColor = [UIColor primaryTextColor];
    self.descriptionLabel.textColor = [UIColor secondaryTextColor];
    self.infoLabel.textColor = [UIColor tertiaryTextColor];
}

- (void)setPackage:(PLPackage *)package {
    self.packageLabel.text = package.name;
    self.descriptionLabel.text = package.shortDescription;
    
    NSMutableArray *info = [NSMutableArray arrayWithCapacity:3];
    if (self.showVersion)
        [info addObject:[package version]];
    if (package.authorName)
        [info addObject:package.authorName];
    if (self.showSize)
        [info addObject:package.installedSizeString];
    if (package.source.origin)
        [info addObject:package.source.origin];
    
    self.infoLabel.text = [info componentsJoinedByString:@" • "];
    
    self.isInstalledImageView.hidden = !package.installed;
    self.isFavoritedImageView.hidden = YES;
    self.isPaidImageView.hidden = !package.paid;
    
    UIImage *sectionImage = [PLSource imageForSection:package.section];
    if (package.iconURL) {
        [self.iconImageView sd_setImageWithURL:package.iconURL placeholderImage:sectionImage];
    }
    else {
        [self.iconImageView setImage:sectionImage];
    }
}

- (void)updateQueueStatus:(ZBPackage *)package {
    ZBQueueType queue = [[ZBQueue sharedQueue] locate:package];
    if (queue != ZBQueueTypeClear) {
        NSString *status = [[ZBQueue sharedQueue] displayableNameForQueueType:queue];
        self.queueStatusBackgroundView.hidden = NO;
        self.queueStatusLabel.text = [NSString stringWithFormat:@"%@", status];
        self.queueStatusBackgroundView.backgroundColor = [ZBQueue colorForQueueType:queue];
    } else {
        self.queueStatusBackgroundView.hidden = YES;
        self.queueStatusLabel.text = nil;
        self.queueStatusBackgroundView.backgroundColor = nil;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.isInstalledImageView.hidden = YES;
    self.isPaidImageView.hidden = YES;
}

@end
