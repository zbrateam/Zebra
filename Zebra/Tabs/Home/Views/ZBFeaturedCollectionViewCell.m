//
//  ZBFeaturedCollectionViewCell.m
//  Zebra
//
//  Created by Wilson Styres on 8/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBFeaturedCollectionViewCell.h"
#import <Packages/Helpers/ZBPackage.h>
#import <Repos/Helpers/ZBRepo.h>
#import <Extensions/UIColor+GlobalColors.h>

@implementation ZBFeaturedCollectionViewCell

@synthesize repoNameLabel;
@synthesize tweakDescriptionLabel;
@synthesize tweakNameLabel;
@synthesize package;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    repoNameLabel.textColor = [UIColor tintColor];
    tweakDescriptionLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
}

- (void)updatePackage:(ZBPackage *)newPackage {
    package = newPackage;
    
    repoNameLabel.text = [[package repo] origin];
    tweakNameLabel.text = [package name];
    tweakDescriptionLabel.text = [package shortDescription];
}

@end
