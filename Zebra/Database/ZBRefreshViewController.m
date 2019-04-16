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
}
@property (strong, nonatomic) IBOutlet UITextView *consoleView;
@end

@implementation ZBRefreshViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    databaseManager = [[ZBDatabaseManager alloc] init];

    if (_dropTables) {
        [databaseManager dropTables];
    }
    
    [databaseManager updateDatabaseUsingCaching:false];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseStatusUpdate:) name:@"databaseStatusUpdate" object:nil];
}

- (void)goodbye {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(goodbye) withObject:nil waitUntilDone:false];
    }
    else {
        if ([self presentingViewController] != NULL) {
            [self dismissViewControllerAnimated:true completion:nil];
        }
        else {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
            ZBTabBarController *vc = [storyboard instantiateViewControllerWithIdentifier:@"tabController"];
            //        vc.hasUpdates = hasUpdates;
            //        vc.updates = updates;
            [self presentViewController:vc animated:YES completion:nil];
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
            case ZBLogLevelDescript:
                color = [UIColor blackColor];
                font = [UIFont fontWithName:@"CourierNewPSMT" size:10.0];
                break;
            case ZBLogLevelInfo:
                color = [UIColor blackColor];
                font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:10.0];
                break;
            case ZBLogLevelError:
                color = [UIColor redColor];
                font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:10.0];
                break;
            case ZBLogLevelWarning:
                color = [UIColor yellowColor];
                font = [UIFont fontWithName:@"CourierNewPSMT" size:10.0];
                break;
            default:
                color = [UIColor whiteColor];
                break;
        }

        NSDictionary *attrs = @{ NSForegroundColorAttributeName: color, NSFontAttributeName: font };

        [self->_consoleView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:str attributes:attrs]];

        if (self->_consoleView.text.length > 0 ) {
            NSRange bottom = NSMakeRange(self->_consoleView.text.length -1, 1);
            [self->_consoleView scrollRangeToVisible:bottom];
        }
    });
}

- (void)databaseStatusUpdate:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"databaseStatusUpdate"]) {
        NSDictionary* userInfo = notification.userInfo;
        ZBLogLevel level = [userInfo[@"level"] intValue];
        NSString *message = userInfo[@"message"];

        [self writeToConsole:message atLevel:level];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
