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
    CMTextAttributes *attributes = [[CMTextAttributes alloc] init];
    [attributes addParagraphStyleAttributes:@{CMParagraphStyleAttributeListItemBulletString: @"\u2022", CMParagraphStyleAttributeFirstLineHeadExtraIndent: @(0), CMParagraphStyleAttributeHeadExtraIndent: @(0)} forElementWithKinds:CMElementKindUnorderedList];
    [attributes addParagraphStyleAttributes:@{CMParagraphStyleAttributeListItemBulletString: @"\u25E6", CMParagraphStyleAttributeFirstLineHeadExtraIndent: @(0), CMParagraphStyleAttributeHeadExtraIndent: @(0)} forElementWithKinds:CMElementKindUnorderedSublist];
    
    CMAttributedStringRenderer *renderer = [[CMAttributedStringRenderer alloc] initWithDocument:document attributes:[[CMTextAttributes alloc] init]];
    
    return [renderer render];
}

@end
