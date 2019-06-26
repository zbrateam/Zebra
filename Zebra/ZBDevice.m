//
//  ZBDevice.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 7/6/2562 BE.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBDevice.h"
#import <Extensions/UIColor+GlobalColors.h>
#import <WebKit/WebKit.h>
#import "ZBAppDelegate.h"
#import "MobileGestalt.h"
#import <UIKit/UIDevice.h>
#import <NSTask.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <unistd.h>

@implementation ZBDevice

+ (BOOL)needsSimulation {
#if TARGET_OS_SIMULATOR
    return YES;
#else
    return ![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/libexec/zebra/supersling"];
#endif
}

+ (NSString *)UDID {
    CFStringRef udidCF = (CFStringRef)MGCopyAnswer(kMGUniqueDeviceID);
    NSString *udid = (__bridge NSString *)udidCF;
    if (udid == NULL) {
        // send a fake UDID in case this is a simulator
        udid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    return udid;
}

+ (NSString *)deviceModelID {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (NSString *)machineID {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *answer = malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *machineIdentifier = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    free(answer);
    return machineIdentifier;
}

+ (void)sbreload {
    if (![self needsSimulation]) {
        NSTask *task = [[NSTask alloc] init];
        BOOL hasSbreload = [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/sbreload"];
        if (hasSbreload) {
            [task setLaunchPath:@"/usr/bin/sbreload"];
            [task launch];
            [task waitUntilExit];
        }
        
        if (!hasSbreload || [task terminationStatus] != 0) {
            NSLog(@"[Zebra] SBReload Failed. Trying to restart backboardd");
            //Ideally, this is only if sbreload fails
            [task setLaunchPath:@"/usr/libexec/zebra/supersling"];
            [task setArguments:@[@"/bin/launchctl", @"stop", @"com.apple.backboardd"]];
            
            [task launch];
        }
    }
}

+ (void)uicache:(NSArray *)arguments observer:(NSObject <ZBConsoleCommandDelegate> *)observer {
    if (![self needsSimulation]) {
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/libexec/zebra/supersling"];
        [task setArguments:[@[@"/usr/bin/uicache"] arrayByAddingObjectsFromArray:arguments]];
        
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
        [task waitUntilExit];
    }
}

+ (BOOL)_isRegularFile:(const char *)path {
    struct stat path_stat;
    stat(path, &path_stat);
    return S_ISREG(path_stat.st_mode);
}

+ (BOOL)_isRegularDirectory:(const char *)path {
    struct stat path_stat;
    stat(path, &path_stat);
    return S_ISDIR(path_stat.st_mode);
}

+ (BOOL)isChimera {
    return [self needsSimulation] ? NO : [self _isRegularDirectory:"/chimera"];
}

+ (BOOL)isElectra {
    return [self needsSimulation] ? NO : [self _isRegularDirectory:"/electra"];
}

+ (BOOL)isUncover {
    return [self needsSimulation] ? NO : [self _isRegularFile:"/.installed_unc0ver"];
}

//Dark mode
+ (BOOL)darkModeEnabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"darkMode"];
}

+ (void)setDarkModeEnabled:(BOOL)enabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:enabled forKey:@"darkMode"];
    [defaults synchronize];
}

+ (void)configureDarkMode {
    [[UINavigationBar appearance] setTintColor:[UIColor tintColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    if (@available(iOS 11.0, *)) {
        [[UINavigationBar appearance] setLargeTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    }
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.09 green:0.09 blue:0.09 alpha:1]];
    [[UINavigationBar appearance] setBackgroundColor:[UIColor colorWithRed:0.09 green:0.09 blue:0.09 alpha:1]];
    [[UINavigationBar appearance] setTranslucent:YES];
    //Status bar
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    
    //Tab
    [[UITabBar appearance] setTintColor:[UIColor tintColor]];
    [[UITabBar appearance] setBackgroundColor:[UIColor colorWithRed:0.11 green:0.11 blue:0.11 alpha:1.0]];
    [[UITabBar appearance] setBarTintColor:[UIColor colorWithRed:0.11 green:0.11 blue:0.11 alpha:1.0]];
    [[UITabBar appearance] setBarStyle:UIBarStyleBlack];
    
    //Tables
    [[UITableView appearance] setBackgroundColor:[UIColor colorWithRed:0.09 green:0.09 blue:0.09 alpha:1.0]];
    [[UITableView appearance] setTintColor:[UIColor tintColor]];
    [[UITableViewCell appearance] setBackgroundColor:[UIColor colorWithRed:0.110 green:0.110 blue:0.114 alpha:1.0]];
    UIView *dark = [[UIView alloc] init];
    dark.backgroundColor = [UIColor selectedCellBackgroundColorDark:YES];
    [[UITableViewCell appearance] setSelectedBackgroundView:dark];
    [UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewCell class]]].textColor = [UIColor whiteColor];
    [[WKWebView appearance] setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [[WKWebView appearance] setOpaque:NO];
}

+ (void)configureLightMode {
    [[UINavigationBar appearance] setTintColor:[UIColor tintColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:nil];
    if (@available(iOS 11.0, *)) {
        [[UINavigationBar appearance] setLargeTitleTextAttributes:nil];
    }
    [[UINavigationBar appearance] setBarTintColor:nil];
    [[UINavigationBar appearance] setBackgroundColor:nil];
    [[UINavigationBar appearance] setTranslucent:YES];
    //Status bar
    [[UINavigationBar appearance] setBarStyle:UIBarStyleDefault];
    
    //Tab
    [[UITabBar appearance] setTintColor:[UIColor tintColor]];
    [[UITabBar appearance] setBackgroundColor:nil];
    [[UITabBar appearance] setBarTintColor:nil];
    [[UITabBar appearance] setBarStyle:UIBarStyleDefault];
    
    //Tables
    [[UITableView appearance] setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [[UITableView appearance] setTintColor:nil];
    [[UITableViewCell appearance] setBackgroundColor:[UIColor cellBackgroundColor]];
    [UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewCell class]]].textColor = [UIColor cellPrimaryTextColor];
    [[WKWebView appearance] setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [[WKWebView appearance] setOpaque:YES];
}

+ (void)applySettings {
    if ([self darkModeEnabled]) {
        [self configureDarkMode];
    }
    else {
        [self configureLightMode];
    }
}

+ (void)refreshViews {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        for (UIView *view in window.subviews) {
            [view removeFromSuperview];
            [window addSubview:view];
        }
    }
}

@end
