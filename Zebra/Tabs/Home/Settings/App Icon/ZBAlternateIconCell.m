//
//  ZBAlternateIconCell.m
//  Zebra
//
//  Created by Adam Demasi on 11/1/2022.
//  Copyright © 2022 Wilson Styres. All rights reserved.
//

#import "ZBAlternateIconCell.h"

#import "UIImageView+Zebra.h"

@implementation ZBAlternateIconCell {
    UIStackView *_stackView;

    NSDictionary <NSString *, id> *_iconSet;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _stackView = [[UIStackView alloc] init];
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.spacing = 20;
        [self.contentView addSubview:_stackView];

        [NSLayoutConstraint activateConstraints:@[
            [_stackView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [_stackView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor constant:15],
            [_stackView.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:-15],
            [_stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:15],
            [_stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-15],
        ]];
    }
    return self;
}

- (NSDictionary <NSString *, id> *)iconSet {
    return _iconSet;
}

- (void)setIconSet:(NSDictionary <NSString *, id> *)iconSet {
    _iconSet = iconSet;

    for (UIView *view in _stackView.arrangedSubviews) {
        [_stackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    NSString *selectedIconName;
    if (@available(iOS 10.3, *)) {
        selectedIconName = [UIApplication sharedApplication].alternateIconName;
    }

    NSInteger i = 0;
    for (NSDictionary <NSString *, id> *item in iconSet[@"icons"]) {
        // Nil selected icon means the default icon is currently active.
        BOOL isSelected = [item[@"iconName"] isEqualToString:selectedIconName ?: @"AppIcon"];
        BOOL border = [item[@"border"] boolValue];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_15_0
        NSString *iconName = item[@"iconName"];
        if ([iconName isEqualToString:@"AppIcon"]) {
            iconName = @"AppIcon60x60";
        }
#else
        NSString *iconName = [item[@"iconName"] stringByAppendingString:@"60x60"];
#endif
        UIImage *image = [[UIImage imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.adjustsImageWhenHighlighted = NO;
        button.accessibilityLabel = [NSString stringWithFormat:@"%@ %@", iconSet[@"name"], item[@"name"]];
        button.accessibilityTraits = isSelected ? UIAccessibilityTraitSelected : kNilOptions;
        button.userInteractionEnabled = !isSelected;
        button.tag = i;
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(iconTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button.imageView resize:CGSizeMake(60, 60) applyRadius:YES];
        if (border) {
            [button.imageView applyBorder];
        }
        if (isSelected) {
            UIImageView *tickImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"selection-tick"]];
            tickImageView.translatesAutoresizingMaskIntoConstraints = NO;
            tickImageView.backgroundColor = [UIColor whiteColor];
            tickImageView.layer.cornerRadius = tickImageView.image.size.width / 2.0;
            tickImageView.clipsToBounds = YES;
            [button addSubview:tickImageView];

            [NSLayoutConstraint activateConstraints:@[
                [tickImageView.trailingAnchor constraintEqualToAnchor:button.imageView.trailingAnchor constant:4],
                [tickImageView.bottomAnchor constraintEqualToAnchor:button.imageView.bottomAnchor constant:3],
            ]];
        }
        [_stackView addSubview:button];
        [_stackView addArrangedSubview:button];
        i++;
    }
}

- (void)iconTapped:(UIButton *)sender {
    [_delegate setAlternateIconFromSet:_iconSet atIndex:sender.tag];
}

@end
