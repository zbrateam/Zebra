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
#import <Tabs/Packages/Helpers/ZBPackage.h>
#import <Queue/ZBQueue.h>
#import <ZBAppDelegate.h>
#import <ZBDevice.h>

@interface ZBConsoleViewController () {
    NSMutableArray *applicationBundlePaths;
    ZBStage currentStage;
    BOOL downloadFailed;
    ZBDownloadManager *downloadManager;
    NSMutableDictionary <NSString *, NSNumber *> *downloadMap;
    NSMutableArray *installedPackageIdentifiers;
    BOOL respringRequired;
    BOOL suppressCancel;
    BOOL updateIconCache;
    ZBQueue *queue;
    BOOL zebraRestartRequired;
}
@property (strong, nonatomic) IBOutlet UIButton *completeButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelOrCloseButton;
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
        downloadFailed = false;
        downloadManager = [[ZBDownloadManager alloc] initWithDownloadDelegate:self];
        downloadMap = [NSMutableDictionary new];
        installedPackageIdentifiers = [NSMutableArray new];
        respringRequired = false;
        updateIconCache = false;
        queue = [ZBQueue sharedQueue];
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Console";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([queue needsToDownloadPackages]) {
        [self downloadPackages:[queue packagesToDownload]];
    }
    else {
        [self performSelectorInBackground:@selector(performActions) withObject:NULL];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)performActions {
    [self performActionsForDownloadedFiles:NULL];
}

