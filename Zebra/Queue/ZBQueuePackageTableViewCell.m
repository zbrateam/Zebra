//
//  ZBQueuePackageTableViewCell.m
//  Zebra
//
//  Created by Amy While on 01/06/2023.
//  Copyright © 2023 Zebra Team. All rights reserved.
//

#import "ZBQueuePackageTableViewCell.h"

@implementation ZBQueuePackageTableViewCell {
    UIImageView *imageView;
    UILabel *titleLabel;
    UILabel *versionLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self->imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self->imageView.translatesAutoresizingMaskIntoConstraints = false;
        self->imageView.contentMode = UIViewContentModeScaleAspectFit;
        self->imageView.layer.cornerRadius = 10;
        self->imageView.clipsToBounds = YES;
        
        self->titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self->titleLabel.translatesAutoresizingMaskIntoConstraints = false;
        self->titleLabel.font = [UIFont systemFontOfSize:17];
        
        self->versionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self->versionLabel.translatesAutoresizingMaskIntoConstraints = false;
        self->versionLabel.font = [UIFont systemFontOfSize:12];
    
        [self.contentView addSubview:self->imageView];
        [self.contentView addSubview:self->titleLabel];
        [self.contentView addSubview:self->versionLabel];

        self.backgroundColor = [UIColor cellBackgroundColor];
        
        [NSLayoutConstraint activateConstraints:@[
            [self->imageView.heightAnchor constraintEqualToConstant:35.0],
            [self->imageView.widthAnchor constraintEqualToConstant:35.0],
            [self->imageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10.25],
            [self->imageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10.25],
            [self->imageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:15],
            
            [self->titleLabel.heightAnchor constraintEqualToConstant:20.5],
            [self->titleLabel.leadingAnchor constraintEqualToAnchor:self->imageView.trailingAnchor constant:7.5],
            [self->titleLabel.topAnchor constraintEqualToAnchor:self->imageView.topAnchor],
            [self->titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant: -15],
                    
            [self->versionLabel.heightAnchor constraintEqualToConstant:14.5],
            [self->versionLabel.leadingAnchor constraintEqualToAnchor:self->titleLabel.leadingAnchor],
            [self->versionLabel.bottomAnchor constraintEqualToAnchor:self->imageView.bottomAnchor],
            [self->versionLabel.trailingAnchor constraintEqualToAnchor:self->titleLabel.trailingAnchor]
        ]];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setPackage:(ZBPackage *)package onQueue:(ZBQueue *)queue {
    if ([package dependencyOf].count > 0 || [package hasIssues] || [package removedBy] != nil || ([package isEssentialOrRequired] && [queue contains:package inQueue:ZBQueueTypeRemove]))  {
        self.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    else {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    
    [package setIconImageForImageView:self->imageView];
    
    self->titleLabel.text = package.name;
    self->versionLabel.text = [NSString stringWithFormat:@"%@ (%@)", package.identifier, package.version];
    
    if ([package hasIssues]) {
        self.tintColor = [UIColor systemPinkColor];
        self->titleLabel.textColor = [UIColor systemPinkColor];
        self->versionLabel.textColor = [UIColor systemPinkColor];
    }
    else if ([package isEssentialOrRequired] && [queue contains:package inQueue:ZBQueueTypeRemove]) {
        self.tintColor = [UIColor systemOrangeColor];
        self->titleLabel.textColor = [UIColor systemOrangeColor];
        self->versionLabel.textColor = [UIColor systemOrangeColor];
    }
    else {
        self.tintColor = [UIColor accentColor];
        self->titleLabel.textColor = [UIColor primaryTextColor];
        self->versionLabel.textColor = [UIColor secondaryTextColor];
    }
}

@end
