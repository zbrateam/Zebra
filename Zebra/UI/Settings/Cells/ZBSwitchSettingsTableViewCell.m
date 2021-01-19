//
//  ZBSwitchSettingsTableViewCell.m
//  Zebra
//
//  Created by absidue on 20-06-14.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSwitchSettingsTableViewCell.h"
#import <Extensions/UIColor+GlobalColors.h>
#import <ZBDevice.h>

@interface ZBSwitchSettingsTableViewCell () {
    UISwitch *theSwitch;
    id target;
    SEL action;
}

@end

@implementation ZBSwitchSettingsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self->theSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        self.accessoryView = self->theSwitch;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setTarget:(id)target action:(SEL)action {
    self->target = target;
    self->action = action;
    [theSwitch removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
    [theSwitch addTarget:self action:@selector(toggleHandler:) forControlEvents:UIControlEventValueChanged];
}

- (void)setOn:(BOOL)on {
    [theSwitch setOn:on animated:NO];
}

- (void)toggle {
    [theSwitch setOn:!theSwitch.on animated:YES];
    [ZBDevice hapticButton];
    [self toggleHandler:theSwitch];
}

- (BOOL)isOn {
    return theSwitch.on;
}

- (void)applyStyling {
    [super applyStyling];
    [theSwitch setOnTintColor:[UIColor accentColor]];
}

- (void)toggleHandler:(UISwitch *)sender {
    if (target && action && [target respondsToSelector:action]) {
        [self->target performSelector:self->action withObject:[NSNumber numberWithBool:sender.on]];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [theSwitch removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
    theSwitch.on = NO;
    target = nil;
    action = nil;
}
@end
