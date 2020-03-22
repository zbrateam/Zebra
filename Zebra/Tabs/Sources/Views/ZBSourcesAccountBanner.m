//
//  ZBSourcesAccountBanner.m
//  Zebra
//
//  Created by Andrew Abosh on 2020-03-21.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourcesAccountBanner.h"

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
    
    self.descriptionLabel.text = source.label;
    [self.button addTarget:owner action:@selector(accountButtonPressed:) forControlEvents:UIControlEventTouchDown];
    
    return self;
}

@end
