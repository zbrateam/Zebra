//
//  ZBConsoleViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/6/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBConsoleViewController.h"
#import "ZBStage.h"

#import <Database/ZBDatabaseManager.h>
#import <Downloads/ZBDownloadManager.h>
#import <Tabs/ZBTabBarController.h>
#import <Tabs/Packages/Helpers/ZBPackage.h>
#import <Queue/ZBQueue.h>
#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <ZBLog.h>
#import <ZBSettings.h>
#import <Extensions/UIColor+GlobalColors.h>
#import <Theme/ZBThemeManager.h>
#import <Extensions/UIFont+Zebra.h>

#include <sysexits.h>

@import FirebaseCrashlytics;
@import LNPopupController;

@interface ZBConsoleViewController () {
    NSMutableArray *applicationBundlePaths;
    NSMutableArray *installedPackageIdentifiers;
    NSMutableDictionary <NSString *, NSNumber *> *downloadMap;
    NSString *localInstallPath;
    ZBDownloadManager *downloadManager;
    ZBQueue *queue;
    ZBStage currentStage;
    BOOL downloadFailed;
    BOOL respringRequired;
    BOOL suppressCancel;
    BOOL updateIconCache;
    BOOL zebraRestartRequired;
    int autoFinishDelay;
    BOOL blockDatabaseMessages;
}
@property (strong, nonatomic) IBOutlet UIButton *completeButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelOrCloseButton;
@property (strong, nonatomic) IBOutlet UILabel *progressText;
@property (strong, nonatomic) IBOutlet UIView *progressTextView;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UITextView *consoleView;
@end

@implementation ZBConsoleViewController

@synthesize completeButton;
@synthesize cancelOrCloseButton;
@synthesize progressText;
@synthesize progressTextView;
@synthesize progressView;
@synthesize consoleView;

#pragma mark - Initializers

- (id)init {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"consoleViewController"];
    
    if (self) {
        applicationBundlePaths = [NSMutableArray new];
        queue = [ZBQueue sharedQueue];
        if ([queue needsToDownloadPackages]) {
            downloadManager = [[ZBDownloadManager alloc] initWithDownloadDelegate:self];
            downloadMap = [NSMutableDictionary new];
        }
        installedPackageIdentifiers = [NSMutableArray new];
        respringRequired = NO;
        updateIconCache = NO;
        blockDatabaseMessages = NO;
        autoFinishDelay = 3;
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Console", @"");
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    NSError *error = NULL;
    if ([ZBDevice isSlingshotBroken:&error]) {
        [ZBAppDelegate sendAlertFrom:self message:error.localizedDescription];
    }
    
    [self setupView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (currentStage == -1) { //Only run the process once per console cycle
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        });
        
        if (downloadManager) {
            [self updateStage:ZBStageDownload];
            [downloadManager downloadPackages:[queue packagesToDownload]];
        }
        else {
            [self performSelectorInBackground:@selector(performTasks) withObject:NULL];
        }
    }
}

