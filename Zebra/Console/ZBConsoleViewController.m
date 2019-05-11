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
#import <Downloads/ZBDownloadManager.h>
#import <Packages/Helpers/ZBPackage.h>

@interface ZBConsoleViewController () {
    int stage;
    BOOL continueWithActions;
    NSArray *akton;
    BOOL needsIconCacheUpdate;
    BOOL needsRespring;
    NSMutableArray *installedIDs;
    NSMutableArray *bundlePaths;
}
@end

@implementation ZBConsoleViewController

@synthesize queue;

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setTitle:@"Console"];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [self.navigationItem setHidesBackButton:true animated:true];
    
    queue = [ZBQueue sharedInstance];
    stage = -1;
    continueWithActions = true;
    needsIconCacheUpdate = false;
    needsRespring = false;
    installedIDs = [NSMutableArray new];
    bundlePaths = [NSMutableArray new];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_externalInstall) {
        akton = @[@[@0], @[@"dpkg", @"-i", _externalFilePath]];
        [self performSelectorInBackground:@selector(performActions) withObject:NULL];
    }
    else if ([queue needsHyena]) {
        [self downloadPackages];
    }
    else {
        [self performSelectorInBackground:@selector(performActions) withObject:NULL];
    }
}

- (void)downloadPackages {
    NSArray *packages = [queue packagesToDownload];
    
    [self writeToConsole:@"Downloading Packages.\n" atLevel:ZBLogLevelInfo];
    ZBDownloadManager *downloadManager = [[ZBDownloadManager alloc] init];
    downloadManager.downloadDelegate = self;
    
    [downloadManager downloadPackages:packages];
}

- (void)performActions {
    [self performActions:NULL];
}

