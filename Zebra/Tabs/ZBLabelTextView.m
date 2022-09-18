//
//  ZBLabelTextView.m
//  Zebra
//
//  Created by Adam Demasi on 7/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import "ZBLabelTextView.h"
#import "ZBDevice.h"
#import "UIColor+GlobalColors.h"

@interface ZBLabelTextView () <UITextViewDelegate>

@end

@implementation ZBLabelTextView

+ (NSMutableAttributedString *)attributedStringWithBody:(NSString *)body {
    NSString *html = [NSString stringWithFormat:@"<!DOCTYPE html><html><head><meta charset=\"utf-8\"><style>"
                      @"* { -webkit-text-size-adjust: 100%%; }"
                      @"body { font: -apple-system-body; }"
                      @"body > :last-child { margin-bottom: 0; }"
                      @"a { text-decoration: %@; }"
                      @"</style></head><body>%@</body></html>",
                      [ZBDevice buttonShapesEnabled] ? @"underline" : @"none",
                      body];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithData:[html dataUsingEncoding:NSUTF8StringEncoding] options:@{
        NSDocumentTypeDocumentOption: NSHTMLTextDocumentType
    } documentAttributes:nil error:nil];
    [attributedString addAttributes:@{
        NSForegroundColorAttributeName: [UIColor primaryTextColor]
    } range:NSMakeRange(0, attributedString.length)];
    return attributedString;
}

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        self.delegate = self;
        self.editable = NO;
        self.scrollEnabled = NO;
        self.backgroundColor = nil;
        self.textContainerInset = UIEdgeInsetsZero;
        self.textContainer.lineFragmentPadding = 0;
        if (@available(iOS 10, *)) {
            self.adjustsFontForContentSizeCategory = YES;
        }
        if (@available(iOS 11, *)) {
            self.textDragInteraction.enabled = NO;
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

    UIResponder *responder = self;
    while (responder != nil && ![responder isKindOfClass:[UIViewController class]]) {
        responder = responder.nextResponder;
    }

    if (responder) {
        [ZBDevice openURL:url delegate:(UIViewController <SFSafariViewControllerDelegate> *)responder];
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
        return ![url.scheme isEqualToString:@"zbra"];
    }
}

@end
