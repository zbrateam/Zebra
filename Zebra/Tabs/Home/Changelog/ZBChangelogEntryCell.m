//
//  ZBChangelogEntryCell.m
//  Zebra
//
//  Created by Adam Demasi on 12/1/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import "ZBChangelogEntryCell.h"

@implementation ZBChangelogEntryCell {
    UITextView *_textView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _textView = [[UITextView alloc] init];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.textContainerInset = UIEdgeInsetsMake(15, 15, 0, 15);
        _textView.scrollEnabled = NO;
        _textView.editable = NO;
        [self.contentView addSubview:_textView];

        [NSLayoutConstraint activateConstraints:@[
            [_textView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_textView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_textView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [_textView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
        ]];
    }
    return self;
}

- (NSAttributedString *)attributedString {
    return _textView.attributedText;
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
    _textView.attributedText = attributedString;
}

@end
