//
//  ZBConsoleViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/6/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBConsoleViewController.h"
#import "ZBStage.h"
#import "ZBCanisterDownloadIngests.h"

#import "ZBDatabaseManager.h"
#import "ZBDownloadManager.h"
#import "ZBTabBarController.h"
#import "ZBPackage.h"
#import "ZBQueue.h"
#import "ZBAppDelegate.h"
#import "ZBDevice.h"
#import "ZBLog.h"
#import "ZBSettings.h"
#import "UIColor+GlobalColors.h"
#import "ZBThemeManager.h"
#import "UIFont+Zebra.h"
#import "ZBCommand.h"

#include <sysexits.h>

@import LNPopupController;

typedef NS_ENUM(NSUInteger, ZBConsoleFinishOption) {
    ZBConsoleFinishOptionClose,
    ZBConsoleFinishOptionRefreshIconCache,
    ZBConsoleFinishOptionReopen,
    ZBConsoleFinishOptionRestartSpringBoard,
    ZBConsoleFinishOptionReload,
    ZBConsoleFinishOptionRebootDevice
};

@interface ZBConsoleViewController () <ZBCommandDelegate> {
    NSMutableArray *applicationBundlePaths;
    NSMutableArray *installedPackageIdentifiers;
    NSMutableDictionary <NSString *, NSNumber *> *downloadMap;
    NSString *localInstallPath;
    ZBDownloadManager *downloadManager;
    ZBQueue *queue;
    ZBStage currentStage;
    BOOL downloadFailed;
    BOOL suppressCancel;
    BOOL updateIconCache;
    BOOL zebraRestartRequired;
    int autoFinishDelay;
    BOOL blockDatabaseMessages;
    ZBConsoleFinishOption finishOption;
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
    self = [super init];
    self = [storyboard instantiateViewControllerWithIdentifier:@"consoleViewController"];
    
