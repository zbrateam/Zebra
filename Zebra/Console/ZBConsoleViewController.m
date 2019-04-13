//
//  ZBConsoleViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/6/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBConsoleViewController.h"
#import <Queue/ZBQueue.h>
#import <NSTask.h>
#import <Database/ZBDatabaseManager.h>
#import <ZBAppDelegate.h>
#import <ZBTabBarController.h>
#import <Hyena/Hyena.h>
#import <ZBTabBarController.h>

@interface ZBConsoleViewController () {
    int stage;
}
@property (strong, nonatomic) IBOutlet UITextView *consoleView;
@property (strong, nonatomic) IBOutlet UIButton *completeButton;
@property (strong, nonatomic) ZBQueue *queue;
@end

@implementation ZBConsoleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (_queue == NULL) {
        _queue = [ZBQueue sharedInstance];
    }
    stage = -1;
    
    [self setTitle:@"Console"];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [self.navigationItem setHidesBackButton:true animated:true];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadStatusUpdate:) name:@"downloadStatusUpdate" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self performActions];
}

- (void)performActions {
    [self writeToConsole:@"Downloading Packages...\n" atLevel:ZBLogLevelInfo];
    Hyena *predator = [[Hyena alloc] init];
    [predator downloadDebsFromQueueWithCompletion:^(NSArray * _Nonnull debs, BOOL success) {
        [self writeToConsole:@"Download Complete!\n" atLevel:ZBLogLevelInfo];
        NSArray *actions = [self->_queue tasks:debs];
        for (NSArray *command in actions) {
            if (![ZBAppDelegate needsSimulation]) {
                if ([command count] == 1) {
                    [self updateStatus:[command[0] intValue]];
                    continue;
                }
                
                NSTask *task = [[NSTask alloc] init];
                [task setLaunchPath:@"/Applications/Zebra.app/supersling"];
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
        }
        [self performPostActions:^(BOOL success) {
            [self->_queue clearQueue];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateStatus:4];
            self->_completeButton.hidden = false;
        });
    }];
    [self performPostActions:^(BOOL success) {
        [(ZBTabBarController *)self.tabBarController checkForPackageUpdates];
    }];
}

- (void)performPostActions:(void (^)(BOOL success))completion  {
    ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
    [databaseManager importLocalPackages:^(BOOL success) {
        completion(success);
    }];
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:[ZBAppDelegate debsLocation]];
    NSString *file;
    
    while (file = [enumerator nextObject]) {
        NSError *error = nil;
        BOOL result = [[NSFileManager defaultManager] removeItemAtPath:[[ZBAppDelegate debsLocation] stringByAppendingPathComponent:file] error:&error];
        
        if (!result && error) {
            NSLog(@"Error while removing %@: %@", file, error);
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"repoStatusUpdate" object:self userInfo:@{@"type": @"updateCheck"}];
}

- (void)updateStatus:(int)s {
    switch (s) {
        case 0:
            stage = 0;
            [self setTitle:@"Installing"];
            [self writeToConsole:@"Installing Packages...\n" atLevel:ZBLogLevelInfo];
            break;
        case 1:
            stage = 1;
            [self setTitle:@"Removing"];
            [self writeToConsole:@"Removing Packages...\n" atLevel:ZBLogLevelInfo];
            break;
        case 2:
            stage = 2;
            [self setTitle:@"Reinstalling"];
            [self writeToConsole:@"Reinstalling Packages...\n" atLevel:ZBLogLevelInfo];
            break;
        case 3:
            stage = 3;
            [self setTitle:@"Upgrading"];
            [self writeToConsole:@"Upgrading Packages...\n" atLevel:ZBLogLevelInfo];
            break;
        case 4:
            stage = 4;
            [self setTitle:@"Done!"];
            [self writeToConsole:@"Done!\n" atLevel:ZBLogLevelInfo];
            break;
            
        default:
            break;
    }
}

- (void)receivedData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];
    
    if (data.length > 0) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self writeToConsole:str atLevel:ZBLogLevelDescript];
    }
}

- (void)receivedErrorData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];
    
    if (data.length > 0) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([str rangeOfString:@"warning"].location != NSNotFound) {
            str = [str stringByReplacingOccurrencesOfString:@"dpkg: " withString:@""];
            [self writeToConsole:str atLevel:ZBLogLevelWarning];
        }
        else if ([str rangeOfString:@"error"].location != NSNotFound) {
            str = [str stringByReplacingOccurrencesOfString:@"dpkg: " withString:@""];
            [self writeToConsole:str atLevel:ZBLogLevelError];
        }
    }
}

- (void)writeToConsole:(NSString *)str atLevel:(ZBLogLevel)level {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIColor *color;
        UIFont *font;
        switch(level) {
            case ZBLogLevelDescript:
                color = [UIColor whiteColor];
                font = [UIFont fontWithName:@"CourierNewPSMT" size:12.0];
                break;
            case ZBLogLevelInfo:
                color = [UIColor whiteColor];
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
        
        [self->_consoleView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:str attributes:attrs]];
        
        if (self->_consoleView.text.length > 0 ) {
            NSRange bottom = NSMakeRange(self->_consoleView.text.length -1, 1);
            [self->_consoleView scrollRangeToVisible:bottom];
        }
    });
}

- (IBAction)complete:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)downloadStatusUpdate:(NSNotification *)notification {
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(downloadStatusUpdate:) withObject:notification waitUntilDone:NO];
        return;
    }
    else if ([notification.name isEqualToString:@"downloadStatusUpdate"])
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

@end
