//
//  ZBPackageTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-05-01.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageTableViewCell.h"

#import "PLPackage+Zebra.h"
#import <Plains/Plains.h>
#import "Zebra-Swift.h"
#import "ZBPackageActions.h"

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
@property (weak, nonatomic) IBOutlet UIStackView *infoStackView;
@property (weak, nonatomic) IBOutlet UIStackView *badgeStackView;
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
    
    self.packageLabel.textColor = [UIColor labelColor];
    self.descriptionLabel.textColor = [UIColor secondaryLabelColor];
    self.infoLabel.textColor = [UIColor tertiaryLabelColor];
}

- (void)setPackage:(PLPackage *)package {
    self.packageLabel.text = package.name;
    self.descriptionLabel.text = package.shortDescription;
    
    NSMutableArray *info = [NSMutableArray arrayWithCapacity:3];
    if (self.showVersion)
        [info addObject:package.version];
    if (self.showAuthor && package.author.name)
        [info addObject:package.author.name];
    if (self.showSize)
        [info addObject:package.installedSizeString];
    if (self.showSource && package.source.origin)
        [info addObject:package.source.origin];
    
    self.infoLabel.text = [info componentsJoinedByString:@" • "];
    
    self.isInstalledImageView.hidden = !package.isInstalled;
    self.isFavoritedImageView.hidden = YES;
    self.isPaidImageView.hidden = !package.isPaid;
    
    [package setPackageIconForImageView:self.iconImageView];
}

- (void)updateQueueStatus:(ZBPackage *)package {
    //TODO: Update for new queue
//    ZBQueueType queue = [[ZBQueue sharedQueue] locate:package];
//    if (queue != ZBQueueTypeClear) {
//        NSString *status = [[ZBQueue sharedQueue] displayableNameForQueueType:queue];
//        self.queueStatusBackgroundView.hidden = NO;
//        self.queueStatusLabel.text = [NSString stringWithFormat:@"%@", status];
//        self.queueStatusBackgroundView.backgroundColor = [ZBQueue colorForQueueType:queue];
//    } else {
//        self.queueStatusBackgroundView.hidden = YES;
//        self.queueStatusLabel.text = nil;
//        self.queueStatusBackgroundView.backgroundColor = nil;
//    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.isInstalledImageView.hidden = YES;
    self.isPaidImageView.hidden = YES;
    self.isFavoritedImageView.hidden = YES;
    
    [self popExtraInfo];
}

- (void)popExtraInfo {
    for (UIView *view in self.infoStackView.arrangedSubviews) {
        if (view == self.infoLabel || view == self.descriptionLabel) continue;
        [view removeFromSuperview];
    }
}

- (void)setShowBadges:(BOOL)showBadges {
    _showBadges = showBadges;
    self.badgeStackView.hidden = !_showBadges;
}

- (void)addInfoText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.font = self.infoLabel.font;
    label.textColor = self.infoLabel.textColor;
    label.text = text;
    
    [self.infoStackView addArrangedSubview:label];
}

- (void)addInfoAttributedText:(NSAttributedString *)attributedText {
    UILabel *label = [[UILabel alloc] init];
    label.font = self.infoLabel.font;
    label.textColor = self.infoLabel.textColor;
    label.attributedText = attributedText;
    
    [self.infoStackView addArrangedSubview:label];
}

@end