- (void)setupView {
    currentStage = -1;
    downloadFailed = NO;
    updateIconCache = NO;
    respringRequired = NO;
    suppressCancel = NO;
    zebraRestartRequired = NO;
    installedPackageIdentifiers = [NSMutableArray new];
    applicationBundlePaths = [NSMutableArray new];
    downloadMap = [NSMutableDictionary new];
    
    [self updateProgress:0.0];
    progressTextView.layer.cornerRadius = 3.0;
    progressText.layer.masksToBounds = YES;
    [self updateProgressText:nil];
    [self setProgressViewHidden:YES];
    self.progressView.progressTintColor = [UIColor accentColor];
    
    ZBAccentColor color = [ZBSettings accentColor];
    ZBInterfaceStyle style = [ZBSettings interfaceStyle];
    if (color == ZBAccentColorMonochrome) {
        //Flip the colors for readability
        self.completeButton.backgroundColor = [UIColor whiteColor];
        [self.completeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    else {
        self.completeButton.backgroundColor = [ZBThemeManager getAccentColor:color forInterfaceStyle:style] ?: [UIColor systemBlueColor];
    }
    
    [self setProgressTextHidden:YES];
    [self updateCancelOrCloseButton];
    
    [self.navigationItem setHidesBackButton:YES];
    
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *app = [self.navigationController.navigationBar.standardAppearance copy];
        app.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        app.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
        self.navigationController.navigationBar.standardAppearance = app;
        self.navigationController.navigationBar.scrollEdgeAppearance = app;
        self.navigationController.navigationBar.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    else {
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
    }
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    [[[[ZBAppDelegate tabBarController] popupContentView] popupInteractionGestureRecognizer] setDelegate:self];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Performing Tasks

- (void)performTasks {
    if (downloadFailed) {
        [self writeToConsole:[NSString stringWithFormat:@"\n%@\n\n%@", NSLocalizedString(@"One or more packages failed to download.", @""), NSLocalizedString(@"Click \"Return to Queue\" to return to the Queue and retry the download.", @"")] atLevel:ZBLogLevelDescript];
        [self finishTasks];
    }
    else {
        NSArray *actions = [queue tasksToPerform];
        BOOL zebraModification = queue.zebraPath || queue.removingZebra;
        if ([actions count] == 0 && !zebraModification) {
            [self writeToConsole:NSLocalizedString(@"There are no actions to perform", @"") atLevel:ZBLogLevelDescript];
        }
        else {
            [self setProgressTextHidden:NO];
            [self updateProgressText:NSLocalizedString(@"Performing Actions...", @"")];
            
            for (ZBPackage *package in [queue packagesToInstall]) {
                [installedPackageIdentifiers addObject:[package identifier]];
            }
            
            for (NSArray *action in actions) {
                if ([action count] == 1) {
                    [self updateStage:(ZBStage)[action[0] intValue]];
                }
                else {
                    if (currentStage == ZBStageRemove) {
                        for (int i = COMMAND_START; i < action.count; ++i) {
                            NSString *packageID = action[i];
                            if (![self isValidPackageID:packageID]) continue;
                            
                            NSString *bundlePath = [ZBPackage applicationBundlePathForIdentifier:packageID];
                            if (bundlePath) {
                                ZBLog(@"[Zebra] %@ has an app bundle", bundlePath);
                                updateIconCache = YES;
                                [applicationBundlePaths addObject:bundlePath];
                            }

                            if (!respringRequired) {
                                respringRequired = [ZBPackage respringRequiredFor:packageID];
                                ZBLog(@"[Zebra] Respring Required? %@", respringRequired ? @"Yes" : @"No");
                            }
                        }
                    }
                    
                    if (![ZBDevice needsSimulation]) {
                        ZBLog(@"[Zebra] Executing commands...");
                        ZBCommand *command = [[ZBCommand alloc] initWithCommand:[ZBDevice packageManagementBinary] arguments:action root:YES delegate:self];
                        [command execute];
                    }
                    else {
                        [self writeToConsole:NSLocalizedString(@"This device is simulated, here are the packages that would be modified in this stage:", @"") atLevel:ZBLogLevelWarning];
                        for (int i = COMMAND_START; i < [action count]; ++i) {
                            NSString *packageID = action[i];
                            if (![self isValidPackageID:packageID]) continue;
                            [self writeToConsole:[packageID lastPathComponent] atLevel:ZBLogLevelDescript];
                        }
                    }
                }
            }
            
            for (int i = 0; i < installedPackageIdentifiers.count; ++i) {
                NSString *packageIdentifier = installedPackageIdentifiers[i];
                NSString *bundlePath = [ZBPackage applicationBundlePathForIdentifier:packageIdentifier];
                if (bundlePath && ![applicationBundlePaths containsObject:bundlePath]) {
                    updateIconCache = YES;
                    [applicationBundlePaths addObject:bundlePath];
                }
                
                if (!respringRequired) {
                    respringRequired  = [ZBPackage respringRequiredFor:packageIdentifier];
                }
            }
            
            if (zebraModification) { //Zebra should be the last thing installed so here is our chance to install it.
                if ([queue locatePackageID:@"xyz.willy.zebra"] == ZBQueueTypeUpgrade) {
                    NSLog(@"[Zebra] Zebra located in upgrade queue, removing app badge");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
                    });
                }
                zebraRestartRequired = YES;
                
                ZBLog(@"[Zebra] modifying zebra...");
                if (queue.removingZebra) {
                    [self postStatusUpdate:NSLocalizedString(@"Removing Zebra...", @"") atLevel:ZBLogLevelInfo];
                    [self postStatusUpdate:@"Goodbye forever :(" atLevel:ZBLogLevelDescript];
                }
                else {
                    [self postStatusUpdate:NSLocalizedString(@"Installing Zebra...", @"") atLevel:ZBLogLevelInfo];
                }
                
                NSString *path = queue.zebraPath;
                
                NSArray *baseCommand;
                if ([[ZBDevice packageManagementBinary] isEqualToString:@"/usr/bin/dpkg"]) {
                    baseCommand = @[queue.removingZebra ? @"-r" : @"-i", queue.zebraPath ? path : @"xyz.willy.zebra"];
                }
                else {
                    baseCommand = @[@"-yqf", @"--allow-downgrades", @"-oApt::Get::HideAutoRemove=true", @"-oquiet::NoProgress=true", @"-oquiet::NoStatistic=true", queue.removingZebra ? @"remove" : @"install", queue.zebraPath ? path : @"xyz.willy.zebra"];
                }
                
                if (![ZBDevice needsSimulation]) {
                    [ZBCommand execute:[ZBDevice packageManagementBinary] withArguments:baseCommand asRoot:YES];
                }
                else {
                    [self writeToConsole:NSLocalizedString(@"This device is simulated, here are the packages that would be modified in this stage:", @"") atLevel:ZBLogLevelWarning];
                    queue.removingZebra ? [self writeToConsole:@"xyz.willy.zebra" atLevel:ZBLogLevelDescript] : [self writeToConsole:[path lastPathComponent] atLevel:ZBLogLevelDescript];
                }
            }
            
            ZBLog(@"[Zebra] Restart required? %@.", zebraRestartRequired ? @"Yes" : @"No");
            if (!zebraRestartRequired && updateIconCache) {
                ZBLog(@"[Zebra] Updating Icon Caches");
                [self updateIconCaches];
            }
        }
        [self refreshLocalPackages];
        [self removeAllDebs];
        [self finishTasks];
    }
}

- (void)finishTasks {
    ZBLog(@"[Zebra] Finishing tasks");
    [downloadMap removeAllObjects];
    [applicationBundlePaths removeAllObjects];
    
    NSMutableArray *wishlist = [[ZBSettings wishlist] mutableCopy];
    [wishlist removeObjectsInArray:installedPackageIdentifiers];
    
    [installedPackageIdentifiers removeAllObjects];
    
    [self updateStage:ZBStageFinished];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    });
}

