//
//  ZBDevice.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 7/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBDevice.h"
#import "ZBSettings.h"
#import "UIColor+GlobalColors.h"
#import <WebKit/WebKit.h>
#import "ZBQueue.h"
#import "ZBAppDelegate.h"
#import "MobileGestalt.h"
#import <UIKit/UIDevice.h>
#import "ZBCommand.h"
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <unistd.h>
@import SafariServices;
@import LNPopupController;

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
    
    return NO; //su/sling is  ok
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
    if (@available(iOS 10.0, *)) {
        UISelectionFeedbackGenerator *feedback = [[UISelectionFeedbackGenerator alloc] init];
        [feedback prepare];
        [feedback selectionChanged];
        feedback = nil;
    }
}

+ (void)restartSpringBoard {
    if (![self needsSimulation]) {
        if (@available(iOS 11.0, *)) {
            //Try sbreload
            NSLog(@"[Zebra] Trying sbreload");
            if ([ZBCommand execute:@"sbreload" withArguments:@[] asRoot:NO]) {
                return;
            }
        }
        
        //Try launchctl
        NSLog(@"[Zebra] Trying launchctl");
        if ([ZBCommand execute:@"launchctl" withArguments:@[@"stop", @"com.apple.backboardd"] asRoot:YES]) {
            return;
        }
        
        //Try killall
        NSLog(@"[Zebra] Trying killall");
        if ([ZBCommand execute:@"killall" withArguments:@[@"-9", @"backboardd"] asRoot:YES]) {
            return;
        }

        [ZBAppDelegate sendErrorToTabController:NSLocalizedString(@"Could not respring. Please respring manually.", @"")];
    }
}

+ (void)restartDevice {
    if (![self needsSimulation]) {
        if (@available(iOS 11.0, *)) {
            //Try sbreload
            NSLog(@"[Zebra] Trying ldrestart");
            if ([ZBCommand execute:@"sync" withArguments:@[] asRoot:YES] &&
                [ZBCommand execute:@"ldrestart" withArguments:@[] asRoot:YES]) {
                return;
            }
        }

        NSLog(@"[Zebra] Trying reboot");
        if ([ZBCommand execute:@"reboot" withArguments:@[] asRoot:YES]) {
           return;
        }

        [ZBAppDelegate sendErrorToTabController:NSLocalizedString(@"Could not restart. Please restart manually.", @"")];
    }
}

+ (void)uicache:(NSArray *_Nullable)arguments observer:(NSObject <ZBCommandDelegate> * _Nullable)observer {
    if (!arguments || [arguments count] == 0) {
        arguments = @[@"-a"];
    }

    if ([ZBCommand execute:@"uicache" withArguments:arguments asRoot:NO]) {
        return;
    }

    NSLog(@"[Zebra] Could not spawn uicache");
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

+ (BOOL)isOdyssey {
    static BOOL value = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [self needsSimulation] ? NO : [self _isRegularFile:@"/.installed_odyssey"];
    });
    return value;
}

+ (BOOL)isTaurine {
    static BOOL value = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [self needsSimulation] ? YES : [self _isRegularFile:@"/.installed_taurine"];
    });
    return value;
}

+ (BOOL)hasProcursus {
    static BOOL value = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [self needsSimulation] ? NO : [self _isRegularFile:@"/.procursus_strapped"];
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
    NSString *model = [ZBDevice machineID];
    if ([model hasPrefix:@"iPhone"]) {
        return @"iPhone";
    }
    if ([model hasPrefix:@"iPad"]) {
        return @"iPad";
    }
    if ([model hasPrefix:@"iPod"]) {
        return @"iPod";
    }
    return @"iPhone/iPod";
}

+ (void)exitZebra {
    [self exitZebraAfter:1];
}

+ (void)exitZebraAfter:(int)seconds {
    [[UIApplication sharedApplication] suspend];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });
}

#pragma mark - Theming

+ (void)openURL:(NSURL *)url delegate:(UIViewController <SFSafariViewControllerDelegate> *)delegate {
    SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url];
    safariVC.delegate = delegate;
    UIColor *tintColor = [UIColor accentColor] ?: [UIColor systemBlueColor];
    if (@available(iOS 10.0, *)) {
        safariVC.preferredBarTintColor = [UIColor groupedTableViewBackgroundColor];
        safariVC.preferredControlTintColor = tintColor;
    } else {
        safariVC.view.tintColor = tintColor;
    }
    [delegate presentViewController:safariVC animated:YES completion:nil];
}

+ (BOOL)useIcon {
    return [ZBSettings swipeActionStyle] == ZBSwipeActionStyleIcon;
}

+ (BOOL)darkModeEnabled {
    return [ZBSettings interfaceStyle] >= ZBInterfaceStyleDark;
}

@end
