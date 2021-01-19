//
//  ZBPackageTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-05-01.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageTableViewCell.h"

#import <Model/ZBPackage.h>
#import <Model/ZBSource.h>

#import <Extensions/UIColor+GlobalColors.h>
#import <Tabs/Packages/Helpers/ZBPackageActions.h>
#import <Queue/ZBQueue.h>
@import SDWebImage;

@implementation ZBPackageTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.isInstalledImageView.hidden = YES;
    self.isPaidImageView.hidden = YES;
    self.isFavoritedImageView.hidden = YES;
    
    self.queueStatusBackgroundView.hidden = YES;
    self.queueStatusBackgroundView.layer.cornerRadius = 5.0;
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    self.iconImageView.layer.cornerRadius = self.iconImageView.frame.size.height * 0.2237;
    self.iconImageView.layer.borderWidth = 1;
    self.iconImageView.layer.borderColor = [[UIColor imageBorderColor] CGColor];
    self.iconImageView.layer.masksToBounds = YES;
    [self setColors];
}

- (void)updateData:(ZBPackage *)package {
    self.packageLabel.text = package.name;
    self.descriptionLabel.text = package.packageDescription;

    NSMutableArray *info = [NSMutableArray arrayWithCapacity:3];
    if (self.showVersion)
        [info addObject:[package version]];
    if (package.authorName)
        [info addObject:package.authorName];
//    if (name.length)
//        [info addObject:name];
    if (self.showSize)
        [info addObject:package.installedSizeString];
    
    self.infoLabel.text = [info componentsJoinedByString:@" • "];
    
    [package setIconImageForImageView:self.iconImageView];
    
    self.isInstalledImageView.hidden = !package.isInstalled;
    self.isFavoritedImageView.hidden = !package.isFavorited;
    self.isPaidImageView.hidden = !package.isPaid;
    
    [self updateQueueStatus:package];
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

- (void)setColors {
    self.packageLabel.textColor = [UIColor primaryTextColor];
    self.descriptionLabel.textColor = [UIColor secondaryTextColor];
    self.infoLabel.textColor = [UIColor tertiaryTextColor];
    self.isInstalledImageView.tintColor = [UIColor accentColor];
    self.queueStatusLabel.textColor = [UIColor whiteColor];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    //FIXME: Fix!
//    self.backgroundColor = [UIColor selectedCellBackgroundColor:highlighted];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.isInstalledImageView.hidden = YES;
    self.isPaidImageView.hidden = YES;
}

@end