#pragma mark - Button Actions

- (void)cancel {
    if (suppressCancel)
        return;
    
    [downloadManager stopAllDownloads];
    [downloadMap removeAllObjects];
    [self updateProgress:1.0];
    [self setProgressViewHidden:YES];
    [self updateProgressText:nil];
    [self setProgressTextHidden:YES];
    [self removeAllDebs];
    [self updateStage:ZBStageFinished];
}

- (void)close {
    [queue clear];
    [[self navigationController] popToRootViewControllerAnimated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ZBUpdateNavigationButtons" object:nil];
}

- (IBAction)cancelOrClose:(id)sender {
    if (currentStage == ZBStageFinished) {
        [self close];
    } else {
        [self cancel];
    }
}

- (void)returnToQueue {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)closeZebra {
    [ZBDevice exitZebraAfter:3];
    if (![ZBDevice needsSimulation]) {
        if (applicationBundlePaths.count > 1) {
            [self updateIconCaches];
        } else {
            [ZBDevice uicache:@[@"/Applications/Zebra.app"]];
        }
    }
}

- (void)restartSpringBoard {
    if (![ZBDevice needsSimulation]) {
        [ZBDevice restartSpringBoard];
    } else {
        [self close];
    }
}

#pragma mark - Helper Methods

- (void)updateIconCaches {
    [self writeToConsole:NSLocalizedString(@"Updating icon cache asynchronously...", @"") atLevel:ZBLogLevelInfo];
    
    if (![ZBDevice needsSimulation]) {
        [ZBDevice uicache:applicationBundlePaths];
    } else {
        [self writeToConsole:NSLocalizedString(@"uicache is not available on the simulator", @"") atLevel:ZBLogLevelWarning];
    }
}

- (void)updateStage:(ZBStage)stage {
    currentStage = stage;
    suppressCancel = stage != ZBStageDownload && stage != ZBStageFinished;
    
    switch (stage) {
        case ZBStageDownload:
            [self updateTitle:NSLocalizedString(@"Downloading", @"")];
            [self writeToConsole:NSLocalizedString(@"Downloading Packages...", @"") atLevel:ZBLogLevelInfo];
            
            [self setProgressTextHidden:NO];
            [self setProgressViewHidden:NO];
            break;
        case ZBStageInstall:
            [self updateTitle:NSLocalizedString(@"Installing", @"")];
            [self writeToConsole:NSLocalizedString(@"Installing Packages...", @"") atLevel:ZBLogLevelInfo];
            break;
        case ZBStageRemove:
            [self updateTitle:NSLocalizedString(@"Removing", @"")];
            [self writeToConsole:NSLocalizedString(@"Removing Packages...", @"") atLevel:ZBLogLevelInfo];
            break;
        case ZBStageReinstall:
            [self updateTitle:NSLocalizedString(@"Reinstalling", @"")];
            [self writeToConsole:NSLocalizedString(@"Reinstalling Packages...", @"") atLevel:ZBLogLevelInfo];
            break;
        case ZBStageUpgrade:
            [self updateTitle:NSLocalizedString(@"Upgrading", @"")];
            [self writeToConsole:NSLocalizedString(@"Upgrading Packages...", @"") atLevel:ZBLogLevelInfo];
            break;
        case ZBStageFinished:
            [self updateTitle:NSLocalizedString(@"Complete", @"")];
            [self writeToConsole:NSLocalizedString(@"Finished!", @"") atLevel:ZBLogLevelInfo];
            [self updateCompleteButton];
            break;
        default:
            break;
    }
    
    [self setProgressViewHidden:stage != ZBStageDownload];
    [self updateCancelOrCloseButton];
}

- (BOOL)isValidPackageID:(NSString *)packageID {
    return ![packageID hasPrefix:@"-"] && ![packageID isEqualToString:@"install"] && ![packageID isEqualToString:@"remove"];
}

- (void)refreshLocalPackages {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    [databaseManager addDatabaseDelegate:self];
    [databaseManager importLocalPackagesAndCheckForUpdates:YES sender:self];
    [databaseManager removeDatabaseDelegate:self];
}

- (void)removeAllDebs {
    ZBLog(@"[Zebra] Removing all debs");
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

#pragma mark - UI Updates

- (void)setProgressViewHidden:(BOOL)hidden {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->progressView.hidden = hidden;
    });
}

