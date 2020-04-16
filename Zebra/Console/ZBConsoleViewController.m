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
#import <UIColor+GlobalColors.h>
#import <ZBThemeManager.h>

#include <sysexits.h>

@import Crashlytics;
@import LNPopupController;

@interface ZBConsoleViewController () {
    NSMutableArray *applicationBundlePaths;
    NSMutableArray *completedDownloads;
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
}
@property (strong, nonatomic) IBOutlet UIButton *completeButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelOrCloseButton;
@property (strong, nonatomic) IBOutlet UILabel *progressText;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UITextView *consoleView;
@end

@implementation ZBConsoleViewController

@synthesize completeButton;
@synthesize cancelOrCloseButton;
@synthesize progressText;
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
        autoFinishDelay = 3;
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Console", @"");
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
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
    progressText.layer.cornerRadius = 3.0;
    progressText.layer.masksToBounds = YES;
    [self updateProgressText:nil];
    [self setProgressViewHidden:YES];
    [[self progressView] setProgressTintColor:[UIColor accentColor]];
    
    ZBAccentColor color = [ZBSettings accentColor];
    ZBInterfaceStyle style = [ZBSettings interfaceStyle];
    if (color == ZBAccentColorMonochrome) {
        //Flip the colors for readability
        [[self completeButton] setBackgroundColor:[UIColor whiteColor]];
        [[self completeButton] setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    else {
        [[self completeButton] setBackgroundColor:[ZBThemeManager getAccentColor:color forInterfaceStyle:style]];
    }
    
    [self setProgressTextHidden:YES];
    [self updateCancelOrCloseButton];
    
    [self.navigationItem setHidesBackButton:YES];
    
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *app = [self.navigationController.navigationBar.standardAppearance copy];
        [app setBackgroundEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
        [app setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
        [self.navigationController.navigationBar setStandardAppearance:app];
        [self.navigationController.navigationBar setScrollEdgeAppearance:app];
    }
    else {
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    }
    
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
            
            for (ZBPackage *package in completedDownloads) {
                [installedPackageIdentifiers addObject:[package identifier]];
            }
            
            for (NSArray *command in actions) {
                if ([command count] == 1) {
                    [self updateStage:(ZBStage)[command[0] intValue]];
                }
                else {
                    if (currentStage == ZBStageRemove) {
                        for (int i = COMMAND_START; i < [command count]; ++i) {
                            NSString *packageID = command[i];
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
                        
                        @try {
                            [task launch];
                            [task waitUntilExit];
                            
                            int terminationStatus = [task terminationStatus];
                            switch (terminationStatus) {
                                case EX_NOPERM:
                                    [self writeToConsole:NSLocalizedString(@"Zebra was unable to complete this command because it does not have the proper permissions. Please verify the permissions located at /usr/libexec/zebra/supersling and report this issue on GitHub.", @"") atLevel:ZBLogLevelError];
                                    break;
                                case EDEADLK:
                                    [self writeToConsole:NSLocalizedString(@"ERROR: Unable to lock status file. Please try again.", @"") atLevel:ZBLogLevelError];
                                    break;
                                case 85: //ERESTART apparently
                                    [self writeToConsole:NSLocalizedString(@"ERROR: Process must be restarted. Please try again.", @"") atLevel:ZBLogLevelError];
                                    break;
                                default:
                                    break;
                            }
                        } @catch (NSException *e) {
                            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Could not complete %@ process. Reason: %@.", @""), [ZBDevice packageManagementBinary], e.reason];
                            
                            CLS_LOG(@"%@", message);
                            NSLog(@"[Zebra] %@", message);
                            [self writeToConsole:message atLevel:ZBLogLevelError];
                        }
                    }
                    else {
                        [self writeToConsole:NSLocalizedString(@"This device is simulated, here are the packages that would be modified in this stage:", @"") atLevel:ZBLogLevelWarning];
                        for (int i = COMMAND_START; i < [command count]; ++i) {
                            NSString *packageID = command[i];
                            if (![self isValidPackageID:packageID]) continue;
                            [self writeToConsole:[packageID lastPathComponent] atLevel:ZBLogLevelDescript];
                        }
                    }
                }
            }
            
            for (int i = 0; i < [installedPackageIdentifiers count]; i++) {
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
                    baseCommand = @[@"dpkg", queue.removingZebra ? @"-r" : @"-i", queue.zebraPath ? path : @"xyz.willy.zebra"];
                }
                else {
                    baseCommand = @[@"apt", @"-yqf", @"--allow-downgrades", @"-oApt::Get::HideAutoRemove=true", @"-oquiet::NoProgress=true", @"-oquiet::NoStatistic=true", queue.removingZebra ? @"remove" : @"install", queue.zebraPath ? path : @"xyz.willy.zebra"];
                }
                
                if (![ZBDevice needsSimulation]) {
                    NSTask *task = [[NSTask alloc] init];
                    [task setLaunchPath:@"/usr/libexec/zebra/supersling"];
                    [task setArguments:baseCommand];
                    
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
                    
                    @try {
                        [task launch];
                        [task waitUntilExit];
                        
                        int terminationStatus = [task terminationStatus];
                        switch (terminationStatus) {
                            case EX_NOPERM:
                                [self writeToConsole:NSLocalizedString(@"Zebra was unable to complete this command because it does not have the proper permissions. Please verify the permissions located at /usr/libexec/zebra/supersling and report this issue on GitHub.", @"") atLevel:ZBLogLevelError];
                                break;
                            case EDEADLK:
                                [self writeToConsole:NSLocalizedString(@"ERROR: Unable to lock status file. Please try again.", @"") atLevel:ZBLogLevelError];
                                break;
                            case 85: //ERESTART apparently
                                [self writeToConsole:NSLocalizedString(@"ERROR: Process must be restarted. Please try again.", @"") atLevel:ZBLogLevelError];
                                    break;
                            default:
                                break;
                        }
                    } @catch (NSException *e) {
                        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Could not complete %@ process. Reason: %@.", @""), [ZBDevice packageManagementBinary], e.reason];
                        
                        CLS_LOG(@"%@", message);
                        NSLog(@"[Zebra] %@", message);
                        [self writeToConsole:message atLevel:ZBLogLevelError];
                        [self writeToConsole:NSLocalizedString(@"Please restart Zebra and see if the issue still persists. If so, please file an issue on GitHub.", @"") atLevel:ZBLogLevelInfo];
                    }
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
    
//    [downloadManager stopAllDownloads];
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
            [ZBDevice uicache:@[@"-p", @"/Applications/Zebra.app"] observer:self];
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
    NSMutableArray *arguments = [NSMutableArray arrayWithObject:@"-p"];
    [arguments addObjectsFromArray:applicationBundlePaths];
    
    if (![ZBDevice needsSimulation]) {
        [ZBDevice uicache:arguments observer:self];
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
    if (str == NULL)
        return;
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
        
        //Adds a newline if there is not already one
        NSString *string = [str copy];
        if (![string hasSuffix:@"\n"]) {
            string = [str stringByAppendingString:@"\n"];
        }
        
        if (string == NULL) {
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
            [self.cancelOrCloseButton setTitle:NSLocalizedString(@"Close", @"")];
        }
        else {
            self.cancelOrCloseButton.enabled = YES;
            [self.cancelOrCloseButton setTitle:NSLocalizedString(@"Cancel", @"")];
        }
        
        if (self.cancelOrCloseButton.enabled) {
            [self.cancelOrCloseButton setTintColor:[UIColor whiteColor]];
        }
        else {
            [self.cancelOrCloseButton setTintColor:[UIColor clearColor]];
        }
    });
}

- (void)updateCompleteButton {
    ZBLog(@"[Zebra] Final statuses: downloadFailed(%d), respringRequired(%d), zebraRestartRequired(%d)", downloadFailed, respringRequired, zebraRestartRequired);
    if ([ZBSettings wantsFinishAutomatically]) { // automatically finish after 3 secs
        dispatch_block_t finishBlock = nil;

        if (self->downloadFailed) {
            [self updateProgressText:NSLocalizedString(@"Returning to queue...", @"")];
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
        CLS_LOG(@"DPKG/APT Error: %@", str);
        if ([str rangeOfString:@"warning"].location != NSNotFound) {
            str = [str stringByReplacingOccurrencesOfString:@"dpkg: " withString:@""];
            [self writeToConsole:str atLevel:ZBLogLevelWarning];
        } else if ([str rangeOfString:@"error"].location != NSNotFound) {
            str = [str stringByReplacingOccurrencesOfString:@"dpkg: " withString:@""];
            [self writeToConsole:str atLevel:ZBLogLevelError];
        }
    }
}

- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level {
    [self writeToConsole:status atLevel:level];
}

#pragma mark - Download Delegate

- (void)startedDownloads {
    if (!completedDownloads) {
        completedDownloads = [NSMutableArray new];
    }
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
        [completedDownloads addObject:package];
    }
}

- (void)finishedAllDownloads {
    [self performSelectorInBackground:@selector(performTasks) withObject:NULL];
    
    suppressCancel = YES;
    [self updateCancelOrCloseButton];
}

#pragma mark - Database Delegate

- (void)databaseStartedUpdate {
    [self writeToConsole:NSLocalizedString(@"Importing local packages.", @"") atLevel:ZBLogLevelInfo];
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    [self writeToConsole:NSLocalizedString(@"Finished importing local packages.", @"") atLevel:ZBLogLevelInfo];
    if (packageUpdates != -1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ZBAppDelegate tabBarController] setPackageUpdateBadgeValue:packageUpdates];
        });
    }
}

@end
