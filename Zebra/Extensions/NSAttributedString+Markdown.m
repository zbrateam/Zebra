//
//  NSAttributedString+Markdown.m
//  Zebra
//
//  Created by Wilson Styres on 5/14/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "NSAttributedString+Markdown.h"

@import CocoaMarkdown;

@implementation NSAttributedString (Markdown)

- (id)initWithMarkdownString:(NSString *)markdownString {
    if (markdownString == nil) return nil;
    CMDocument *document = [[CMDocument alloc] initWithString:markdownString options:0];

    CMAttributedStringRenderer *renderer = [[CMAttributedStringRenderer alloc] initWithDocument:document attributes:[self baseAttributes:0]];
    
    return [renderer render];
}

- (id)initWithMarkdownString:(NSString *)markdownString fontSize:(CGFloat)fontSize {
    if (markdownString == nil) return nil;
    CMDocument *document = [[CMDocument alloc] initWithString:markdownString options:0];
    
    CMAttributedStringRenderer *renderer = [[CMAttributedStringRenderer alloc] initWithDocument:document attributes:[self baseAttributes:fontSize]];
    
    return [renderer render];
}

- (CMTextAttributes *)baseAttributes:(CGFloat)fontSize {
    CMTextAttributes *attributes = [[CMTextAttributes alloc] init];
    
    // Set spacing on ordered lists
    [attributes addParagraphStyleAttributes:@{CMParagraphStyleAttributeFirstLineHeadExtraIndent: @(0), CMParagraphStyleAttributeHeadExtraIndent: @(0)} forElementWithKinds:CMElementKindOrderedList];
    [attributes addParagraphStyleAttributes:@{CMParagraphStyleAttributeFirstLineHeadExtraIndent: @(0), CMParagraphStyleAttributeHeadExtraIndent: @(0)} forElementWithKinds:CMElementKindOrderedSublist];
    
    // Set spacing on unordered list (and set bullet character)
    [attributes addParagraphStyleAttributes:@{CMParagraphStyleAttributeListItemBulletString: @"\u2022", CMParagraphStyleAttributeFirstLineHeadExtraIndent: @(0), CMParagraphStyleAttributeHeadExtraIndent: @(0)} forElementWithKinds:CMElementKindUnorderedList];
    [attributes addParagraphStyleAttributes:@{CMParagraphStyleAttributeListItemBulletString: @"\u25E6", CMParagraphStyleAttributeFirstLineHeadExtraIndent: @(0), CMParagraphStyleAttributeHeadExtraIndent: @(0)} forElementWithKinds:CMElementKindUnorderedSublist];
    
    // Set font size
    if (fontSize > 0) [attributes addFontAttributes:@{UIFontDescriptorSizeAttribute: @(fontSize)} forElementWithKinds:CMElementKindText];
    
    return attributes;
}

@end
