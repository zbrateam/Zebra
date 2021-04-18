//
//  ZBConsoleViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/6/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBConsoleViewController.h"

#import <Extensions/UIFont+Zebra.h>

#import <Plains/PLDatabase.h>

@interface ZBConsoleViewController () {
    UITextView *consoleView;
    UIButton *completeButton;
    UIProgressView *progressView;
}
@end

@implementation ZBConsoleViewController

#pragma mark - Initializers

- (id)init {
    self = [super init];
    
    if (self) {
        self.title = @"Console";
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    consoleView = [[UITextView alloc] initWithFrame:self.view.frame];
    consoleView.font = [UIFont monospaceFont];
    consoleView.contentInset = UIEdgeInsetsMake(8, 8, 8, 8);
    consoleView.editable = NO;
    
    [self.view addSubview:consoleView];
    
    completeButton = [[UIButton alloc] initWithFrame:CGRectZero];
    completeButton.backgroundColor = [UIColor systemPinkColor];
    completeButton.layer.cornerRadius = 10;
    completeButton.layer.masksToBounds = YES;
    completeButton.hidden = YES;
    [completeButton addTarget:self action:@selector(complete) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:completeButton];
    
    progressView = [[UIProgressView alloc] init];
    progressView.tintColor = [UIColor systemPinkColor];
    
    [self.view addSubview:progressView];
    
    [NSLayoutConstraint activateConstraints:@[
        [completeButton.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:16],
        [completeButton.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-16],
        [completeButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16],
        [completeButton.heightAnchor constraintEqualToConstant:44],
        [progressView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:16],
        [progressView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-16],
        [progressView.bottomAnchor constraintEqualToAnchor:completeButton.topAnchor constant:-16],
        [consoleView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [consoleView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [consoleView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [consoleView.bottomAnchor constraintEqualToAnchor:progressView.topAnchor constant:-8]
    ]];
    completeButton.translatesAutoresizingMaskIntoConstraints = NO;
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    consoleView.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)complete {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[PLDatabase sharedInstance] startDownloads:self];
}

- (void)writeToConsole:(NSString *)str atLevel:(PLLogLevel)level {
    if (str == nil)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIColor *color;
        UIFont *font;
        switch (level) {
            case PLLogLevelInfo:
                color = [UIColor labelColor];
                font = UIFont.monospaceFont;
                break;
            case PLLogLevelStatus:
                color = [UIColor labelColor];
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
//    [self writeToConsole:@"Started Downloads." atLevel:PLLogLevelStatus];
}

- (void)progressUpdate:(CGFloat)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->progressView setProgress:progress];
    });
}

- (void)statusUpdate:(NSString *)update atLevel:(PLLogLevel)level {
    [self writeToConsole:update atLevel:level];
}

- (void)finishedDownloads {
//    [self writeToConsole:@"Finished Downloads." atLevel:PLLogLevelStatus];
}

- (void)startedInstalls {
//    [self writeToConsole:message atLevel:PLLogLevelStatus];
}

- (void)finishedInstalls {
//    [self writeToConsole:@"Finished Installs." atLevel:PLLogLevelStatus];
    dispatch_async(dispatch_get_main_queue(), ^{
        self->completeButton.hidden = NO;
    });
}

@end