- (void)performActionsForDownloadedFiles:(NSArray *_Nullable)downloadedFiles {
    if (downloadFailed) {
        //TODO: Provide options for the user to cancel, retry, or clear queue.
    }
    else {
        NSArray *actions = [queue tasksToPerform:downloadedFiles];
        for (NSArray *command in actions) {
            if ([command count] == 1) {
                [self updateStage:(ZBStage)[command[0] intValue]];
            }
            else {
                for (int i = COMMAND_START; i < [command count]; ++i) {
                    NSString *packageID = command[i];
                    if (![self isValidPackageID:packageID]) continue;
                    
                    if (currentStage == ZBStageFinished) {
                        NSLog(@"Well ill be");
                    }
                    
                    if ([ZBPackage containsApplicationBundle:packageID]) {
                        updateIconCache = true;
                        NSString *path = [ZBPackage pathForApplication:packageID];
                        if (path != NULL) {
                            [applicationBundlePaths addObject:path];
                        }
                    }
                        
                    if (!respringRequired) {
                        respringRequired = [ZBPackage respringRequiredFor:packageID];
                    }
                    
                    if (currentStage != ZBStageRemove) {
                        [installedPackageIdentifiers addObject:packageID];
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
        [queue clear];
        [self refreshLocalPackages];
        [self finishTasks];
    }
}

- (void)finishTasks {
    [downloadMap removeAllObjects];
    [self setProgressViewHidden:true];
    
    NSMutableArray *uicaches = [NSMutableArray new];
    for (NSString *packageIdentifier in installedPackageIdentifiers) {
        if ([ZBPackage containsApplicationBundle:packageIdentifier]) {
            updateIconCache = YES;
            NSString *actualPackageIdentifier = packageIdentifier;
            if ([packageIdentifier hasSuffix:@".deb"]) {
                // Transform deb-path-like packageID into actual package ID for checking to prevent duplicates
                actualPackageIdentifier = [[packageIdentifier lastPathComponent] stringByDeletingPathExtension];
                // ex., com.xxx.yyy_1.0.0_iphoneos_arm.deb
                NSRange underscoreRange = [actualPackageIdentifier rangeOfString:@"_" options:NSLiteralSearch];
                if (underscoreRange.location != NSNotFound) {
                    actualPackageIdentifier = [actualPackageIdentifier substringToIndex:underscoreRange.location];
                    if (!zebraRestartRequired && [actualPackageIdentifier isEqualToString:@"xyz.willy.zebra"]) {
                        zebraRestartRequired = YES;
                    }
                }
                if ([uicaches containsObject:actualPackageIdentifier])
                    continue;
            }
            if (![uicaches containsObject:actualPackageIdentifier])
                [uicaches addObject:actualPackageIdentifier];
        }
        
        if (!respringRequired) {
            respringRequired = [ZBPackage respringRequiredFor:packageIdentifier] ? YES : respringRequired;
        }
    }
    
    [self removeAllDebs];
    
    if (updateIconCache) {
        [self updateIconCaches:uicaches];
    }
    
    [self updateStage:ZBStageFinished];
}

- (void)updateIconCaches:(NSArray *)caches {
    //FIXME: Localize
    [self writeToConsole:@"Updating icon cache asynchronously..." atLevel:ZBLogLevelInfo];
    NSMutableArray *arguments = [NSMutableArray new];
    if ([caches count] + [applicationBundlePaths count] > 1) {
        [arguments addObject:@"-a"];
        [self writeToConsole:@"This may take awhile and Zebra may crash. It is okay if it does." atLevel:ZBLogLevelWarning];
    }
    else {
        [arguments addObject:@"-p"];
        for (NSString *packageID in caches) {
            if ([packageID isEqualToString:[ZBAppDelegate bundleID]])
                continue;
            NSString *bundlePath = [ZBPackage pathForApplication:packageID];
            if (bundlePath != NULL)
                [applicationBundlePaths addObject:bundlePath];
        }
        [arguments addObjectsFromArray:applicationBundlePaths];
    }
    
    if (![ZBDevice needsSimulation]) {
        [ZBDevice uicache:arguments observer:self];
    } else {
        [self writeToConsole:@"uicache is not available on the simulator" atLevel:ZBLogLevelWarning];
    }
}

- (void)updateCompleteButton {
    //FIXME: Localize
    dispatch_async(dispatch_get_main_queue(), ^{
        self->completeButton.hidden = NO;
        [self updateProgressText:nil];
        if (self->respringRequired) {
            [self->completeButton setTitle:@"Restart SpringBoard" forState:UIControlStateNormal];
            [self->completeButton addTarget:self action:@selector(restartSpringBoard) forControlEvents:UIControlEventTouchUpInside];
        }
        else if (self->zebraRestartRequired) {
            [self->completeButton setTitle:@"Close Zebra" forState:UIControlStateNormal];
            [self->completeButton addTarget:self action:@selector(closeZebra) forControlEvents:UIControlEventTouchUpInside];
        }
        else {
            [self->completeButton setTitle:@"Done" forState:UIControlStateNormal];
        }
    });
}

- (void)cancel {
    if (suppressCancel)
        return;
    
    [downloadManager stopAllDownloads];
    [downloadMap removeAllObjects];
    [self updateProgress:1.0];
    [self setProgressViewHidden:true];
    [self updateProgressText:nil];
    [self setProgressTextHidden:true];
    [queue clear];
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

- (void)updateStage:(ZBStage)stage {
    dispatch_async(dispatch_get_main_queue(), ^{
        //FIXME: Localize
        switch (stage) {
            case ZBStageDownload:
                [self setTitle:@"Downloading"];
                [self writeToConsole:@"Downloading Packages..." atLevel:ZBLogLevelInfo];
            case ZBStageInstall:
                [self setTitle:@"Installing"];
                [self writeToConsole:@"Installing Packages..." atLevel:ZBLogLevelInfo];
                break;
            case ZBStageRemove:
                [self setTitle:@"Removing"];
                [self writeToConsole:@"Removing Packages..." atLevel:ZBLogLevelInfo];
                break;
            case ZBStageReinstall:
                [self setTitle:@"Reinstalling"];
                [self writeToConsole:@"Reinstalling Packages..." atLevel:ZBLogLevelInfo];
                break;
            case ZBStageUpgrade:
                [self setTitle:@"Upgrading"];
                [self writeToConsole:@"Upgrading Packages..." atLevel:ZBLogLevelInfo];
                break;
            case ZBStageFinished:
                [self setTitle:@"Complete"];
                [self writeToConsole:@"Finished!" atLevel:ZBLogLevelInfo];
                
                self->suppressCancel = NO;
                [self updateCompleteButton];
                [self updateCancelOrCloseButton];
                break;
            default:
                break;
        }
    });
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

        [self->consoleView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[str stringByAppendingString:@"\n"] attributes:attrs]];

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
            self.cancelOrCloseButton.hidden = YES;
        } else if (self->currentStage == ZBStageFinished) {
            self.cancelOrCloseButton.hidden = self->zebraRestartRequired;
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
    if (currentStage == ZBStageFinished) {
        [self close];
    } else {
        [self cancel];
    }
}

#pragma mark - Helper Methods

- (BOOL)isValidPackageID:(NSString *)packageID {
    return ![packageID hasPrefix:@"-"] && ![packageID isEqualToString:@"install"] && ![packageID isEqualToString:@"remove"];
}

- (void)refreshLocalPackages {
    ZBDatabaseManager *databaseManager = [ZBDatabaseManager sharedInstance];
    [databaseManager addDatabaseDelegate:self];
    [databaseManager importLocalPackagesAndCheckForUpdates:YES sender:self];
}

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
        [self->progressView setProgress:progress animated:true];
    });
}

- (void)updateProgressText:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->progressText.text = text;
    });
}

