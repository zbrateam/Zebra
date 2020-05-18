//
//  NSAttributedString+Markdown.h
//  Zebra
//
//  Created by Wilson Styres on 5/14/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (Markdown)
- (id)initWithMarkdownString:(NSString *)markdownString;
- (id)initWithMarkdownString:(NSString *)markdownString fontSize:(CGFloat)fontSize;
@end

NS_ASSUME_NONNULL_END
