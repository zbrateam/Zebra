//
//  ZBDevice.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 7/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <ZBDevice.h>
#import <ZBSettings.h>
#import <Extensions/UIColor+GlobalColors.h>
#import <WebKit/WebKit.h>
#import <Queue/ZBQueue.h>
#import "ZBAppDelegate.h"
#import "MobileGestalt.h"
#import <UIKit/UIDevice.h>
#import <NSTask.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <unistd.h>
@import SafariServices;
@import LNPopupController;
@import Crashlytics;

@implementation ZBDevice

+ (BOOL)needsSimulation {
#if TARGET_OS_SIMULATOR
    return YES;
#else
    static BOOL value = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = ![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/libexec/zebra/supersling"];
    });
    return value;
#endif
}

//Check to see if su/sling has the proper setuid/setgid bit
//We shouldn't do a dispatch_once because who knows when the file could be changed
//Returns YES if su/sling's setuid/setgid permissions need to be reset
+ (BOOL)isSlingshotBrokenWithError:(NSError *_Nullable*_Nullable)error {
#if TARGET_OS_SIMULATOR
    return NO;
#else
    struct stat path_stat;
    stat("/usr/libexec/zebra/supersling", &path_stat);
    
    if (![self _isRegularFile:@"/usr/libexec/zebra/supersling"]) { //this doesn't work?? edit: im a fool??
        NSError *cannotAccessError = [NSError errorWithDomain:NSCocoaErrorDomain code:50 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to access su/sling. Please verify that /usr/libexec/zebra/supersling exists.", @"")}];
        *error = cannotAccessError;
        
        return YES; //If we can't access the file, it is likely broken
    }
    
    if (path_stat.st_uid != 0 || path_stat.st_gid != 0) {
        NSError *cannotAccessError = [NSError errorWithDomain:NSCocoaErrorDomain code:51 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"su/sling is not owned by root:wheel. Please verify the permissions of the file located at /usr/libexec/zebra/supersling.", @"")}];
        *error = cannotAccessError;
        
        return YES; //If the uid/gid aren't 0 then theres a problem
    }
    
    //Check the uid/gid bits of permissions
    BOOL cannot_set_uid = (path_stat.st_mode & S_ISUID) == 0;
    BOOL cannot_set_gid = (path_stat.st_mode & S_ISGID) == 0;
    if (cannot_set_uid || cannot_set_gid) {
        NSError *cannotAccessError = [NSError errorWithDomain:NSCocoaErrorDomain code:52 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"su/sling does not have permission to set the uid or gid. Please verify the permissions of the file located at /usr/libexec/zebra/supersling.", @"")}];
        *error = cannotAccessError;
        
        return YES;
    }
    
    return NO; //su/sling is  ok
#endif
}

+ (NSString *)UDID {
    static NSString *udid = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CFStringRef udidCF = (CFStringRef)MGCopyAnswer(kMGUniqueDeviceID);
        udid = (__bridge NSString *)udidCF;
        if (udid == NULL) {
            // send a fake UDID in case this is a simulator
            udid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        }
    });
    return udid;
}

+ (NSString *)deviceModelID {
    static NSString *modelID = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct utsname systemInfo;
        uname(&systemInfo);
        modelID = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    });
    return modelID;
}

+ (NSString *)machineID {
    static NSString *machineIdentifier = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *answer = malloc(size);
        sysctlbyname("hw.machine", answer, &size, NULL, 0);
        machineIdentifier = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
        free(answer);
        
        if ([machineIdentifier isEqualToString:@"x86_64"]) {
            machineIdentifier = @"iPhone11,2";
        }
    });
    return machineIdentifier;
}

+ (void)hapticButton {
    if (@available(iOS 10.0, *)) {
        UISelectionFeedbackGenerator *feedback = [[UISelectionFeedbackGenerator alloc] init];
        [feedback prepare];
        [feedback selectionChanged];
        feedback = nil;
    }
}

