//
//  ZBConsoleViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/6/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBConsoleViewController.h"

#import <Extensions/UIFont+Zebra.h>

@interface ZBConsoleViewController () {
    UITextView *consoleView;
}
@end

@implementation ZBConsoleViewController

#pragma mark - Initializers

- (id)init {
    self = [super init];
    
    if (self) {
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)loadView {
    [super loadView];
    
    consoleView = [[UITextView alloc] initWithFrame:self.view.frame];
    consoleView.autoresizingMask  = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    consoleView.font = [UIFont monospaceFont];
    
    [self.view addSubview:consoleView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (void)writeToConsole:(NSString *)str atLevel:(PLLogLevel)level {
    if (str == nil)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIColor *color;
        UIFont *font;
        switch (level) {
            case PLLogLevelInfo:
                color = [UIColor whiteColor];
                font = UIFont.monospaceFont;
                break;
            case PLLogLevelStatus:
                color = [UIColor whiteColor];
                font = UIFont.boldMonospaceFont;
                break;
            case PLLogLevelError:
                color = [UIColor redColor];
                font = UIFont.boldMonospaceFont;
                break;
            case PLLogLevelWarning:
                color = [UIColor yellowColor];
                font = UIFont.monospaceFont;
                break;
        }

        NSDictionary *attrs = @{ NSForegroundColorAttributeName: color, NSFontAttributeName: font };
        
        //Adds a newline if there is not already one
        NSString *string = [str copy];
        if (![string hasSuffix:@"\n"]) {
            string = [str stringByAppendingString:@"\n"];
        }
        
        if (string == nil) {
            return;
        }
        
        [self->consoleView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:string attributes:attrs]];

        if (self->consoleView.text.length) {
            NSRange bottom = NSMakeRange(self->consoleView.text.length - 1, 1);
            [self->consoleView scrollRangeToVisible:bottom];
        }
    });
}

#pragma mark - Plains Acquire Delegate

- (void)startedDownloads {
    [self writeToConsole:@"Started Downloads." atLevel:PLLogLevelStatus];
}

- (void)progressUpdate:(CGFloat)progress {
    [self writeToConsole:[NSString stringWithFormat:@"%f%%", progress] atLevel:PLLogLevelInfo];
}

- (void)statusUpdate:(NSString *)update atLevel:(PLLogLevel)level {
    [self writeToConsole:update atLevel:level];
}

- (void)finishedDownloads {
    [self writeToConsole:@"Finished Downloads." atLevel:PLLogLevelStatus];
}

@end
