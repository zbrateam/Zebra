//
//  ZBRefreshViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBRefreshViewController.h"
#import <Database/ZBDatabaseManager.h>
#import <Parsel/Parsel.h>

@interface ZBRefreshViewController ()
@property (strong, nonatomic) IBOutlet UITextView *consoleView;
@end

@implementation ZBRefreshViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
    [databaseManager fullImport];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UINavigationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"tabController"];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseStatusUpdate:) name:@"databaseStatusUpdate" object:nil];
}

- (void)writeToConsole:(NSString *)str atLevel:(ZBLogLevel)level {
    UIColor *color;
    UIFont *font;
    switch(level) {
        case ZBLogLevelDescript:
            color = [UIColor blackColor];
            font = [UIFont fontWithName:@"CourierNewPSMT" size:12.0];
            break;
        case ZBLogLevelInfo:
            color = [UIColor blackColor];
            font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:12.0];
            break;
        case ZBLogLevelError:
            color = [UIColor redColor];
            font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:12.0];
            break;
        case ZBLogLevelWarning:
            color = [UIColor yellowColor];
            font = [UIFont fontWithName:@"CourierNewPSMT" size:12.0];
            break;
        default:
            color = [UIColor whiteColor];
            break;
    }
        
    NSDictionary *attrs = @{ NSForegroundColorAttributeName: color, NSFontAttributeName: font };
    
    [_consoleView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:str attributes:attrs]];
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