- (void)setProgressTextHidden:(BOOL)hidden {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->progressText.hidden = hidden;
    });
}

- (void)updateProgress:(CGFloat)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->progressView setProgress:progress animated:YES];
    });
}

- (void)updateProgressText:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->progressText.text = text;
    });
}

- (void)updateTitle:(NSString *)title {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setTitle:[NSString stringWithFormat:@" %@ ", title]];
    });
}

- (void)writeToConsole:(NSString *)str atLevel:(ZBLogLevel)level {
    if (str == nil)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIColor *color;
        UIFont *font;
        switch (level) {
            case ZBLogLevelDescript:
                color = [UIColor whiteColor];
                font = UIFont.monospaceFont;
                break;
            case ZBLogLevelInfo:
                color = [UIColor whiteColor];
                font = UIFont.boldMonospaceFont;
                break;
            case ZBLogLevelError:
                color = [UIColor redColor];
                font = UIFont.boldMonospaceFont;
                break;
            case ZBLogLevelWarning:
                color = [UIColor yellowColor];
                font = UIFont.monospaceFont;
                break;
        }

        NSDictionary *attrs = @{ NSForegroundColorAttributeName: color, NSFontAttributeName: font };
        
        //Adds a newline if there is not already one
        NSString *string = [str copy];
        if (![string hasSuffix:@"\n"]) {
            string = [str stringByAppendingString:@"\n"];
        }
        
        if (string == nil) {
            return;
        }
        
        [self->consoleView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:string attributes:attrs]];

        if (self->consoleView.text.length) {
            NSRange bottom = NSMakeRange(self->consoleView.text.length - 1, 1);
            [self->consoleView scrollRangeToVisible:bottom];
        }
    });
}

