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

@interface ZBRefreshViewController ()
@property (strong, nonatomic) IBOutlet UITextView *consoleView;
@end

@implementation ZBRefreshViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
    
    if (_dropTables) {
        [databaseManager dropTables];
    }
    
    [databaseManager updateDatabaseUsingCaching:false singleRepo:NULL completion:^(BOOL success, NSError * _Nonnull error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"repoStatusUpdate" object:self userInfo:@{@"type": @"updateCheck"}];
        [self goodbye];
    }];
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
    
    [_consoleView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:str attributes:attrs]];
    
    if (_consoleView.text.length > 0 ) {
        NSRange bottom = NSMakeRange(_consoleView.text.length -1, 1);
        [_consoleView scrollRangeToVisible:bottom];
    }
}

- (void)databaseStatusUpdate:(NSNotification *)notification {
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(databaseStatusUpdate:) withObject:notification waitUntilDone:NO];
        return;
    }
    else if ([notification.name isEqualToString:@"databaseStatusUpdate"])
    {
        NSDictionary* userInfo = notification.userInfo;
        int level = [userInfo[@"level"] intValue];
        NSString *message = userInfo[@"message"];
        
        switch (level) {
            case 0:
                [self writeToConsole:message atLevel:ZBLogLevelDescript];
                break;
            case 1:
                [self writeToConsole:message atLevel:ZBLogLevelInfo];
                break;
            case 2:
                [self writeToConsole:message atLevel:ZBLogLevelError];
                break;
            default:
                break;
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