    if (self) {
        applicationBundlePaths = [NSMutableArray new];
        queue = [ZBQueue sharedQueue];
        if ([queue needsToDownloadPackages]) {
            downloadManager = [[ZBDownloadManager alloc] initWithDownloadDelegate:self];
            downloadMap = [NSMutableDictionary new];
        }
        installedPackageIdentifiers = [NSMutableArray new];
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
    suppressCancel = NO;
    zebraRestartRequired = NO;
    installedPackageIdentifiers = [NSMutableArray new];
    applicationBundlePaths = [NSMutableArray new];
    downloadMap = [NSMutableDictionary new];
    finishOption = ZBConsoleFinishOptionClose;
    
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
        if (@available(iOS 11.0, *)) {}
        else {
            self.edgesForExtendedLayout = UIRectEdgeNone;
            self.view.preservesSuperviewLayoutMargins = YES;
            self.navigationController.navigationBar.translucent = NO;
        }
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
            [self updateProgressText:NSLocalizedString(@"Performing Actions…", @"")];
            
            for (ZBPackage *package in [queue packagesToInstall]) {
                [installedPackageIdentifiers addObject:[package identifier]];
            }
            
            [CanisterIngest ingestPackages:[queue packagesToInstall]];
            
            for (NSArray <NSString *> *command in actions) {
                if ([command count] == 1) {
                    [self updateStage:(ZBStage)[command[0] intValue]];
                }
                else {
                    if (currentStage == ZBStageRemove) {
                        for (int i = COMMAND_START; i < command.count; ++i) {
                            NSString *packageID = command[i];
                            if (![self isValidPackageID:packageID]) continue;
                            
                            NSString *bundlePath = [ZBPackage applicationBundlePathForIdentifier:packageID];
                            if (bundlePath) {
                                ZBLog(@"[Zebra] %@ has an app bundle", bundlePath);
                                updateIconCache = YES;
                                [applicationBundlePaths addObject:bundlePath];
                            }

                            if (finishOption < ZBConsoleFinishOptionRestartSpringBoard && [ZBPackage respringRequiredFor:packageID]) {
                                finishOption = ZBConsoleFinishOptionRestartSpringBoard;
                                ZBLog(@"[Zebra] Respring Required");
                            }
                        }
                    }
                    
                    if (![ZBDevice needsSimulation]) {
                        ZBLog(@"[Zebra] Executing commands…");
                        [self _runSuperslingCommand:command];
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
            
            for (int i = 0; i < installedPackageIdentifiers.count; ++i) {
                NSString *packageIdentifier = installedPackageIdentifiers[i];
                NSString *bundlePath = [ZBPackage applicationBundlePathForIdentifier:packageIdentifier];
                if (bundlePath && ![applicationBundlePaths containsObject:bundlePath]) {
                    updateIconCache = YES;
                    [applicationBundlePaths addObject:bundlePath];
                }

                if (finishOption < ZBConsoleFinishOptionRestartSpringBoard && [ZBPackage respringRequiredFor:packageIdentifier]) {
                    finishOption = ZBConsoleFinishOptionRestartSpringBoard;
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
                if (finishOption < ZBConsoleFinishOptionReopen) {
                    finishOption = ZBConsoleFinishOptionReopen;
                }
                
                ZBLog(@"[Zebra] modifying zebra…");
                if (queue.removingZebra) {
                    [self postStatusUpdate:NSLocalizedString(@"Removing Zebra…", @"") atLevel:ZBLogLevelInfo];
                    [self postStatusUpdate:@"Goodbye forever :(" atLevel:ZBLogLevelDescript];
                }
                else {
                    [self postStatusUpdate:NSLocalizedString(@"Installing Zebra…", @"") atLevel:ZBLogLevelInfo];
                }
                
                NSString *path = queue.zebraPath;
                
                NSArray *baseCommand;
                if ([[ZBDevice packageManagementBinary] isEqualToString:@INSTALL_PREFIX @"/usr/bin/dpkg"]) {
                    baseCommand = @[@"dpkg", queue.removingZebra ? @"-r" : @"-i", queue.zebraPath ? path : @"xyz.willy.zebra"];
                }
                else {
                    baseCommand = @[@"apt", @"-yqf", @"--allow-downgrades", @"-oApt::Get::HideAutoRemove=true", @"-oquiet::NoProgress=true", @"-oquiet::NoStatistic=true", queue.removingZebra ? @"remove" : @"install", queue.zebraPath ? path : @"xyz.willy.zebra"];
                }
                
                if (![ZBDevice needsSimulation]) {
                    [self _runSuperslingCommand:baseCommand];
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

- (void)_runSuperslingCommand:(NSArray <NSString *> *)arguments {
    ZBCommand *command = [[ZBCommand alloc] initWithCommand:arguments[0] arguments:arguments root:YES delegate:self];
    command.useFinishFd = YES;
    int status = [command execute];
    if (status < 0) {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Could not complete %@ process. Reason: %@", @""), [ZBDevice packageManagementBinary], [NSString stringWithUTF8String:strerror(status)]];

        NSLog(@"[Zebra] %@", message);
        [self writeToConsole:message atLevel:ZBLogLevelError];
    } else {
        // Handle specific error states
        switch (status) {
        case EX_NOPERM: {
            NSString *supersling = [[NSBundle mainBundle] pathForResource:@"supersling" ofType:nil];
            [self writeToConsole:[NSString stringWithFormat:NSLocalizedString(@"Zebra was unable to complete this command because it does not have the proper permissions. Please verify the permissions located at %@ and report this issue on GitHub.", @""), supersling] atLevel:ZBLogLevelError];
            break;
        }
        case EDEADLK:
            [self writeToConsole:NSLocalizedString(@"ERROR: Unable to lock status file. Please try again.", @"") atLevel:ZBLogLevelError];
            break;
        case 85: //ERESTART apparently
            [self writeToConsole:NSLocalizedString(@"ERROR: Process must be restarted. Please try again.", @"") atLevel:ZBLogLevelError];
            break;
        default:
            break;
        }
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
            [ZBDevice uicache:@[@"-p", @INSTALL_PREFIX @"/Applications/Zebra.app"] observer:self];
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

- (void)restartDevice {
    if (![ZBDevice needsSimulation]) {
        [ZBDevice restartDevice];
    } else {
        [self close];
    }
}

#pragma mark - Helper Methods

- (void)updateIconCaches {
    [self writeToConsole:NSLocalizedString(@"Updating icon cache asynchronously…", @"") atLevel:ZBLogLevelInfo];
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
            [self writeToConsole:NSLocalizedString(@"Downloading Packages…", @"") atLevel:ZBLogLevelInfo];
            
            [self setProgressTextHidden:NO];
            [self setProgressViewHidden:NO];
            break;
        case ZBStageInstall:
            [self updateTitle:NSLocalizedString(@"Installing", @"")];
            [self writeToConsole:NSLocalizedString(@"Installing Packages…", @"") atLevel:ZBLogLevelInfo];
            break;
        case ZBStageRemove:
            [self updateTitle:NSLocalizedString(@"Removing", @"")];
            [self writeToConsole:NSLocalizedString(@"Removing Packages…", @"") atLevel:ZBLogLevelInfo];
            break;
        case ZBStageReinstall:
            [self updateTitle:NSLocalizedString(@"Reinstalling", @"")];
            [self writeToConsole:NSLocalizedString(@"Reinstalling Packages…", @"") atLevel:ZBLogLevelInfo];
            break;
        case ZBStageUpgrade:
            [self updateTitle:NSLocalizedString(@"Upgrading", @"")];
            [self writeToConsole:NSLocalizedString(@"Upgrading Packages…", @"") atLevel:ZBLogLevelInfo];
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
        self->progressTextView.hidden = text == nil;
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
    ZBLog(@"[Zebra] Final statuses: downloadFailed(%d), finishOption(%lu), zebraRestartRequired(%d)", downloadFailed, (unsigned long)finishOption, zebraRestartRequired);
    if ([ZBSettings wantsFinishAutomatically]) { // automatically finish after 3 secs
        dispatch_block_t finishBlock = nil;

        if (self->downloadFailed) {
            [self updateProgressText:NSLocalizedString(@"Returning to Queue…", @"")];
            finishBlock = ^{
                [self updateProgressText:nil];
                [self returnToQueue];
            };
        }
        else {
            switch (self->finishOption) {
            case ZBConsoleFinishOptionClose:
            case ZBConsoleFinishOptionRefreshIconCache: {
                // RefreshIconCache is redundant; we’re just treating it the same as Close.
                [self updateProgressText:NSLocalizedString(@"Done…", @"")];
                finishBlock = ^{
                    [self updateProgressText:nil];
                    [self close];
                };
                break;
            }

            case ZBConsoleFinishOptionReopen: {
                [self updateProgressText:NSLocalizedString(@"Closing Zebra…", @"")];
                finishBlock = ^{
                    [self updateProgressText:nil];
                    [self closeZebra];
                };
                break;
            }

            case ZBConsoleFinishOptionRestartSpringBoard:
            case ZBConsoleFinishOptionReload: {
                [self updateProgressText:NSLocalizedString(@"Restarting SpringBoard…", @"")];
                finishBlock = ^{
                    [self updateProgressText:nil];
                    [self restartSpringBoard];
                };
                break;
            }

            case ZBConsoleFinishOptionRebootDevice: {
                [self updateProgressText:[NSString stringWithFormat:NSLocalizedString(@"Restarting %@…", @""), [UIDevice currentDevice].localizedModel]];
                finishBlock = ^{
                    [self updateProgressText:nil];
                    [self restartDevice];
                };
                break;
            }
            }
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
            else {
                switch (self->finishOption) {
                case ZBConsoleFinishOptionClose:
                case ZBConsoleFinishOptionRefreshIconCache:
                    // RefreshIconCache is redundant since we handle this automatically; we’re just
                    // treating it the same as Close.
                    [self->completeButton setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
                    [self->completeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
                    break;

                case ZBConsoleFinishOptionReopen:
                    [self->completeButton setTitle:NSLocalizedString(@"Close Zebra", @"") forState:UIControlStateNormal];
                    [self->completeButton addTarget:self action:@selector(closeZebra) forControlEvents:UIControlEventTouchUpInside];
                    break;

                case ZBConsoleFinishOptionRestartSpringBoard:
                case ZBConsoleFinishOptionReload:
                    [self->completeButton setTitle:NSLocalizedString(@"Restart SpringBoard", @"") forState:UIControlStateNormal];
                    [self->completeButton addTarget:self action:@selector(restartSpringBoard) forControlEvents:UIControlEventTouchUpInside];
                    break;

                case ZBConsoleFinishOptionRebootDevice:
                    [self->completeButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"Restart %@", @""), [UIDevice currentDevice].localizedModel] forState:UIControlStateNormal];
                    [self->completeButton addTarget:self action:@selector(restartDevice) forControlEvents:UIControlEventTouchUpInside];
                    break;
                }
            }
        });
    }
}

#pragma mark - Command Delegate

- (void)receivedData:(NSString *)str {
    [self writeToConsole:str atLevel:ZBLogLevelDescript];
}

- (void)receivedErrorData:(NSString *)str {
    if ([str containsString:@"stable CLI interface"]) return;
    if ([str containsString:@"postinst"]) return;
    if ([str rangeOfString:@"warning"].location != NSNotFound || [str hasPrefix:@"W:"]) {
        [self writeToConsole:str atLevel:ZBLogLevelWarning];
    } else {
        [self writeToConsole:str atLevel:ZBLogLevelError];
    }
}

- (void)receivedFinishData:(NSString *)str {
    if ([str hasPrefix:@"finish:"]) {
        NSArray *components = [str componentsSeparatedByString:@":"];
        if (components.count == 2) {
            NSString *option = [components[1] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            NSArray *options = @[@"return", @"uicache", @"reopen", @"restart", @"reload", @"reboot"];
            NSUInteger index = [options indexOfObject:option];

            if (index != NSNotFound && index > finishOption) {
                finishOption = (ZBConsoleFinishOption)index;
            }
        }
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
    [self updateProgressText:[NSString stringWithFormat: @"%@: %.0f%% ", NSLocalizedString(@"Downloading", @""), totalProgress * 100]];
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
    if (packageUpdates != -1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ZBAppDelegate tabBarController] setPackageUpdateBadgeValue:packageUpdates];
        });
    }
}

@end
