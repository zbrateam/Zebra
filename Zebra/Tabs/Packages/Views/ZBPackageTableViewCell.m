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
#import "ZBRepo.h"
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
    self.packageLabel.text = package.name;
    self.descriptionLabel.text = package.shortDescription;
    ZBRepo *repo = package.repo;
    NSString *repoName = repo.origin;
    if (package.author) {
        self.authorAndRepo.text = [NSString stringWithFormat:@"%@ • %@", [self stripEmailFromAuthor:package.author], repoName];
    } else {
        self.authorAndRepo.text = repoName;
    }
    UIImage *sectionImage = [UIImage imageNamed:package.sectionImageName];
    if (sectionImage == NULL) {
        sectionImage = [UIImage imageNamed:@"Other"];
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
    ZBQueueType queue = [[ZBQueue sharedInstance] queueStatusForPackage:package];
    if (queue) {
        NSString *status = [[ZBQueue sharedInstance] queueToKey:queue];
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
    self.packageLabel.textColor = [UIColor cellPrimaryTextColor];
    self.descriptionLabel.textColor = [UIColor cellSecondaryTextColor];
    self.authorAndRepo.textColor = [UIColor cellSecondaryTextColor];
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
    self.backgroundColor = [UIColor selectedCellBackgroundColor:highlighted];
}

@end
