//
//  ZBConsoleViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/6/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBConsoleViewController.h"
#import <ZBLog.h>
#import <NSTask.h>
#import <ZBDevice.h>
#import <Queue/ZBQueue.h>
#import <Database/ZBDatabaseManager.h>
#import <ZBAppDelegate.h>
#import <ZBTabBarController.h>
#import <Downloads/ZBDownloadManager.h>
#import <Packages/Helpers/ZBPackage.h>
@import LNPopupController;

typedef enum {
    ZBStageInstall = 0,
    ZBStageRemove,
    ZBStageReinstall,
    ZBStageUpgrade,
    ZBStageDone
} ZBStage;

@interface ZBConsoleViewController () {
    ZBStage stage;
    BOOL continueWithActions;
    BOOL needsIconCacheUpdate;
    BOOL needsRespring;
    BOOL hasZebraUpdated;
    BOOL preventCancel;
    NSArray *akton;
    NSMutableArray *installedIDs;
    NSMutableArray *bundlePaths;
    NSMutableDictionary <NSString *, NSNumber *> *downloadingMap;
    ZBDownloadManager *downloadManager;
}
@end

@implementation ZBConsoleViewController

@synthesize queue;

- (void)viewDidLoad {
    [super viewDidLoad];
    queue = [ZBQueue sharedInstance];
    self.title = @"Console";
    stage = -1;
    continueWithActions = YES;
    needsIconCacheUpdate = NO;
    needsRespring = NO;
    preventCancel = NO;
    installedIDs = [NSMutableArray new];
    bundlePaths = [NSMutableArray new];
    downloadingMap = [NSMutableDictionary new];
    _progressView.progress = 0;
    _progressView.hidden = YES;
    _progressText.text = nil;
    _progressText.hidden = YES;
    [self updateCancelOrCloseButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_externalInstall) {
        akton = @[@[@0], @[@"apt", @"install", @"-y", _externalFilePath]];
        [self performSelectorInBackground:@selector(performActions) withObject:NULL];
    } else if ([queue needsHyena]) {
        _progressView.hidden = NO;
        _progressText.hidden = NO;
        [self downloadPackages];
    } else {
        [self performSelectorInBackground:@selector(performActions) withObject:NULL];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)downloadPackages {
    NSArray *packages = [queue packagesToDownload];
    [self writeToConsole:@"Downloading Packages...\n" atLevel:ZBLogLevelInfo];
    downloadManager = [[ZBDownloadManager alloc] init];
    downloadManager.downloadDelegate = self;
    [downloadManager downloadPackages:packages];
}

- (void)performActions {
    [self performActions:NULL];
}

- (BOOL)isValidPackageID:(NSString *)packageID {
    return ![packageID hasPrefix:@"-"] && ![packageID isEqualToString:@"install"] && ![packageID isEqualToString:@"remove"];
}

- (void)performActions:(NSArray *)debs {
    if (akton != NULL) {
        ZBLog(@"[Zebra] Actions: %@", akton);
        for (NSArray *command in akton) {
            if ([command count] == 1) {
                [self updateStatus:[command[0] intValue]];
            } else {
                for (int i = 3; i < [command count]; ++i) {
                    NSString *packageID = command[i];
                    if (![self isValidPackageID:packageID]) {
                        continue;
                    }
                    
                    if (stage != ZBStageDone) {
                        if (!needsIconCacheUpdate && [ZBPackage containsApp:packageID]) {
                            needsIconCacheUpdate = YES;
                            NSString *path = [ZBPackage pathForApplication:packageID];
                            if (path) {
                                [bundlePaths addObject:path];
                            }
                        }
                        
                        if (!needsRespring) {
                            needsRespring = [ZBPackage containsRespringable:packageID];
                        }
                    }
                    if (stage != ZBStageDone && stage != ZBStageRemove) {
                        [installedIDs addObject:packageID];
                    }
                }
                
                if (![ZBDevice needsSimulation]) {
                    NSTask *task = [[NSTask alloc] init];
                    [task setLaunchPath:@"/usr/libexec/zebra/supersling"];
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
    } else {
        if (continueWithActions) {
            _progressText.text = @"Performing actions...";
            NSArray *actions = [queue tasks:debs];
            ZBLog(@"[Zebra] Actions: %@", actions);
            
            for (NSArray *command in actions) {
                if ([command count] == 1) {
                    [self updateStatus:[command[0] intValue]];
                } else {
                    for (int i = 3; i < [command count]; ++i) {
                        NSString *packageID = command[i];
                        if (![self isValidPackageID:packageID]) {
                            continue;
                        }
                        if (stage != ZBStageDone) {
                            if (!needsIconCacheUpdate && [ZBPackage containsApp:packageID]) {
                                needsIconCacheUpdate = YES;
                                NSString *path = [ZBPackage pathForApplication:packageID];
                                if (path) {
                                    [bundlePaths addObject:path];
                                }
                            }
                            
                            if (!needsRespring) {
                                needsRespring = [ZBPackage containsRespringable:packageID];
                            }
                        }
                        if (stage != ZBStageDone && stage != ZBStageRemove) {
                            [installedIDs addObject:packageID];
                        }
                    }
                    
                    if (![ZBDevice needsSimulation]) {
                        NSTask *task = [[NSTask alloc] init];
                        [task setLaunchPath:@"/usr/libexec/zebra/supersling"];
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
        } else {
            [self finishUp];
        }
    }
}

- (void)finishUp {
    [queue clearQueue];
    [downloadingMap removeAllObjects];
    _progressView.hidden = YES;
    
    NSMutableArray *uicaches = [NSMutableArray new];
    for (NSString *packageID in installedIDs) {
        BOOL update = [ZBPackage containsApp:packageID];
        if (update) {
            needsIconCacheUpdate = YES;
            NSString *truePackageID = packageID;
            if ([truePackageID hasSuffix:@".deb"]) {
                // Transform deb-path-like packageID into actual package ID for checking to prevent duplicates
                truePackageID = [[packageID lastPathComponent] stringByDeletingPathExtension];
                // ex., com.xxx.yyy_1.0.0_iphoneos_arm.deb
                NSRange underscoreRange = [truePackageID rangeOfString:@"_" options:NSLiteralSearch];
                if (underscoreRange.location != NSNotFound) {
                    truePackageID = [truePackageID substringToIndex:underscoreRange.location];
                    if (!self->hasZebraUpdated && [truePackageID isEqualToString:@"xyz.willy.zebra"]) {
                        self->hasZebraUpdated = YES;
                    }
                }
                if ([uicaches containsObject:truePackageID])
                    continue;
            }
            if (![uicaches containsObject:truePackageID])
                [uicaches addObject:truePackageID];
        }
        
        if (!needsRespring) {
            needsRespring = [ZBPackage containsRespringable:packageID] ? YES : needsRespring;
        }
    }
    
    [self removeAllDebs];
    
    if (needsIconCacheUpdate) {
        [self writeToConsole:@"Updating icon cache...\n" atLevel:ZBLogLevelInfo];
        NSMutableArray *arguments = [NSMutableArray new];
        if ([uicaches count] + [bundlePaths count] > 1) {
            [arguments addObject:@"-a"];
            [self writeToConsole:@"This may take awhile and Zebra may crash. It is okay if it does.\n" atLevel:ZBLogLevelWarning];
        } else {
            [arguments addObject:@"-p"];
            for (NSString *packageID in uicaches) {
                if ([packageID isEqualToString:[ZBAppDelegate bundleID]])
                    continue;
                NSString *bundlePath = [ZBPackage pathForApplication:packageID];
                if (bundlePath != NULL)
                    [bundlePaths addObject:bundlePath];
            }
            [arguments addObjectsFromArray:bundlePaths];
        }
        
        if (![ZBDevice needsSimulation]) {
            [ZBDevice uicache:arguments observer:self];
        } else {
            [self writeToConsole:@"uicache is not available on the simulator\n" atLevel:ZBLogLevelWarning];
        }
    }
    
    preventCancel = NO;
    [self updateStatus:ZBStageDone];
    [self updateCompleteButton];
    [self updateCancelOrCloseButton];
}

- (void)updateCompleteButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_completeButton.hidden = NO;
        self->_progressText.text = nil;
        if (self->hasZebraUpdated) {
            [self->_completeButton setTitle:@"Close Zebra" forState:UIControlStateNormal];
            [self->_completeButton addTarget:self action:@selector(closeZebra) forControlEvents:UIControlEventTouchUpInside];
        } else if (self->needsRespring) {
            [self->_completeButton setTitle:@"Restart SpringBoard" forState:UIControlStateNormal];
            [self->_completeButton addTarget:self action:@selector(restartSpringBoard) forControlEvents:UIControlEventTouchUpInside];
        } else {
            [self->_completeButton setTitle:@"Done" forState:UIControlStateNormal];
        }
    });
}

- (void)cancel {
    if (preventCancel) {
        return;
    }
    [downloadManager stopAllDownloads];
    [downloadingMap removeAllObjects];
    _progressView.progress = 1;
    _progressView.hidden = YES;
    _progressText.text = nil;
    _progressText.hidden = YES;
    [queue clearQueue];
    [self removeAllDebs];
    [self updateCancelOrCloseButton];
}

- (void)closeZebra {
    if (![ZBDevice needsSimulation]) {
        [ZBDevice uicache:@[@"-p", @"/Applications/Zebra.app"] observer:self];
    }
    exit(1); // Correct?
}

- (void)restartSpringBoard {
    [ZBDevice sbreload];
}

- (void)refreshLocalPackages {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    [databaseManager addDatabaseDelegate:self];
    [databaseManager importLocalPackagesAndCheckForUpdates:YES sender:self];
}

- (void)removeAllDebs {
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:[ZBAppDelegate debsLocation]];
    NSString *file;

    while (file = [enumerator nextObject]) {
        NSError *error = nil;
        BOOL result = [[NSFileManager defaultManager] removeItemAtPath:[[ZBAppDelegate debsLocation] stringByAppendingPathComponent:file] error:&error];

        if (!result && error) {
            NSLog(@"[Zebra] Error while removing %@: %@", file, error);
        }
    }
}

- (void)updateStatus:(ZBStage)s {
    stage = s;
    switch (s) {
        case ZBStageInstall:
            [self setTitle:@"Installing"];
            [self writeToConsole:@"Installing Packages...\n" atLevel:ZBLogLevelInfo];
            break;
        case ZBStageRemove:
            [self setTitle:@"Removing"];
            [self writeToConsole:@"Removing Packages...\n" atLevel:ZBLogLevelInfo];
            break;
        case ZBStageReinstall:
            [self setTitle:@"Reinstalling"];
            [self writeToConsole:@"Reinstalling Packages...\n" atLevel:ZBLogLevelInfo];
            break;
        case ZBStageUpgrade:
            [self setTitle:@"Upgrading"];
            [self writeToConsole:@"Upgrading Packages...\n" atLevel:ZBLogLevelInfo];
            break;
        case ZBStageDone:
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

    if (data.length) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self writeToConsole:str atLevel:ZBLogLevelDescript];
    }
}

- (void)receivedErrorData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];

    if (data.length) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([str rangeOfString:@"warning"].location != NSNotFound) {
            str = [str stringByReplacingOccurrencesOfString:@"dpkg: " withString:@""];
            [self writeToConsole:str atLevel:ZBLogLevelWarning];
        } else if ([str rangeOfString:@"error"].location != NSNotFound) {
            str = [str stringByReplacingOccurrencesOfString:@"dpkg: " withString:@""];
            [self writeToConsole:str atLevel:ZBLogLevelError];
        }
    }
}

