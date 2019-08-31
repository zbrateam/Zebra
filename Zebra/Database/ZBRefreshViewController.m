//
//  ZBRefreshViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <ZBTabBarController.h>
#import <ZBDevice.h>
#import <Database/ZBDatabaseManager.h>
#import <Downloads/ZBDownloadManager.h>
#import <ZBRepoManager.h>
#include <Parsel/parsel.h>
#import "ZBRefreshViewController.h"

typedef enum {
    ZBStateCancel = 0,
    ZBStateDone
} ZBRefreshButtonState;

@interface ZBRefreshViewController () {
    ZBDatabaseManager *databaseManager;
    BOOL hadAProblem;
    ZBRefreshButtonState buttonState;
}
@property (strong, nonatomic) IBOutlet UIButton *completeOrCancelButton;
@property (strong, nonatomic) IBOutlet UITextView *consoleView;
@end

@implementation ZBRefreshViewController

@synthesize messages;

- (void)viewDidLoad {
    [super viewDidLoad];
    if (_dropTables) {
        self.completeOrCancelButton.hidden = YES;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableCancelButton) name:@"disableCancelRefresh" object:nil];
    if ([ZBDevice darkModeEnabled]) {
        [self setNeedsStatusBarAppearanceUpdate];
        [self.view setBackgroundColor:[UIColor tableViewBackgroundColor]];
        [_consoleView setBackgroundColor:[UIColor tableViewBackgroundColor]];
    }
}

- (void)disableCancelButton {
    buttonState = ZBStateDone;
    self.completeOrCancelButton.hidden = YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [ZBDevice darkModeEnabled] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!messages) {
        databaseManager = [ZBDatabaseManager sharedInstance];
        [databaseManager addDatabaseDelegate:self];
        
        if (_dropTables) {
            [databaseManager dropTables];
        }
        
        if (self.repoURLs.count) {
            // Update only the repos specified
            [databaseManager updateRepoURLs:self.repoURLs useCaching:NO];
        } else {
            // Update every repo
            [databaseManager updateDatabaseUsingCaching:NO userRequested:YES];
        }
    } else {
        hadAProblem = YES;
        for (NSString *message in messages) {
            [self writeToConsole:message atLevel:ZBLogLevelError];
        }
        buttonState = ZBStateDone;
        [self clearProblems];
    }
}

- (IBAction)completeOrCancelButton:(id)sender {
    if (buttonState == ZBStateDone) {
        [self goodbye];
    } else {
        if (_dropTables) {
            return;
        }
        [databaseManager cancelUpdates:self];
        ((ZBTabBarController *)self.tabBarController).repoBusyList = [NSMutableDictionary new];
        [self writeToConsole:@"Refresh cancelled\n" atLevel:ZBLogLevelInfo];
        
        buttonState = ZBStateDone;
        [self.completeOrCancelButton setTitle:@"Done" forState:UIControlStateNormal];
    }
}

- (void)clearProblems {
    messages = NULL;
    hadAProblem = NO;
    self->_consoleView.text = nil;
}

- (void)goodbye {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(goodbye) withObject:nil waitUntilDone:NO];
    } else {
        [self clearProblems];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)writeToConsole:(NSString *)str atLevel:(ZBLogLevel)level {
    if (str == NULL)
        return;
    __block BOOL isDark = [ZBDevice darkModeEnabled];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIColor *color = [UIColor whiteColor];
        UIFont *font;
        switch (level) {
            case ZBLogLevelDescript ... ZBLogLevelInfo: {
                if (!isDark) {
                    color = [UIColor blackColor];
                }
                font = [UIFont fontWithName:level == ZBLogLevelDescript ? @"CourierNewPSMT" : @"CourierNewPS-BoldMT" size:10.0];
                break;
            }
            case ZBLogLevelError: {
                color = [UIColor redColor];
                font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:10.0];
                break;
            }
            case ZBLogLevelWarning: {
                color = [UIColor yellowColor];
                font = [UIFont fontWithName:@"CourierNewPSMT" size:10.0];
                break;
            }
            default:
                break;

        }

        NSDictionary *attrs = @{ NSForegroundColorAttributeName: color, NSFontAttributeName: font };
        
        [self->_consoleView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:str attributes:attrs]];

        if (self->_consoleView.text.length) {
            NSRange bottom = NSMakeRange(self->_consoleView.text.length -1, 1);
            [self->_consoleView scrollRangeToVisible:bottom];
        }
    });
}

#pragma mark - Database Delegate

- (void)databaseStartedUpdate {
    hadAProblem = NO;
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    ZBTabBarController *tabController = (ZBTabBarController *)[[[UIApplication sharedApplication] delegate] window].rootViewController;
    if (packageUpdates != -1) {
        [tabController setPackageUpdateBadgeValue:packageUpdates];
    }
    if (!hadAProblem) {
        [self goodbye];
    } else {
        [self.completeOrCancelButton setTitle:@"Done" forState:UIControlStateNormal];
    }
    [[ZBRepoManager sharedInstance] needRecaching];
}

- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level {
    if (level == ZBLogLevelError || level == ZBLogLevelWarning) {
        hadAProblem = YES;
    }
    [self writeToConsole:status atLevel:level];
}

@end