- (void)performActions:(NSArray *)debs {
    if (akton != NULL) {
        for (NSArray *command in akton) {
            if ([command count] == 1) {
                [self updateStatus:[command[0] intValue]];
            }
            else {
                if (![ZBAppDelegate needsSimulation]) {
                    for (int i = 2; i < [command count]; i++) {
                        NSString *packageID = command[i];
                        
                        if (stage == 1) {
                            BOOL update = [ZBPackage containsApp:packageID];
                            if (update) {
                                needsIconCacheUpdate = true;
                                [bundlePaths addObject:[ZBPackage pathForApplication:packageID]];
                            }
                            
                            if (!needsRespring) {
                                needsRespring = [ZBPackage containsTweak:packageID];
                            }
                        }
                        else {
                            [installedIDs addObject:packageID];
                        }
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
        }
        [self refreshLocalPackages];
    }
    else {
        if ([ZBAppDelegate needsSimulation]) {
            [self writeToConsole:@"Console actions are not available on the simulator\n" atLevel:ZBLogLevelWarning];
            [self refreshLocalPackages];
        }
        else if (continueWithActions) {
            NSArray *actions = [queue tasks:debs];
            
            for (NSArray *command in actions) {
                if ([command count] == 1) {
                    [self updateStatus:[command[0] intValue]];
                }
                else {
                    if (![ZBAppDelegate needsSimulation]) {
                        for (int i = 2; i < [command count]; i++) {
                            NSString *packageID = command[i];
                            if (stage == 1) {
                                BOOL update = [ZBPackage containsApp:packageID];
                                if (update) {
                                    needsIconCacheUpdate = true;
                                    [bundlePaths addObject:[ZBPackage pathForApplication:packageID]];
                                }
                                
                                if (!needsRespring) {
                                    needsRespring = [ZBPackage containsTweak:packageID];
                                }
                            }
                            else {
                                [installedIDs addObject:packageID];
                            }
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
            }
            [self refreshLocalPackages];
        }
        else {
            [self finishUp];
        }
    }
}

- (void)finishUp {
    [queue clearQueue];
    
    NSMutableArray *uicaches = [NSMutableArray new];
    if (![ZBAppDelegate needsSimulation]) {
        for (NSString *packageID in installedIDs) {
            BOOL update = [ZBPackage containsApp:packageID];
            if (update) {
                needsIconCacheUpdate = true;
                [uicaches addObject:packageID];
            }
            
            if (!needsRespring) {
                needsRespring = [ZBPackage containsTweak:packageID] ? true : needsRespring;
            }
        }
    }
    
    if (needsIconCacheUpdate) {
        [self writeToConsole:@"Updating icon cache...\n" atLevel:ZBLogLevelInfo];
        NSMutableArray *arguments = [NSMutableArray new];
        if ([uicaches count] + [bundlePaths count] > 1) {
            [arguments addObject:@"-a"];
            [self writeToConsole:@"This may take awhile and Zebra may crash. It is okay if it does.\n" atLevel:ZBLogLevelWarning];
        }
        else {
            [arguments addObject:@"-p"];
            for (NSString *packageID in uicaches) {
                if ([packageID isEqualToString:@"-p"]) continue;
                
                NSString *bundlePath = [ZBPackage pathForApplication:packageID];
                if (bundlePath != NULL) [bundlePaths addObject:bundlePath];
            }
            [arguments addObjectsFromArray:bundlePaths];
        }
        
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/bin/uicache"];
        [task setArguments:arguments];
        
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
    
    [self removeAllDebs];
    [self updateStatus:4];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_completeButton.hidden = false;
        
        if (self->needsRespring) {
            UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(goodbye)];
            self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
            self.navigationItem.rightBarButtonItem = closeButton;
            
            [self->_completeButton setTitle:@"Restart SpringBoard" forState:UIControlStateNormal];
            [self->_completeButton addTarget:self action:@selector(restartSpringBoard) forControlEvents:UIControlEventTouchUpInside];
        }
        else {
            [self->_completeButton setTitle:@"Done" forState:UIControlStateNormal];
        }
    });
}

- (void)goodbye {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)restartSpringBoard {
    //Bye!
    NSTask *task = [[NSTask alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:@"/chimera"]) {
        [task setLaunchPath:@"/usr/bin/sbreload"];
    }
    else {
        [task setLaunchPath:@"/usr/bin/killall"];
        [task setArguments:@[@"-9", @"backboardd"]];
    }
    
    [task launch];
}

- (void)refreshLocalPackages {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    [databaseManager setDatabaseDelegate:self];
    [databaseManager justImportLocal];
}

- (void)removeAllDebs {
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:[ZBAppDelegate debsLocation]];
    NSString *file;

    while (file = [enumerator nextObject]) {
        NSError *error = nil;
        BOOL result = [[NSFileManager defaultManager] removeItemAtPath:[[ZBAppDelegate debsLocation] stringByAppendingPathComponent:file] error:&error];

        if (!result && error) {
            NSLog(@"Error while removing %@: %@", file, error);
        }
    }
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

#pragma mark - Hyena Delegate

- (void)predator:(nonnull ZBDownloadManager *)downloadManager finishedAllDownloads:(nonnull NSDictionary *)filenames {
    NSArray *debs = [filenames objectForKey:@"debs"];
    
    [self performSelectorInBackground:@selector(performActions:) withObject:debs];
}

- (void)predator:(nonnull ZBDownloadManager *)downloadManager startedDownloadForFile:(nonnull NSString *)filename {
    [self writeToConsole:[NSString stringWithFormat:@"Downloading %@\n", filename] atLevel:ZBLogLevelDescript];
}

- (void)predator:(nonnull ZBDownloadManager *)downloadManager finishedDownloadForFile:(nonnull NSString *)filename withError:(NSError * _Nullable)error {
    if (error != NULL) {
        continueWithActions = false;
        [self writeToConsole:error.localizedDescription atLevel:ZBLogLevelError];
    }
    else {
        [self writeToConsole:[NSString stringWithFormat:@"Done %@\n", filename] atLevel:ZBLogLevelDescript];
    }
}

#pragma mark - Database Delegate

- (void)databaseStartedUpdate {
    [self writeToConsole:@"Importing local packages.\n" atLevel:ZBLogLevelInfo];
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    [self writeToConsole:@"Finished importing local packages.\n" atLevel:ZBLogLevelInfo];
    
    NSLog(@"[Zebra] %d updates available.", packageUpdates);
    
    ZBTabBarController *tabController = (ZBTabBarController *)[[[UIApplication sharedApplication] delegate] window].rootViewController;
    [tabController setPackageUpdateBadgeValue:packageUpdates];
    
    [self finishUp];
}

@end
