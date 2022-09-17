//
//  ZBHomeDemoNoticeCell.m
//  Zebra
//
//  Created by Adam Demasi on 17/9/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import "ZBHomeDemoNoticeCell.h"
#import "ZBLabelTextView.h"
#import "UIColor+GlobalColors.h"
#import "ZBDevice.h"

@implementation ZBHomeDemoNoticeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor cellBackgroundColor];

        UIFont *headlineFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];

        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont fontWithDescriptor:headlineFont.fontDescriptor size:headlineFont.pointSize * 1.2];
        label.textColor = [UIColor systemRedColor];
        label.numberOfLines = 0;
        label.text = NSLocalizedString(@"Demo Mode", @"");

        ZBLabelTextView *textView = [[ZBLabelTextView alloc] init];
        textView.translatesAutoresizingMaskIntoConstraints = NO;

        NSString *strong = [NSString stringWithFormat:NSLocalizedString(@"Zebra doesn’t have permission to install packages on this %@.", @""), [UIDevice currentDevice].localizedModel];
        NSString *line1 = NSLocalizedString(@"There may be an issue with the jailbreak. Try restarting your device. If that doesn’t work, use the “Restore” feature in your jailbreak tool.", @"");
        NSString *line2 = NSLocalizedString(@"Beware of fake jailbreaks. If you’re not sure whether the jailbreak you’re using is legitimate, visit <a href=\"https://www.reddit.com/r/jailbreak\">reddit.com/r/jailbreak</a> or <a href=\"https://ios.cfw.guide/\">ios.cfw.guide</a> for help.", @"");
        NSString *body = [NSString stringWithFormat:@"<strong>%@</strong> %@<br><br>%@", strong, line1, line2];
        textView.attributedText = [ZBLabelTextView attributedStringWithBody:body];

        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[label, textView]];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.spacing = 15;
        [self.contentView addSubview:stackView];

        [NSLayoutConstraint activateConstraints:@[
            [stackView.leadingAnchor constraintEqualToAnchor:self.contentView.readableContentGuide.leadingAnchor],
            [stackView.trailingAnchor constraintEqualToAnchor:self.contentView.readableContentGuide.trailingAnchor],
            [stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:15],
            [stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-15]
        ]];
    }

    return self;
}

@end
