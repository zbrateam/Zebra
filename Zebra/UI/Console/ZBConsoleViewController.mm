//
//  ZBConsoleViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/6/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBConsoleViewController.h"

#import "Zebra-Swift.h"

#import <Plains/Plains.h>

typedef NS_ENUM(NSUInteger, ZBConsoleFinishOption) {
    ZBConsoleFinishOptionClose,
    ZBConsoleFinishOptionRefreshIconCache,
    ZBConsoleFinishOptionReopen,
    ZBConsoleFinishOptionRestartSpringBoard,
    ZBConsoleFinishOptionReload,
    ZBConsoleFinishOptionRebootDevice
};

@interface ZBConsoleViewController () {
    UITextView *consoleView;
    UIButton *completeButton;
    UIProgressView *progressView;
    ZBConsoleFinishOption finishOption;
    NSArray *installedApps;
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
    consoleView.font = [UIFont monospace];
    consoleView.contentInset = UIEdgeInsetsMake(8, 8, 8, 8);
    consoleView.editable = NO;
    
    [self.view addSubview:consoleView];
    
    completeButton = [[UIButton alloc] initWithFrame:CGRectZero];
    completeButton.backgroundColor = [UIColor accentColor];
    completeButton.layer.cornerRadius = 10;
    completeButton.layer.masksToBounds = YES;
    completeButton.hidden = YES;
    completeButton.titleLabel.font = [UIFont boldSystemFontOfSize:completeButton.titleLabel.font.pointSize];
    
    [self.view addSubview:completeButton];
    
    progressView = [[UIProgressView alloc] init];
    progressView.tintColor = [UIColor accentColor];
    
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 13.0, macCatalyst 13.0, *)) {
        self.navigationController.navigationBar.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.navigationItem.hidesBackButton = YES;
    
    installedApps = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Applications" error:nil];
    [[PLPackageManager sharedInstance] downloadAndPerform:self];
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
                font = UIFont.monospace;
                break;
            case PLLogLevelStatus:
                color = [UIColor labelColor];
                font = UIFont.boldMonospace;
                break;
            case PLLogLevelError:
                color = [UIColor redColor];
                font = UIFont.boldMonospace;
                break;
            case PLLogLevelWarning:
                color = [UIColor yellowColor];
                font = UIFont.monospace;
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

#pragma mark - Plains Console Delegate

- (void)startedDownloads {
    [self writeToConsole:@"Downloading Packages." atLevel:PLLogLevelStatus];
}

- (void)progressUpdate:(CGFloat)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->progressView setProgress:progress];
    });
}

- (void)statusUpdate:(NSString *)update atLevel:(PLLogLevel)level {
    [self writeToConsole:update atLevel:level];
}

- (void)finishUpdate:(NSString *)update {
    if ([update hasPrefix:@"finish:"]) {
        NSArray *components = [update componentsSeparatedByString:@":"];
        if (components.count == 2) {
            NSString *option = [components[1] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            NSArray *options = @[@"return", @"uicache", @"reopen", @"restart", @"reload", @"reboot"];
            NSUInteger index = [options indexOfObject:option];
            
            if (index != NSNotFound && index > finishOption) {
                finishOption = (ZBConsoleFinishOption)index;
            }
        }
    }
}

- (void)finishedDownloads {
    [self writeToConsole:@"Downloads Complete." atLevel:PLLogLevelStatus];
}

- (void)startedInstalls {
    [self writeToConsole:@"Performing Actions." atLevel:PLLogLevelStatus];
}

- (void)finishedInstalls {
    if (finishOption == ZBConsoleFinishOptionRefreshIconCache) {
        [self writeToConsole:@"Refreshing Icon Cache." atLevel:PLLogLevelStatus];
        [self refreshIconCache];
    }
    
    [self writeToConsole:@"Reloading package lists." atLevel:PLLogLevelStatus];
    [[PLPackageManager sharedInstance] import];
    [self writeToConsole:@"Finished." atLevel:PLLogLevelStatus];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.4 animations:^{
            self->progressView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self->progressView.hidden = YES;
        }];
        
        self->completeButton.hidden = NO;
        
        NSString *title;
        SEL action;
        switch (self->finishOption) {
            case ZBConsoleFinishOptionReopen:
                title = @"Restart Zebra";
                action = @selector(restartZebra);
                break;
            case ZBConsoleFinishOptionRestartSpringBoard:
            case ZBConsoleFinishOptionReload:
                title = @"Restart SpringBoard";
                action = @selector(restartSpringBoard);
                break;
            case ZBConsoleFinishOptionRebootDevice:
                title = @"Reboot Device";
                action = @selector(rebootDevice);
                break;
            default:
                title = @"Done";
                action = @selector(complete);
                break;
        }
        
        [self->completeButton setTitle:title forState:UIControlStateNormal];
        [self->completeButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
        [self->completeButton addTarget:self action:action forControlEvents:UIControlEventTouchUpOutside];
    });
}

#pragma mark - Finish Actions

- (void)complete {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)refreshIconCache {
    NSMutableArray *installedAppsNow = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Applications" error:nil] mutableCopy];
    for (NSString *path in installedApps) {
        [installedAppsNow removeObject:path];
    }
    
    if (installedAppsNow.count) {
        NSMutableArray *fullPaths = [NSMutableArray new];
        for (NSString *app in installedAppsNow) {
            [fullPaths addObject:[@"/Applications/" stringByAppendingPathComponent:app]];
        }
        
        [ZBDeviceCommands uicacheWithPaths:fullPaths];
    }
}

- (void)restartZebra {
    [ZBDeviceCommands relaunchZebra];
}

- (void)restartSpringBoard {
    [ZBDeviceCommands restartSystemApp];
}

- (void)rebootDevice {
    [ZBDeviceCommands reboot];
}

@end