- (void)writeToConsole:(NSString *)str atLevel:(ZBLogLevel)level {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIColor *color;
        UIFont *font;
        switch (level) {
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

        if (self->_consoleView.text.length) {
            NSRange bottom = NSMakeRange(self->_consoleView.text.length - 1, 1);
            [self->_consoleView scrollRangeToVisible:bottom];
        }
    });
}

- (void)clearConsole {
    _consoleView.text = nil;
}

- (void)updateCancelOrCloseButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->preventCancel) {
            self.cancelOrCloseButton.hidden = YES;
        } else if (self->stage == ZBStageDone) {
            self.cancelOrCloseButton.hidden = self->hasZebraUpdated;
            [self.cancelOrCloseButton setTitle:@"Close" forState:UIControlStateNormal];
        } else {
            self.cancelOrCloseButton.hidden = NO;
            [self.cancelOrCloseButton setTitle:@"Cancel" forState:UIControlStateNormal];
        }
    });
}

- (void)close {
    [self clearConsole];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)complete:(id)sender {
    [self close];
}

- (IBAction)cancelOrClose:(id)sender {
    if (stage == ZBStageDone) {
        [self close];
    } else {
        [self cancel];
    }
}

#pragma mark - Hyena Delegate

- (void)predator:(nonnull ZBDownloadManager *)downloadManager progressUpdate:(CGFloat)progress forPackage:(ZBPackage *)package {
    downloadingMap[package.identifier] = @(progress);
    CGFloat totalProgress = 0;
    for (NSString *packageID in downloadingMap) {
        totalProgress += [downloadingMap[packageID] doubleValue];
    }
    totalProgress /= downloadingMap.count;
    [_progressView setProgress:totalProgress animated:YES];
    _progressText.text = [NSString stringWithFormat:@"Downloading: %.1f%%", totalProgress * 100];
}

