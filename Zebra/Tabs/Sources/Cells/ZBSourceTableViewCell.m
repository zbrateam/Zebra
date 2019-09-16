//
//  ZBSourceTableViewCell.m
//  Zebra
//
//  Created by Andrew Abosh on 2019-09-09.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@import SDWebImage;

#import "ZBSourceTableViewCell.h"

#import <Tabs/Sources/Helpers/ZBSource.h>

@implementation ZBSourceTableViewCell {
    UIActivityIndicatorView *spinner;
}

@synthesize sourceNameLabel;
@synthesize sourceURLLabel;
@synthesize iconImageView;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.iconImageView.layer.cornerRadius = 6;
    self.iconImageView.layer.masksToBounds = true;
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:12];
    [spinner setColor:[UIColor grayColor]];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
//    self.backgroundColor= [UIColor selectedCellBackgroundColor:highlighted];
}

- (BOOL)setSpinning:(BOOL)spinning {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (spinning) {
            self.accessoryView = self->spinner;
            [self->spinner startAnimating];
        } else {
            [self->spinner stopAnimating];
            self.accessoryView = nil;
        }
    });
    
    return spinning;
}

- (void)updateData:(ZBSource *)source {
    [sourceNameLabel setText:[source origin]];
    [sourceURLLabel setText:[source displayableURL]];
    [iconImageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
}

@end
