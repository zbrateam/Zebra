//
//  ZBRefreshViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <ZBTabBarController.h>
#import <ZBDevice.h>
#import "ZBRefreshViewController.h"
#import <Database/ZBDatabaseManager.h>
#include <Parsel/parsel.h>

@interface ZBRefreshViewController () {
    ZBDatabaseManager *databaseManager;
    BOOL hadAProblem;
}
@property (strong, nonatomic) IBOutlet UIButton *completeButton;
@property (strong, nonatomic) IBOutlet UITextView *consoleView;
@end

@implementation ZBRefreshViewController

@synthesize messages;

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([ZBDevice darkModeEnabled]) {
        [self setNeedsStatusBarAppearanceUpdate];
        [self.view setBackgroundColor:[UIColor tableViewBackgroundColor]];
        [_consoleView setBackgroundColor:[UIColor tableViewBackgroundColor]];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if ([ZBDevice darkModeEnabled]) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!messages) {
        databaseManager = [ZBDatabaseManager sharedInstance];
        [databaseManager addDatabaseDelegate:self];
        
        if (_dropTables) {
            [databaseManager dropTables];
        }
        
        [databaseManager updateDatabaseUsingCaching:false userRequested:true];
    }
    else {
        hadAProblem = true;
        
        for (NSString *message in messages) {
            [self writeToConsole:message atLevel:ZBLogLevelError];
        }
        
        [self goodbye];
    }
}

- (IBAction)completeButton:(id)sender {
    messages = NULL;
    hadAProblem = false;
    [self goodbye];
}

- (void)goodbye {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(goodbye) withObject:nil waitUntilDone:false];
    }
    else {
        if (hadAProblem) {
            messages = NULL;
            self.completeButton.hidden = false;
        }
        else {
            if ([self presentingViewController] != NULL) {
                [self dismissViewControllerAnimated:true completion:nil];
            }
            else {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
                ZBTabBarController *vc = [storyboard instantiateViewControllerWithIdentifier:@"tabController"];
                [self presentViewController:vc animated:YES completion:nil];
            }
        }
    }
}

- (void)writeToConsole:(NSString *)str atLevel:(ZBLogLevel)level {
    if (str == NULL)
        return;
    __block BOOL isDark = [ZBDevice darkModeEnabled];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIColor *color;
        UIFont *font;
        switch (level) {
            case ZBLogLevelDescript: {
                if (isDark) {
                    color = [UIColor whiteColor];
                } else {
                    color = [UIColor blackColor];
                }
                font = [UIFont fontWithName:@"CourierNewPSMT" size:10.0];
                break;
            }
            case ZBLogLevelInfo: {
                if (isDark) {
                    color = [UIColor whiteColor];
                } else {
                    color = [UIColor blackColor];
                }
                font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:10.0];
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
            default: {
                color = [UIColor whiteColor];
                break;
            }
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
    hadAProblem = false;
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    ZBTabBarController *tabController = (ZBTabBarController *)[[[UIApplication sharedApplication] delegate] window].rootViewController;
    [tabController setPackageUpdateBadgeValue:packageUpdates];
    [self goodbye];
}

- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level {
    if (level == ZBLogLevelError || level == ZBLogLevelWarning) {
        hadAProblem = true;
    }
    
    [self writeToConsole:status atLevel:level];
}

@end