- (void)predator:(nonnull ZBDownloadManager *)downloadManager finishedAllDownloads:(NSDictionary *)filenames {
    _progressText.text = nil;
    if (filenames.count) {
        NSArray *debs = [filenames objectForKey:@"debs"];
        [self performSelectorInBackground:@selector(performActions:) withObject:debs];
    } else {
        continueWithActions = NO;
        [self cancel];
        [self writeToConsole:@"Nothing has been downloaded.\n" atLevel:ZBLogLevelWarning];
        [self updateStatus:ZBStageDone];
        [self updateCompleteButton];
    }
    preventCancel = YES;
    self.cancelOrCloseButton.hidden = YES;
}

- (void)predator:(nonnull ZBDownloadManager *)downloadManager startedDownloadForFile:(nonnull NSString *)filename {
    [self writeToConsole:[NSString stringWithFormat:@"Downloading %@\n", filename] atLevel:ZBLogLevelDescript];
}

- (void)predator:(nonnull ZBDownloadManager *)downloadManager finishedDownloadForFile:(NSString *_Nullable)filename withError:(NSError * _Nullable)error {
    if (error != NULL) {
        continueWithActions = NO;
        [self writeToConsole:[error.localizedDescription stringByAppendingString:@"\n"] atLevel:ZBLogLevelError];
    } else if (filename) {
        [self writeToConsole:[NSString stringWithFormat:@"Done %@\n", filename] atLevel:ZBLogLevelDescript];
    }
}

#pragma mark - Database Delegate

- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level {
    [self writeToConsole:status atLevel:level];
}

- (void)databaseStartedUpdate {
    [self writeToConsole:@"Importing local packages.\n" atLevel:ZBLogLevelInfo];
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    [self writeToConsole:@"Finished importing local packages.\n" atLevel:ZBLogLevelInfo];
    ZBLog(@"[Zebra] %d updates available.", packageUpdates);
    if (packageUpdates != -1) {
        [[ZBAppDelegate tabBarController] setPackageUpdateBadgeValue:packageUpdates];
    }
    [self finishUp];
}

@end
