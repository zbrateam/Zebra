//
//  ZBRefreshViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBRefreshViewController.h"

#import "ZBDatabaseManager.h"
#import <Extensions/UIColor+GlobalColors.h>
#import <Extensions/UIFont+Zebra.h>
#import <Tabs/ZBTabBarController.h>
#import <Tabs/Sources/Helpers/ZBBaseSource.h>
#import <Tabs/Sources/Helpers/ZBSourceManager.h>
#import <Theme/ZBThemeManager.h>

typedef enum {
    ZBStateCancel = 0,
    ZBStateDone
} ZBRefreshButtonState;

@interface ZBRefreshViewController () {
    ZBSourceManager *sourceManager;
    BOOL hadAProblem;
}
@property (strong, nonatomic) IBOutlet UIButton *completeOrCancelButton;
@property (strong, nonatomic) IBOutlet UITextView *consoleView;
@end

@implementation ZBRefreshViewController

#pragma mark - Initializers

- (id)init {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
    
    if (self) {
        sourceManager = [ZBSourceManager sharedInstance];
        [sourceManager addDelegate:self];
        
        hadAProblem = NO;
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setCompleteOrCancelButtonHidden:YES];
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.consoleView setBackgroundColor:[UIColor blackColor]];
    
    ZBAccentColor color = [ZBSettings accentColor];
    ZBInterfaceStyle style = [ZBSettings interfaceStyle];
    if (color == ZBAccentColorMonochrome) {
        //Flip the colors for readability
        [[self completeOrCancelButton] setBackgroundColor:[UIColor whiteColor]];
        [[self completeOrCancelButton] setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    else {
        [[self completeOrCancelButton] setBackgroundColor:[ZBThemeManager getAccentColor:color forInterfaceStyle:style] ?: [UIColor systemBlueColor]];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.consoleView.backgroundColor = [UIColor blackColor];
    
    [[ZBDatabaseManager sharedInstance] dropTables];
    [sourceManager refreshSourcesUsingCaching:NO userRequested:YES error:nil];
}

- (IBAction)completeOrCancelButton:(id)sender {
    [self goodbye];
}

- (void)goodbye {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(goodbye) withObject:nil waitUntilDone:NO];
    } else {
        [sourceManager removeDelegate:self];
        [[[UIApplication sharedApplication] windows][0] setRootViewController:[[ZBTabBarController alloc] init]];
    }
}

#pragma mark - UI Updates

- (void)setCompleteOrCancelButtonHidden:(BOOL)hidden {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.completeOrCancelButton setHidden:hidden];
    });
}

- (void)updateCompleteOrCancelButtonText:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.completeOrCancelButton setTitle:text forState:UIControlStateNormal];
    });
}

- (void)clearConsoleText {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.consoleView setText:nil];
    });
}

- (void)writeToConsole:(NSString *)str atLevel:(ZBLogLevel)level {
    if (str == nil)
        return;
    if (![str hasSuffix:@"\n"])
        str = [str stringByAppendingString:@"\n"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIColor *color = [UIColor whiteColor];
        UIFont *font;
        switch (level) {
            case ZBLogLevelDescript:
                font = UIFont.monospaceFont;
            case ZBLogLevelInfo: {
                if ([ZBSettings interfaceStyle] < ZBInterfaceStyleDark) {
                    color = [UIColor whiteColor];
                }
                font = font ?: UIFont.boldMonospaceFont;
                break;
            }
            case ZBLogLevelError: {
                color = [UIColor systemRedColor];
                font = UIFont.boldMonospaceFont;
                break;
            }
            case ZBLogLevelWarning: {
                color = [UIColor systemYellowColor];
                font = UIFont.monospaceFont;
                break;
            }
            default:
                break;
        }

        NSDictionary *attrs = @{ NSForegroundColorAttributeName: color, NSFontAttributeName: font };
        
        [self.consoleView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:str attributes:attrs]];

        if (self.consoleView.text.length) {
            NSRange bottom = NSMakeRange(self.consoleView.text.length - 1, 1);
            [self.consoleView scrollRangeToVisible:bottom];
        }
    });
}

#pragma mark - Source Delegate

- (void)startedSourceRefresh {
    [self writeToConsole:NSLocalizedString(@"Migrating Database...", @"") atLevel:ZBLogLevelInfo];
}

- (void)startedDownloadForSource:(ZBBaseSource *)source {
    [self writeToConsole:[NSString stringWithFormat:NSLocalizedString(@"Downloading %@", @""), source.repositoryURI] atLevel:ZBLogLevelDescript];
}

- (void)finishedDownloadForSource:(ZBBaseSource *)source {
    [self writeToConsole:[NSString stringWithFormat:NSLocalizedString(@"Finished Downloading %@", @""), source.repositoryURI] atLevel:ZBLogLevelDescript];
    for (NSError *error in source.errors) {
        hadAProblem = YES;
        [self writeToConsole:error.localizedDescription atLevel:ZBLogLevelError];
    }
    
    for (NSError *warning in source.warnings) {
        [self writeToConsole:warning.localizedDescription atLevel:ZBLogLevelWarning];
    }
}

- (void)startedImportForSource:(ZBBaseSource *)source {
    [self writeToConsole:[NSString stringWithFormat:NSLocalizedString(@"Importing %@", @""), source.repositoryURI] atLevel:ZBLogLevelDescript];
}

- (void)finishedImportForSource:(ZBBaseSource *)source {
    [self writeToConsole:[NSString stringWithFormat:NSLocalizedString(@"Finished Importing %@", @""), source.repositoryURI] atLevel:ZBLogLevelDescript];
}

- (void)updatesAvailable:(int)numberOfUpdates {
    [self writeToConsole:[NSString stringWithFormat:NSLocalizedString(@"%d updates are available", @""), numberOfUpdates] atLevel:ZBLogLevelDescript];
}

- (void)finishedSourceRefresh {
    [self writeToConsole:NSLocalizedString(@"Migration Complete!", @"") atLevel:ZBLogLevelInfo];
    
    if (hadAProblem) {
        [self updateCompleteOrCancelButtonText:NSLocalizedString(@"Done", @"")];
        [self setCompleteOrCancelButtonHidden:NO];
    } else {
        [self goodbye];
    }
}

@end
