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
#import <Packages/Helpers/ZBPackageActionsManager.h>
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
    self.iconImageView.layer.shadowRadius = 3;
    self.iconImageView.clipsToBounds = YES;
}

- (void)updateData:(ZBPackage *)package {
    [self updateData:package calculateSize:NO];
}

- (void)updateData:(ZBPackage *)package calculateSize:(BOOL)calculateSize {
    self.packageLabel.text = package.name;
    self.descriptionLabel.text = package.shortDescription;
    ZBSource *repo = package.repo;
    NSString *repoName = repo.origin;
    NSString *author = [self stripEmailFromAuthor:package.author];
    NSString *installedSize = calculateSize ? [package installedSizeString] : nil;
    NSMutableArray *info = [NSMutableArray arrayWithCapacity:3];
    if (author.length)
        [info addObject:author];
    if (repoName.length)
        [info addObject:repoName];
    if (installedSize)
        [info addObject:installedSize];
    self.authorAndRepoAndSize.text = [info componentsJoinedByString:@" • "];
    UIImage *sectionImage = [UIImage imageNamed:package.sectionImageName];
    if (sectionImage == NULL) {
        sectionImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Applications/Zebra.app/Sections/%@.png", package.sectionImageName]];
        if (sectionImage == NULL) { //Just in case
            sectionImage = [UIImage imageNamed:@"Other"];
        }
    }
    
    if (package.iconPath) {
        // [self.iconImageView setImageFromURL:[NSURL URLWithString:package.iconPath] placeHolderImage:sectionImage];
        // [self.iconImageView loadImageFromURL:[NSURL URLWithString:package.iconPath] placeholderImage:sectionImage cachingKey:package.name];
        [self.iconImageView sd_setImageWithURL:[NSURL URLWithString:package.iconPath] placeholderImage:sectionImage];
    } else {
        self.iconImageView.image = sectionImage;
    }
    
    BOOL installed = [package isInstalled:NO];
    BOOL paid = [package isPaid];
    
    self.isInstalledImageView.hidden = !installed;
    self.isPaidImageView.hidden = !paid;
    
    if (!self.isInstalledImageView.hidden) {
        self.isInstalledImageView.image = [UIImage imageNamed:@"Installed"];
    }
    if (!self.isPaidImageView.hidden) {
        if (!installed) {
            self.isInstalledImageView.image = self.isPaidImageView.image;
            self.isInstalledImageView.hidden = NO;
            self.isPaidImageView.hidden = YES;
        } else {
            self.isPaidImageView.image = [UIImage imageNamed:@"Paid"];
        }
    }
    
    [self updateQueueStatus:package];
}

- (void)updateQueueStatus:(ZBPackage *)package {
    ZBQueueType queue = [[ZBQueue sharedQueue] locate:package];
    if (queue != ZBQueueTypeClear) {
        NSString *status = [[ZBQueue sharedQueue] displayableNameForQueueType:queue useIcon:NO];
        self.queueStatusLabel.hidden = NO;
        self.queueStatusLabel.text = [NSString stringWithFormat:@" %@ ", status];
        self.queueStatusLabel.backgroundColor = [ZBPackageActionsManager colorForAction:queue];
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

- (NSString *)stripEmailFromAuthor:(NSString *)name {
    NSArray *authorName = [name componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSMutableArray *cleanedStrings = [NSMutableArray new];
    for (NSString *cut in authorName) {
        if (![cut hasPrefix:@"<"] && ![cut hasSuffix:@">"]) {
            [cleanedStrings addObject:cut];
        }
    }
    return [cleanedStrings componentsJoinedByString:@" "];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    //FIXME: Fix!
//    self.backgroundColor = [UIColor selectedCellBackgroundColor:highlighted];
}

@end