- (void)clearConsole {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->consoleView.text = nil;
    });
}

- (void)updateCancelOrCloseButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->suppressCancel) {
            self.cancelOrCloseButton.enabled = NO;
        }
        else if (self->currentStage == ZBStageFinished) {
            self.cancelOrCloseButton.enabled = !self->zebraRestartRequired;
            self.cancelOrCloseButton.title = NSLocalizedString(@"Close", @"");
        }
        else {
            self.cancelOrCloseButton.enabled = YES;
            self.cancelOrCloseButton.title = NSLocalizedString(@"Cancel", @"");
        }
        
        if (self.cancelOrCloseButton.enabled) {
            self.cancelOrCloseButton.tintColor = [UIColor whiteColor];
        }
        else {
            self.cancelOrCloseButton.tintColor = [UIColor clearColor];
        }
    });
}

- (void)updateCompleteButton {
    ZBLog(@"[Zebra] Final statuses: downloadFailed(%d), respringRequired(%d), zebraRestartRequired(%d)", downloadFailed, respringRequired, zebraRestartRequired);
    if ([ZBSettings wantsFinishAutomatically]) { // automatically finish after 3 secs
        dispatch_block_t finishBlock = nil;

        if (self->downloadFailed) {
            [self updateProgressText:NSLocalizedString(@"Returning to Queue...", @"")];
            finishBlock = ^{
                [self updateProgressText:nil];
                [self returnToQueue];
            };
        }
        else if (self->respringRequired) {
            [self updateProgressText:NSLocalizedString(@"Restarting SpringBoard...", @"")];
            finishBlock = ^{
                [self updateProgressText:nil];
                [self restartSpringBoard];
            };
        }
        else if (self->zebraRestartRequired) {
            [self updateProgressText:NSLocalizedString(@"Closing Zebra...", @"")];
            finishBlock = ^{
                [self updateProgressText:nil];
                [self closeZebra];
            };
        }
        else {
            [self updateProgressText:NSLocalizedString(@"Done...", @"")];
            finishBlock = ^{
                [self updateProgressText:nil];
                [self close];
            };
        }

        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self->autoFinishDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), finishBlock);
    } else { // manual finish
        dispatch_async(dispatch_get_main_queue(), ^{
            self->completeButton.hidden = NO;
            [self updateProgressText:nil];
            if (self->downloadFailed) {
                [self->completeButton setTitle:NSLocalizedString(@"Return to Queue", @"") forState:UIControlStateNormal];
                [self->completeButton addTarget:self action:@selector(returnToQueue) forControlEvents:UIControlEventTouchUpInside];
            }
            else if (self->respringRequired) {
                [self->completeButton setTitle:NSLocalizedString(@"Restart SpringBoard", @"") forState:UIControlStateNormal];
                [self->completeButton addTarget:self action:@selector(restartSpringBoard) forControlEvents:UIControlEventTouchUpInside];
            }
            else if (self->zebraRestartRequired) {
                [self->completeButton setTitle:NSLocalizedString(@"Close Zebra", @"") forState:UIControlStateNormal];
                [self->completeButton addTarget:self action:@selector(closeZebra) forControlEvents:UIControlEventTouchUpInside];
            }
            else {
                [self->completeButton setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
                [self->completeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
            }
        });
    }
}

#pragma mark - Command Delegate

- (void)receivedData:(NSString *)data {
    NSLog(@"[Zebra] Data: %@", data);
    [self writeToConsole:data atLevel:ZBLogLevelDescript];
}

- (void)receivedErrorData:(NSString *)data {
    NSLog(@"[Zebra] Err Data: %@", data);
    [[FIRCrashlytics crashlytics] logWithFormat:@"DPKG/APT Error: %@", data];
    if ([data rangeOfString:@"warning"].location != NSNotFound || [data hasPrefix:@"W:"]) {
        [self writeToConsole:data atLevel:ZBLogLevelWarning];
    } else {
        [self writeToConsole:data atLevel:ZBLogLevelError];
    }
}

- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level {
    if (!blockDatabaseMessages) [self writeToConsole:status atLevel:level];
}

#pragma mark - Download Delegate

- (void)startedDownloads {
}

- (void)startedPackageDownload:(ZBPackage *)package {
    [self writeToConsole:[NSString stringWithFormat:NSLocalizedString(@"Downloading %@ (%@)", @""), package.name, package.identifier] atLevel:ZBLogLevelDescript];
}

- (void)progressUpdate:(CGFloat)progress forPackage:(ZBPackage *)package {
    downloadMap[package.identifier] = @(progress);
    CGFloat totalProgress = 0;
    for (NSString *packageID in downloadMap) {
        totalProgress += [downloadMap[packageID] doubleValue];
    }
    totalProgress /= downloadMap.count;
    [self updateProgress:totalProgress];
    [self updateProgressText:[NSString stringWithFormat: @"%@: %.1f%% ", NSLocalizedString(@"Downloading", @""), totalProgress * 100]];
}

- (void)finishedPackageDownload:(ZBPackage *)package withError:(NSError *_Nullable)error {
    if (error) {
        downloadFailed = YES;
        [self writeToConsole:error.localizedDescription atLevel:ZBLogLevelError];
    }
    else {
        [self writeToConsole:[NSString stringWithFormat:NSLocalizedString(@"Done %@ (%@)", @""), package.name, package.identifier] atLevel:ZBLogLevelDescript];
    }
}

- (void)finishedAllDownloads {
    [self performSelectorInBackground:@selector(performTasks) withObject:nil];
    
    suppressCancel = YES;
    [self updateCancelOrCloseButton];
}

#pragma mark - Database Delegate

- (void)databaseStartedUpdate {
    blockDatabaseMessages = YES; // Prevents random database messages from coming in to the console
    [self writeToConsole:NSLocalizedString(@"Importing local packages.", @"") atLevel:ZBLogLevelInfo];
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    blockDatabaseMessages = NO;
    [self writeToConsole:NSLocalizedString(@"Finished importing local packages.", @"") atLevel:ZBLogLevelInfo];
//    if (packageUpdates != -1) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[ZBAppDelegate tabBarController] setPackageUpdateBadgeValue:packageUpdates];
//        });
//    }
}

@end