+ (void)asRoot:(NSTask *)task arguments:(NSArray *)arguments {
    NSString *launchPath = task.launchPath;
    [task setLaunchPath:@"/usr/libexec/zebra/supersling"];
    NSArray *trueArguments = @[launchPath];
    if (arguments) {
        trueArguments = [trueArguments arrayByAddingObjectsFromArray:arguments];
    }
    [task setArguments:trueArguments];
}

+ (void)task:(NSTask *)task withArguments:(NSArray *)arguments {
    NSString *launchPath = task.launchPath;
    NSArray *trueArguments = @[launchPath];
    if (arguments) {
        trueArguments = [trueArguments arrayByAddingObjectsFromArray:arguments];
    }
    [task setArguments:trueArguments];
}

+ (void)sbreload {
    if (![self needsSimulation]) {
        BOOL failed;
        
        //Try sbreload
        BOOL hasSbreload = [[NSFileManager defaultManager] isExecutableFileAtPath:@"/usr/bin/sbreload"];
        if (hasSbreload) {
            failed = NO;
            
            NSTask *sbreloadTask = [[NSTask alloc] init];
            [sbreloadTask setLaunchPath:@"sbreload"];
            [self asRoot:sbreloadTask arguments:nil];
            if (![sbreloadTask isRunning]) {
                @try {
                    [sbreloadTask launch];
                    [sbreloadTask waitUntilExit];
                }
                @catch (NSException *e) {
                    CLS_LOG(@"Could not spawn sbreload. Reason: %@", e.reason);
                    failed = YES;
                }
            } else {
                failed = YES;
            }
        }
        
        //Try launchctl
        BOOL hasLaunchCTL = [[NSFileManager defaultManager] isExecutableFileAtPath:@"/sbin/launchctl"];
        if (hasLaunchCTL && (!hasSbreload || failed)) {
            failed = NO;
            
            NSTask *launchCTLTask = [[NSTask alloc] init];
            [launchCTLTask setLaunchPath:@"launchctl"];
            [self asRoot:launchCTLTask arguments:@[@"stop", @"com.apple.backboardd"]];
            if (![launchCTLTask isRunning]) {
                @try {
                    [launchCTLTask launch];
                    [launchCTLTask waitUntilExit];
                }
                @catch (NSException *e) {
                    CLS_LOG(@"Could not spawn launchctl. Reason: %@", e.reason);
                    failed = YES;
                }
            } else {
                failed = YES;
            }
        }
        
        //Try killall
        BOOL hasKillAll = [[NSFileManager defaultManager] isExecutableFileAtPath:@"/usr/bin/killall"];
        if (hasKillAll && ((!hasSbreload && !hasLaunchCTL) || failed)) {
            failed = NO;
            
            NSTask *killallTask = [[NSTask alloc] init];
            [killallTask setLaunchPath:@"killall"];
            [self asRoot:killallTask arguments:@[@"-9", @"com.apple.backboardd"]];
            if (![killallTask isRunning]) {
                @try {
                    [killallTask launch];
                    [killallTask waitUntilExit];
                }
                @catch (NSException *e) {
                    CLS_LOG(@"Could not spawn killall. Reason: %@", e.reason);
                    failed = YES;
                }
            } else {
                failed = YES;
            }
        }
    }
}

+ (void)uicache:(NSArray *)arguments observer:(NSObject <ZBConsoleCommandDelegate> *)observer {
    if (![self needsSimulation]) {
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/bin/uicache"];
        [self task:task withArguments:arguments];
        
        if (observer) {
            NSPipe *outputPipe = [[NSPipe alloc] init];
            NSFileHandle *output = [outputPipe fileHandleForReading];
            [output waitForDataInBackgroundAndNotify];
            [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:output];
            NSPipe *errorPipe = [[NSPipe alloc] init];
            NSFileHandle *error = [errorPipe fileHandleForReading];
            [error waitForDataInBackgroundAndNotify];
            [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(receivedErrorData:) name:NSFileHandleDataAvailableNotification object:error];
            [task setStandardOutput:outputPipe];
            [task setStandardError:errorPipe];
        }
        
        [task launch];
    }
}

