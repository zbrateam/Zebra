//
//  ZBPackageTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-05-01.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageTableViewCell.h"
#import <UIColor+GlobalColors.h>
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageActions.h>
#import "ZBSource.h"
#import <Queue/ZBQueue.h>
@import SDWebImage;

@implementation ZBPackageTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor cellBackgroundColor];
    self.isInstalledImageView.hidden = YES;
    self.isPaidImageView.hidden = YES;
    self.queueStatusLabel.hidden = YES;
    self.queueStatusLabel.textColor = [UIColor whiteColor];
    self.queueStatusLabel.layer.cornerRadius = 4.0;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.iconImageView.layer.cornerRadius = 10;
    self.iconImageView.clipsToBounds = YES;
    self.isInstalledImageView.tintColor = [UIColor accentColor];
}

- (void)updateData:(ZBPackage *)package {
    [self updateData:package calculateSize:NO];
}

- (void)updateData:(ZBPackage *)package calculateSize:(BOOL)calculateSize {
    self.packageLabel.text = package.name;
    self.descriptionLabel.text = package.shortDescription;
    ZBSource *repo = package.source;
    NSString *repoName = repo.origin;
    NSString *author = package.authorName;
    NSString *installedSize = calculateSize ? [package installedSizeString] : nil;
    NSMutableArray *info = [NSMutableArray arrayWithCapacity:3];
    if (author.length)
        [info addObject:author];
    if (repoName.length)
        [info addObject:repoName];
    if (installedSize)
        [info addObject:installedSize];
    self.authorAndRepoAndSize.text = [info componentsJoinedByString:@" • "];
    
    [package setIconImageForImageView:self.iconImageView];
    
    BOOL installed = [package isInstalled:NO];
    BOOL paid = [package isPaid];
    
    self.isInstalledImageView.hidden = !installed;
    self.isPaidImageView.hidden = !paid;
    
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
    self.authorAndRepoAndSize.textColor = [UIColor secondaryTextColor];
    self.backgroundColor = [UIColor cellBackgroundColor];
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
