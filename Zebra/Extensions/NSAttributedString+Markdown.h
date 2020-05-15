//
//  NSAttributedString+Markdown.h
//  Zebra
//
//  Created by Wilson Styres on 5/14/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (Markdown)
- (id)initWithMarkdownString:(NSString *)markdownString;
@end

NS_ASSUME_NONNULL_END