+ (BOOL)_isRegularFile:(NSString *)path {
    BOOL isDir = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    return exists && !isDir;
}

+ (BOOL)_isRegularDirectory:(NSString *)path {
    BOOL isDir = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    return exists && isDir;
}

+ (BOOL)isCheckrain {
    static BOOL value = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [self needsSimulation] ? NO : [self _isRegularFile:@"/.bootstrapped"];
    });
    return value;
}

+ (BOOL)isChimera {
    static BOOL value = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [self needsSimulation] ? NO : [self _isRegularDirectory:@"/chimera"];
    });
    return value;
}

+ (BOOL)isElectra {
    static BOOL value = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [self needsSimulation] ? NO : [self _isRegularDirectory:@"/electra"];
    });
    return value;
}

+ (BOOL)isUncover {
    static BOOL value = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [self needsSimulation] ? NO : [self _isRegularFile:@"/.installed_unc0ver"];
    });
    return value;
}

+ (NSString *)packageManagementBinary {
    static NSString *packageManagementBinary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/apt"]) {
            packageManagementBinary = @"/usr/bin/apt";
        }
        else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/dpkg"]) {
            packageManagementBinary = @"/usr/bin/dpkg";
        }
    });
    return packageManagementBinary;
}

+ (NSString * _Nonnull)deviceType {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return @"iPad"; /* Device is iPad */
    return @"iPhone/iPod";
}

// Dark mode
+ (BOOL)darkModeEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"darkMode"];
}

+ (BOOL)darkModeOledEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:oledModeKey];
}

+ (BOOL)darkModeThirteenEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:thirteenModeKey];
}

+ (void)setDarkModeEnabled:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:enabled forKey:@"darkMode"];
    [defaults synchronize];
}

+ (void)configureTabBarColors:(UIColor *)tintColor forDarkMode:(BOOL)darkMode {
    // Tab
    [[UITabBar appearance] setTintColor:tintColor];
    if (@available(iOS 10.0, *)) {
        [[UITabBar appearance] setUnselectedItemTintColor:[UIColor lightGrayColor]];
    }
    [[UITabBar appearance] setBackgroundColor:nil];
    [[UITabBar appearance] setBarTintColor:nil];

    if (darkMode) {
        [[UITabBar appearance] setBarStyle:UIBarStyleBlack];
    } else {
        [[UITabBar appearance] setBarStyle:UIBarStyleDefault];
    }
}