#pragma mark - Downloading Packages

- (void)downloadPackages:(NSArray <ZBPackage *> *)packages {
    [self updateStage:ZBStageDownload];
    [downloadManager downloadPackages:packages];
}

- (void)predator:(nonnull ZBDownloadManager *)downloadManager progressUpdate:(CGFloat)progress forPackage:(ZBPackage *)package {
    downloadMap[package.identifier] = @(progress);
    CGFloat totalProgress = 0;
    for (NSString *packageID in downloadMap) {
        totalProgress += [downloadMap[packageID] doubleValue];
    }
    totalProgress /= downloadMap.count;
    [self updateProgress:totalProgress];
    [self updateProgressText:[NSString stringWithFormat: @"Downloading: %.1f%% ", totalProgress * 100]];
}

- (void)predator:(nonnull ZBDownloadManager *)downloadManager finishedAllDownloads:(NSDictionary *)filenames {
    [self updateProgressText:nil];
    if (filenames.count) {
        NSArray *debs = [filenames objectForKey:@"debs"];
        [self performSelectorInBackground:@selector(performActionsForDownloadedFiles:) withObject:debs];
    }
    else {
        downloadFailed = true;
        [self cancel];
        [self writeToConsole:@"Nothing has been downloaded.\n" atLevel:ZBLogLevelWarning];
        [self updateStage:ZBStageFinished];
        [self updateCompleteButton];
    }
    suppressCancel = true;
    self.cancelOrCloseButton.hidden = YES;
}

- (void)predator:(nonnull ZBDownloadManager *)downloadManager startedDownloadForFile:(nonnull NSString *)filename {
    [self writeToConsole:[NSString stringWithFormat:@"Downloading %@", filename] atLevel:ZBLogLevelDescript];
}

- (void)predator:(nonnull ZBDownloadManager *)downloadManager finishedDownloadForFile:(NSString *_Nullable)filename withError:(NSError * _Nullable)error {
    if (error != NULL) {
        downloadFailed = true;
        [self writeToConsole:error.localizedDescription atLevel:ZBLogLevelError];
    }
    else if (filename) {
        [self writeToConsole:[NSString stringWithFormat:@"Done %@", filename] atLevel:ZBLogLevelDescript];
    }
}

#pragma mark - Database Delegate

- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level {
    [self writeToConsole:status atLevel:level];
}

- (void)databaseStartedUpdate {
    //FIXME: Localize
    [self writeToConsole:@"Importing local packages." atLevel:ZBLogLevelInfo];
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    //FIXME: Localize
    [self writeToConsole:@"Finished importing local packages." atLevel:ZBLogLevelInfo];
//    ZBLog(@"[Zebra] %d updates available.", packageUpdates);
    if (packageUpdates != -1) {
        [[ZBAppDelegate tabBarController] setPackageUpdateBadgeValue:packageUpdates];
    }
}

@end
