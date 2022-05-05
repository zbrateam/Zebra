//
//  ZBLabelTextView.m
//  Zebra
//
//  Created by Adam Demasi on 7/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import "ZBLabelTextView.h"

@interface ZBLabelTextView () <UITextViewDelegate>

@end

@implementation ZBLabelTextView

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        self.delegate = self;
        self.editable = NO;
        self.scrollEnabled = NO;
        self.backgroundColor = nil;
        self.textDragInteraction.enabled = NO;
        self.textContainerInset = UIEdgeInsetsZero;
        self.textContainer.lineFragmentPadding = 0;
        if (@available(iOS 10, *)) {
            self.adjustsFontForContentSizeCategory = YES;
        }
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // 🧡 to https://stackoverflow.com/a/44878203/709376 for this
    if (![super pointInside:point withEvent:event]) {
        return NO;
    }
    UITextPosition *position = [self closestPositionToPoint:point];
    UITextRange *range = [self.tokenizer rangeEnclosingPosition:position
                                           withGranularity:UITextGranularityCharacter
                                               inDirection:UITextLayoutDirectionLeft];
    if (range == nil) {
        return NO;
    }
    NSInteger index = [self offsetFromPosition:self.beginningOfDocument toPosition:range.start];
    return [self.attributedText attribute:NSLinkAttributeName atIndex:index effectiveRange:nil] != nil;
}

- (BOOL)_handleURL:(NSURL *)url {
    if ([url.scheme isEqualToString:@"zbra"] && _linkHandler != nil) {
        _linkHandler(url);
        return NO;
    }
    return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    // Disallow selection by resetting selected range to nothing
    self.selectedRange = NSMakeRange(0, 0);
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)url inRange:(NSRange)characterRange {
    return [self _handleURL:url];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)url inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction API_AVAILABLE(ios(10.0)) {
    switch (interaction) {
    case UITextItemInteractionInvokeDefaultAction:
        return [self _handleURL:url];
    default:
        return NO;
    }
}

@end