+ (void)configureDarkMode {
    UIColor *tintColor = [UIColor tintColor];
    // Navigation bar
    [[UINavigationBar appearance] setTintColor:tintColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor cellPrimaryTextColor]}];
    // [[UINavigationBar appearance] setShadowImage:[UIImage new]];
    if (@available(iOS 11.0, *)) {
        [[UINavigationBar appearance] setLargeTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor cellPrimaryTextColor]}];
    }
    if ([ZBDevice darkModeOledEnabled]) {
        [[UINavigationBar appearance] setBackgroundColor:[UIColor tableViewBackgroundColor]];
        [[UINavigationBar appearance] setTranslucent:NO];
    } else {
        [[UINavigationBar appearance] setBackgroundColor:nil];
        [[UINavigationBar appearance] setTranslucent:YES];
    }
    
    // Status bar
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    
    [self configureTabBarColors:tintColor forDarkMode:true];
    
    // Tables
    [[UITableView appearance] setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [[UITableView appearance] setSeparatorColor:[UIColor cellSeparatorColor]];
    [[UITableView appearance] setTintColor:tintColor];
    [[UITableViewCell appearance] setBackgroundColor:[UIColor cellBackgroundColor]];
    
    UIView *dark = [[UIView alloc] init];
    dark.backgroundColor = [UIColor selectedCellBackgroundColorDark:YES oled:[ZBDevice darkModeOledEnabled]];
    [[UITableViewCell appearance] setSelectedBackgroundView:dark];
    [UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewCell class]]].textColor = [UIColor cellPrimaryTextColor];
    
    // Keyboard
    [[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceDark];
    
    // Web views
    [[WKWebView appearance] setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [[WKWebView appearance] setOpaque:YES];
    
    //PopupBar
    [[LNPopupBar appearance] setBackgroundStyle:UIBlurEffectStyleDark];
    [[LNPopupBar appearance] setBackgroundColor:[UIColor blackColor]];
    [[LNPopupBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    [[LNPopupBar appearance] setSubtitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    [[UITextField appearance] setTextColor:[UIColor whiteColor]];
}

+ (void)configureLightMode {
    UIColor *tintColor = [UIColor tintColor];
    // Navigation bar
    [[UINavigationBar appearance] setTintColor:tintColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor cellPrimaryTextColor]}];
    // [[UINavigationBar appearance] setShadowImage:[UIImage new]];
    if (@available(iOS 11.0, *)) {
        [[UINavigationBar appearance] setLargeTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor cellPrimaryTextColor]}];
    }
    [[UINavigationBar appearance] setBarTintColor:nil];
    [[UINavigationBar appearance] setBackgroundColor:nil];
    [[UINavigationBar appearance] setTranslucent:YES];
    // Status bar
    [[UINavigationBar appearance] setBarStyle:UIBarStyleDefault];
    
    // Tab
    [self configureTabBarColors:tintColor forDarkMode:false];
    
    // Tables
    [[UITableView appearance] setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [[UITableView appearance] setTintColor:tintColor];
    [[UITableView appearance] setTintColor:nil];
    [[UITableViewCell appearance] setBackgroundColor:[UIColor cellBackgroundColor]];
    [[UITableViewCell appearance] setSelectedBackgroundView:nil];
    [UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewCell class]]].textColor = [UIColor cellPrimaryTextColor];
    
    // Keyboard
    [[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceDefault];
    
    // Web views
    [[WKWebView appearance] setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [[WKWebView appearance] setOpaque:YES];
    
    [[LNPopupBar appearance] setTranslucent:true];
    [[LNPopupBar appearance] setBackgroundStyle:UIBlurEffectStyleLight];
    [[LNPopupBar appearance] setBackgroundColor:[UIColor whiteColor]];
    [[LNPopupBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]}];
    [[LNPopupBar appearance] setSubtitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]}];
    
    [[UITextField appearance] setTextColor:[UIColor blackColor]];
}

+ (void)applyThemeSettings {
    if ([self darkModeEnabled]) {
        [self configureDarkMode];
    } else {
        [self configureLightMode];
    }
}

+ (void)refreshViews {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        for (UIView *view in window.subviews) {
            [view removeFromSuperview];
            [window addSubview:view];
            CATransition *transition = [CATransition animation];
            transition.type = kCATransitionFade;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.fillMode = kCAFillModeForwards;
            transition.duration = 0.35;
            transition.subtype = kCATransitionFromTop;
            [view.layer addAnimation:transition forKey:nil];
        }
    }
}

+ (NSInteger)selectedColorTint {
    return [[NSUserDefaults standardUserDefaults] integerForKey:tintSelectionKey];
}

+ (void)openURL:(NSURL *)url delegate:(UIViewController <SFSafariViewControllerDelegate> *)delegate {
    SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url];
    safariVC.delegate = delegate;
    UIColor *tintColor = [UIColor tintColor];
    if (@available(iOS 10.0, *)) {
        safariVC.preferredBarTintColor = [UIColor tableViewBackgroundColor];
        safariVC.preferredControlTintColor = tintColor;
    } else {
        safariVC.view.tintColor = tintColor;
    }
    [delegate presentViewController:safariVC animated:YES completion:nil];
}

+ (BOOL)useIcon {
    return [[NSUserDefaults standardUserDefaults] boolForKey:iconActionKey];
}

@end
