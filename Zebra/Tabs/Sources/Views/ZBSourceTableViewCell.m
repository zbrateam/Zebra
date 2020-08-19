//
//  ZBSourceTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-05-02.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSourceTableViewCell.h"
#import <Extensions/UIColor+GlobalColors.h>
#import <Tabs/Sources/Helpers/ZBSource.h>
@import SDWebImage;

@interface ZBSourceTableViewCell () {
    UIActivityIndicatorView *spinner;
}
@end

@implementation ZBSourceTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor cellBackgroundColor];
    self.sourceLabel.textColor = [UIColor primaryTextColor];
    self.urlLabel.textColor = [UIColor secondaryTextColor];
    self.iconImageView.layer.cornerRadius = 10;
    self.iconImageView.layer.masksToBounds = YES;
    self.chevronView = (UIImageView *)(self.accessoryView);
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:12];
    spinner.color = [UIColor grayColor];
}

- (void)setSource:(ZBSource *)source {
    self.sourceLabel.text = source.label;
    self.urlLabel.text = source.repositoryURI;
    [self.iconImageView sd_setImageWithURL:source.iconURL placeholderImage:[UIImage imageNamed:@"Unknown"]];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    //FIXME: Fix pls
//    self.backgroundColor= [UIColor selectedCellBackgroundColor:highlighted];
}

- (void)clearAccessoryView {
    self.accessoryView = self.chevronView;
}

- (void)setSpinning:(BOOL)spinning {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (spinning) {
            self.accessoryView = self->spinner;
            [self->spinner startAnimating];
        } else {
            [self->spinner stopAnimating];
            self.accessoryView = self.chevronView;
        }
    });
}

- (void)setDisabled:(BOOL)disabled {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (disabled) {
//            self.selectionStyle = UITableViewCellSelectionStyleNone;
            self.alpha = 0.5;
        } else {
//            self.selectionStyle = UITableViewCellSelectionStyleDefault;
            self.alpha = 1.0;
        }
    });
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.iconImageView sd_cancelCurrentImageLoad];
}

@end
