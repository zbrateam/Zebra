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
//#import <Tabs/Packages/Helpers/ZBPackage.h>
#import <Tabs/Packages/Helpers/ZBPackageActions.h>
#import <Queue/ZBQueue.h>
@import SDWebImage;

@implementation ZBPackageTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.isInstalledImageView.hidden = YES;
    self.isPaidImageView.hidden = YES;
    self.isOnWishlistImageView.hidden = YES;
    
    self.queueStatusLabel.hidden = YES;
    self.queueStatusLabel.layer.cornerRadius = 4.0;
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    self.iconImageView.layer.cornerRadius = 10;
    self.iconImageView.clipsToBounds = YES;
    [self setColors];
}

- (void)updateData:(ZBPackage *)package {
    [self updateData:package calculateSize:NO showVersion:NO];
}

- (void)updateData:(ZBPackage *)package calculateSize:(BOOL)calculateSize showVersion:(BOOL)showVersion {
    self.packageLabel.text = package.name;
    self.descriptionLabel.text = package.packageDescription;
    ZBSource *source = package.source;
    NSString *name = source.origin;
    NSString *author = package.authorName;
    NSString *installedSize = calculateSize ? [package installedSizeString] : nil;
    NSMutableArray *info = [NSMutableArray arrayWithCapacity:3];
    if (showVersion)
        [info addObject:[package version]];
    if (author.length)
        [info addObject:author];
    if (name.length)
        [info addObject:name];
    if (installedSize)
        [info addObject:installedSize];
    self.authorAndSourceAndSize.text = [info componentsJoinedByString:@" • "];
    
    [package setIconImageForImageView:self.iconImageView];
    
    self.isInstalledImageView.hidden = !package.isInstalled;
    self.isOnWishlistImageView.hidden = !package.isOnWishlist;
    self.isPaidImageView.hidden = !package.isPaid;
    
    [self updateQueueStatus:package];
}

- (void)updateQueueStatus:(ZBPackage *)package {
    ZBQueueType queue = [[ZBQueue sharedQueue] locate:package];
    if (queue != ZBQueueTypeClear) {
        NSString *status = [[ZBQueue sharedQueue] displayableNameForQueueType:queue];
        self.queueStatusLabel.hidden = NO;
        self.queueStatusLabel.text = [NSString stringWithFormat:@" %@ ", status];
        self.queueStatusLabel.backgroundColor = [ZBQueue colorForQueueType:queue];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.queueStatusLabel sizeToFit];
        });
    } else {
        self.queueStatusLabel.hidden = YES;
        self.queueStatusLabel.text = nil;
        self.queueStatusLabel.backgroundColor = nil;
    }
}

- (void)setColors {
    self.packageLabel.textColor = [UIColor primaryTextColor];
    self.descriptionLabel.textColor = [UIColor secondaryTextColor];
    self.authorAndSourceAndSize.textColor = [UIColor tertiaryTextColor];
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
