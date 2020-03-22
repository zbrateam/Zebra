//
//  ZBSourcesAccountBanner.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-03-21.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourcesAccountBanner.h"
#import "UIColor+GlobalColors.h"

@implementation ZBSourcesAccountBanner

@synthesize source;
@synthesize owner;

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (id)initWithSource:(ZBSource *)source andOwner:(ZBRepoSectionsListTableViewController *)owner {
    self = [[[NSBundle mainBundle] loadNibNamed: NSStringFromClass([self class]) owner:self options:nil] objectAtIndex:0];
    self.source = source;
    self.owner = owner;
    
//    self.descriptionLabel.text = source.label;
    [self.button addTarget:owner action:@selector(accountButtonPressed:) forControlEvents:UIControlEventTouchDown];
    
    [self applyStyle];
    return self;
}

- (void) applyStyle {
    self.backgroundColor = [[UIColor tableViewBackgroundColor] colorWithAlphaComponent:0.6];
    if (@available(iOS 10.0, *)) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = self.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self insertSubview:blurEffectView atIndex:0];
    }
    self.descriptionLabel.textColor = [UIColor primaryTextColor];
    self.button.tintColor = [UIColor accentColor];
    self.button.layer.cornerRadius = 14;
    self.seperatorView.backgroundColor = [UIColor cellSeparatorColor];
}

@end
