//
//  AUPMConsoleViewController.m
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "AUPMConsoleViewController.h"
#import "AUPMQueue.h"
#import "NSTask.h"
#import "AUPMDatabaseManager.h"
#import "AUPMAppDelegate.h"
#import "AUPMTabBarController.h"

@interface AUPMConsoleViewController () {
    UITextView *_consoleOutputView;
    AUPMQueue *_queue;
}

@end

@implementation AUPMConsoleViewController

- (id)init {
    self = [super init];
    
    if (self) {
        _queue = [AUPMQueue sharedInstance];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setHidesBackButton:YES animated:YES];
    
    _consoleOutputView = [[UITextView alloc] initWithFrame:CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height)];
    _consoleOutputView.editable = false;
    
    [self.view addSubview:_consoleOutputView];
    
    self.title = @"Console";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self performActions:[_queue tasksForQueue]];
}

- (void)performActions:(NSArray *)actions {
    
#ifdef RELEASE
    for (NSArray *command in actions) {
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/Applications/AUPM.app/supersling"];
        [task setArguments:command];
        
        NSPipe *outputPipe = [[NSPipe alloc] init];
        NSFileHandle *output = [outputPipe fileHandleForReading];
        [output waitForDataInBackgroundAndNotify];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:output];
        
        NSPipe *errorPipe = [[NSPipe alloc] init];
        NSFileHandle *error = [errorPipe fileHandleForReading];
        [error waitForDataInBackgroundAndNotify];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedErrorData:) name:NSFileHandleDataAvailableNotification object:error];
        
        [task setStandardOutput:outputPipe];
        [task setStandardError:errorPipe];
        
        [task launch];
        [task waitUntilExit];
    }
#endif
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(postInstallActions)];
    UINavigationItem *navItem = self.navigationItem;
    navItem.rightBarButtonItem = doneButton;
    
    [_queue clearQueue];
}

- (void)postInstallActions {
    // if (_action == 0 || _action == 2) {
    //   AUPMPackageManager *packageManager = [[AUPMPackageManager alloc] init];
    //
    //   if ([_packages count] == 1) {
    //     if ([packageManager packageHasApp:[_packages firstObject]]) {
    //       UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Application Detected"
    //       message:@"It looks like this package contains an application that appears on your home screen. Would you like to run uicache? If not, the application won't show up until a reboot."
    //       preferredStyle:UIAlertControllerStyleAlert];
    //
    //       UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Yep!" style:UIAlertActionStyleDefault
    //       handler:^(UIAlertAction * action) {
    //         [alert dismissViewControllerAnimated:true completion:nil];
    //
    //         UIAlertController* waitAlert = [UIAlertController alertControllerWithTitle:@"Awesome!"
    //         message:@"This might take a second, hang on!"
    //         preferredStyle:UIAlertControllerStyleAlert];
    //
    //         [self presentViewController:waitAlert animated:YES completion:nil];
    //
    //         NSTask *uiCacheTask = [[NSTask alloc] init];
    //         [uiCacheTask setLaunchPath:@"/usr/bin/uicache"];
    //
    //         [uiCacheTask launch];
    //         [uiCacheTask waitUntilExit];
    //
    //         [waitAlert dismissViewControllerAnimated:true completion:nil];
    //         [self dismissConsole];
    //       }];
    //
    //       UIAlertAction* noWayAction = [UIAlertAction actionWithTitle:@"No way!" style:UIAlertActionStyleDefault
    //       handler:^(UIAlertAction * action) {
    //         [alert dismissViewControllerAnimated:true completion:nil];
    //         [self dismissConsole];
    //       }];
    //
    //       [alert addAction:okAction];
    //       [alert addAction:noWayAction];
    //       [self presentViewController:alert animated:YES completion:nil];
    //     }
    //     else if ([packageManager packageHasTweak:[_packages firstObject]]) {
    //       UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Tweak Detected"
    //       message:@"It looks like this package contains an tweak. Would you like to respring? If not, the tweak may not work until you respring."
    //       preferredStyle:UIAlertControllerStyleAlert];
    //
    //       UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Yep!" style:UIAlertActionStyleDefault
    //       handler:^(UIAlertAction * action) {
    //         // [alert dismissViewControllerAnimated:true completion:nil];
    //
    //         UIAlertController* waitAlert = [UIAlertController alertControllerWithTitle:@"Awesome!"
    //         message:@"This might take a second, hang on!"
    //         preferredStyle:UIAlertControllerStyleAlert];
    //
    //         [self presentViewController:waitAlert animated:YES completion:nil];
    //
    //         NSTask *respringTask = [[NSTask alloc] init];
    //         [respringTask setLaunchPath:@"/usr/bin/killall"];
    //         NSArray *args = [[NSArray alloc] initWithObjects: @"-9", @"backboardd", nil];
    //         [respringTask setArguments:args];
    //
    //         [respringTask launch];
    //
    //         [waitAlert dismissViewControllerAnimated:true completion:nil];
    //       }];
    //
    //       UIAlertAction* noWayAction = [UIAlertAction actionWithTitle:@"No way!" style:UIAlertActionStyleDefault
    //       handler:^(UIAlertAction * action) {
    //         [alert dismissViewControllerAnimated:true completion:nil];
    //         [self dismissConsole];
    //       }];
    //
    //       [alert addAction:okAction];
    //       [alert addAction:noWayAction];
    //       [self presentViewController:alert animated:YES completion:nil];
    //     }
    //   }
    // }
    // else {
    //   [self dismissConsole];
    // }
    
    [self dismissConsole];
}

- (void)dismissConsole {
    AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
    [databaseManager updateEssentials:^(BOOL success) {
        AUPMTabBarController *tabController = (AUPMTabBarController *)((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController;
        [tabController updatePackageTableView];
        
        [self dismissViewControllerAnimated:true completion:nil];
    }];
}

- (void)receivedData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];
    
    if (data.length > 0) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        UIFont *font = [UIFont fontWithName:@"CourierNewPSMT" size:12.0];
        NSDictionary *attrs = @{ NSFontAttributeName: font };
        [_consoleOutputView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:str attributes:attrs]];
        
        if (_consoleOutputView.text.length > 0 ) {
            NSRange bottom = NSMakeRange(_consoleOutputView.text.length -1, 1);
            [_consoleOutputView scrollRangeToVisible:bottom];
        }
    }
}

- (void)receivedErrorData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];
    
    if (data.length > 0) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        UIColor *color = [UIColor redColor];
        UIFont *font = [UIFont fontWithName:@"CourierNewPSMT" size:12.0];
        NSDictionary *attrs = @{ NSForegroundColorAttributeName : color, NSFontAttributeName: font };
        [_consoleOutputView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:str attributes:attrs]];
        
        if (_consoleOutputView.text.length > 0 ) {
            NSRange bottom = NSMakeRange(_consoleOutputView.text.length -1, 1);
            [_consoleOutputView scrollRangeToVisible:bottom];
        }
    }
}

@end
