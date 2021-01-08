//
//  ZBDevice.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 7/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBDevice.h"

#import <ZBSettings.h>
#import <sys/stat.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <Headers/MobileGestalt.h>
#import <Extensions/UIColor+GlobalColors.h>
#import <Theme/ZBThemeManager.h>
#import <Console/ZBCommand.h>

@import UIKit.UISelectionFeedbackGenerator;
@import FirebaseCrashlytics;
@import SafariServices;

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
+ (BOOL)isSlingshotBroken:(NSError *_Nullable*_Nullable)error {
    if ([ZBDevice needsSimulation]) {
        return NO; //Since simulated devices don't have su/sling, it isn't broken!
    }
    
    struct stat path_stat;
    stat("/usr/libexec/zebra/supersling", &path_stat);
    
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
    
    return NO; //su/sling is ok
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
        
        if ([modelID isEqualToString:@"x86_64"]) {
            modelID = @"iPhone11,2";
        }
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

+ (NSString * _Nonnull)debianArchitecture {
    return @"iphoneos-arm";
}

+ (void)hapticButton {
    UISelectionFeedbackGenerator *feedback = [[UISelectionFeedbackGenerator alloc] init];
    [feedback prepare];
    [feedback selectionChanged];
    feedback = nil;
}

+ (void)restartSpringBoard {
    if (![self needsSimulation]) {
        [ZBCommand execute:@"uicache" withArguments:@[@"-r"] asRoot:NO];
    }
}

+ (void)uicache:(NSArray *_Nullable)bundleIdentifiers {
    if (![self needsSimulation]) {
        if (bundleIdentifiers.count) {
            [ZBCommand execute:@"uicache" withArguments:[@[@"-p"] arrayByAddingObjectsFromArray:bundleIdentifiers] asRoot:NO];
        }
        else {
            [ZBCommand execute:@"uicache" withArguments:@[@"-a"] asRoot:NO];
        }
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
        value = [self needsSimulation] ? YES : [self _isRegularFile:@"/.bootstrapped"];
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

+ (BOOL)isOdyssey {
    static BOOL value = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([self _isRegularFile:@"/.procursus_strapped"]) {
            value = [self needsSimulation] ? NO : [self _isRegularFile:@"/.installed_odyssey"];
        }
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
    return [[UIDevice currentDevice] model];
}

+ (void)relaunchZebra {
    int seconds = 1; // if you change this, remember to update the relaunch daemon

    if (![self needsSimulation]) {
        [ZBCommand execute:@"launchctl" withArguments:@[@"start", @"xyz.willy.Zebra.Relaunch"] asRoot:YES];
    }

    [[UIApplication sharedApplication] suspend];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });
}

#pragma mark - Theming

+ (void)openURL:(NSURL *)url sender:(UIViewController *)sender {
    if (!sender) sender = UIApplication.sharedApplication.keyWindow.rootViewController;
    
    SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url];
    
    UIColor *tintColor = [UIColor accentColor] ?: [UIColor systemBlueColor];
    safariVC.preferredControlTintColor = tintColor;
    
    [sender presentViewController:safariVC animated:YES completion:nil];
}

+ (BOOL)useIcon {
    return [ZBSettings swipeActionStyle] == ZBSwipeActionStyleIcon;
}

+ (BOOL)darkModeEnabled {
    return [ZBSettings interfaceStyle] >= ZBInterfaceStyleDark;
}

#pragma mark - Headers

+ (NSString *)downloadUserAgent {
    return @"Telesphoreo (Zebra) APT-HTTP/1.0.592";
}

+ (NSDictionary *)downloadHeaders {
    NSString *version = [[UIDevice currentDevice] systemVersion];
    NSString *udid = [ZBDevice UDID];
    NSString *machineIdentifier = [ZBDevice machineID];
    
    return @{@"X-Cydia-ID" : udid, @"User-Agent" : [self downloadUserAgent], @"X-Firmware": version, @"X-Unique-ID" : udid, @"X-Machine" : machineIdentifier};
}

+ (NSString *)depictionUserAgent {
    return [NSString stringWithFormat:@"Cydia/1.1.32 Zebra/%@ (%@; iOS/%@) %@", PACKAGE_VERSION, [ZBDevice deviceType], [[UIDevice currentDevice] systemVersion], [ZBThemeManager stringForCurrentInterfaceStyle]];
}

+ (NSDictionary *)depictionHeaders {
    NSString *version = [[UIDevice currentDevice] systemVersion];
    NSString *udid = [ZBDevice UDID];
    NSString *machineIdentifier = [ZBDevice machineID];
    NSString *tintColor = [UIColor hexStringFromColor:[UIColor accentColor]];
    
    return @{@"X-Cydia-ID": udid, @"X-Firmware": version, @"X-Unique-ID": udid, @"X-Machine": machineIdentifier, @"Payment-Provider": @"API", @"Theme": [ZBThemeManager stringForCurrentInterfaceStyle], @"Tint-Color": tintColor, @"Accept-Language": [[NSLocale preferredLanguages] firstObject]};
}

+ (NSString *)jailbreakType {
    NSString *jailbreak = @"Unknown (Older Jailbreak for < 11.0)";
    if ([ZBDevice isOdyssey]) {
        jailbreak = @"Odyssey";
    }
    else if ([ZBDevice isCheckrain]) {
        jailbreak = @"checkra1n";
    }
    else if ([ZBDevice isChimera]) {
        jailbreak = @"Chimera";
    }
    else if ([ZBDevice isElectra]) {
        jailbreak = @"Electra";
    }
    else if ([ZBDevice isUncover]) {
        jailbreak = @"unc0ver";
    }
    
    return jailbreak;
}

@end
