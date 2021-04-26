//
//  ZBSourceTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-05-02.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSourceTableViewCell.h"
#import <Extensions/ZBColor.h>
#import <Model/ZBSourceFilter.h>

#import <Plains/Model/PLSource.h>

#import <SDWebImage/SDWebImage.h>

@interface ZBSourceTableViewCell () {
    UIActivityIndicatorView *spinner;
}
@end

@implementation ZBSourceTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.sourceLabel.textColor = [ZBColor primaryTextColor];
    self.urlLabel.textColor = [ZBColor secondaryTextColor];
    self.installedPackagesLabel.textColor = [ZBColor secondaryTextColor];
    self.tintColor = [ZBColor accentColor];
    
    self.iconImageView.layer.cornerRadius = self.iconImageView.frame.size.height * 0.2237;
    self.iconImageView.layer.borderWidth = 1;
    self.iconImageView.layer.borderColor = [[ZBColor imageBorderColor] CGColor];
    self.iconImageView.layer.masksToBounds = YES;
    self.storeBadge.hidden = YES;
    self.installedPackagesLabel.hidden = YES;
    
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:12];
    spinner.color = [UIColor grayColor];
}

- (void)setSource:(PLSource *)source {
    self.sourceLabel.text = source.label;
    self.urlLabel.text = source.URI.absoluteString;
//    self.storeBadge.hidden = source.paymentEndpointURL == NULL;

//    if ([ZBSettings wantsInstalledPackagesCount] || filter.sortOrder == ZBSourceSortOrderInstalledPackages) {
//        NSUInteger numberOfInstalledPackages = [source numberOfInstalledPackages];
//        if (numberOfInstalledPackages > 0) {
//            self.installedPackagesLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lu Installed", @""), numberOfInstalledPackages];
//            self.installedPackagesLabel.hidden = NO;
//        } else {
//            self.installedPackagesLabel.hidden = YES;
//        }
//    } else {
//        self.installedPackagesLabel.hidden = YES;
//    }

    [self.iconImageView sd_setImageWithURL:source.iconURL placeholderImage:[UIImage imageNamed:@"Unknown"]];

//    if (source.errors.count) {
//        self.accessoryType = [source isKindOfClass:[ZBSource class]] ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryDetailButton;
//        self.tintColor = [UIColor systemPinkColor];
//    } else if (source.warnings.count) {
//        self.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
//        self.tintColor = [UIColor systemYellowColor];
//    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    //FIXME: Fix pls
//    self.backgroundColor= [UIColor selectedCellBackgroundColor:highlighted];
}

- (void)setSpinning:(BOOL)spinning {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (spinning) {
            self.accessoryView = self->spinner;
            [self->spinner startAnimating];
        } else {
            [self->spinner stopAnimating];
            self.accessoryView = nil;
        }
    });
}

- (void)setDisabled:(BOOL)disabled {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (disabled) {
            self.selectionStyle = UITableViewCellSelectionStyleNone;
            self.alpha = 0.5;
        } else {
            self.selectionStyle = UITableViewCellSelectionStyleDefault;
            self.alpha = 1.0;
        }
    });
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.iconImageView sd_cancelCurrentImageLoad];
    self.tintColor = [ZBColor accentColor];
    self.accessoryType = UITableViewCellAccessoryNone;
    [self setDisabled:NO];
}

@end
