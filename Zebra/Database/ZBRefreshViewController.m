//
//  ZBRefreshViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBRefreshViewController.h"
#import <Database/ZBDatabaseManager.h>
#include <Parsel/parsel.h>
#import <ZBTabBarController.h>

@interface ZBRefreshViewController () {
    ZBDatabaseManager *databaseManager;
    BOOL hadAProblem;
}
@property (strong, nonatomic) IBOutlet UIButton *completeButton;
@property (strong, nonatomic) IBOutlet UITextView *consoleView;
@end

@implementation ZBRefreshViewController

@synthesize messages;

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!messages) {
        databaseManager = [ZBDatabaseManager sharedInstance];
        [databaseManager setDatabaseDelegate:self];
        
        if (_dropTables) {
            [databaseManager dropTables];
        }
        
        [databaseManager updateDatabaseUsingCaching:false requested:true];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        if (str == NULL)
            return;

        UIColor *color;
        UIFont *font;
        switch(level) {
            case ZBLogLevelDescript: {
                color = [UIColor blackColor];
                font = [UIFont fontWithName:@"CourierNewPSMT" size:10.0];
                break;
            }
            case ZBLogLevelInfo: {
                color = [UIColor blackColor];
                font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:10.0];
                break;
            }
            case ZBLogLevelError: {
                self->hadAProblem = true;
                color = [UIColor redColor];
                font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:10.0];
                break;
            }
            case ZBLogLevelWarning: {
                self->hadAProblem = true;
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

        if (self->_consoleView.text.length > 0 ) {
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
    [(ZBTabBarController *)self.tabBarController setPackageUpdateBadgeValue:packageUpdates];
    [self goodbye];
}

- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level {
    [self writeToConsole:status atLevel:level];
}

@end
