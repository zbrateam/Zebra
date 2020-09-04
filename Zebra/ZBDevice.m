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
#import <Theme/ZBThemeManager.h>
#import <Queue/ZBQueue.h>
#import "ZBAppDelegate.h"
#import "MobileGestalt.h"
#import <UIKit/UIDevice.h>
#import <Headers/NSTask.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <unistd.h>

@import SafariServices;
@import LNPopupController;
@import FirebaseCrashlytics;
@import Foundation;
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
    UISelectionFeedbackGenerator *feedback = [[UISelectionFeedbackGenerator alloc] init];
    [feedback prepare];
    [feedback selectionChanged];
    feedback = nil;
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

+ (void)restartSpringBoard {
    if (![self needsSimulation]) {
        BOOL failed = NO;
        
        //Try sbreload
        NSLog(@"[Zebra] Trying sbreload");
        @try {
            [self runCommandInPath:@"sbreload" asRoot:NO observer:nil];
        }
        @catch (NSException *e) {
            [[FIRCrashlytics crashlytics] logWithFormat:@"Could not spawn sbreload. %@: %@", e.name, e.reason];
            NSLog(@"[Zebra] Could not spawn sbreload. %@: %@", e.name, e.reason);
            failed = YES;
        }
        
        //Try launchctl
        if (failed) {
            NSLog(@"[Zebra] Trying launchctl");
            failed = NO;
            
            @try {
                [self runCommandInPath:@"launchctl stop com.apple.backboardd" asRoot:YES observer:nil];
            }
            @catch (NSException *e) {
                [[FIRCrashlytics crashlytics] logWithFormat:@"Could not spawn launchctl. %@: %@", e.name, e.reason];
                NSLog(@"[Zebra] Could not spawn launchctl. %@: %@", e.name, e.reason);
                failed = YES;
            }
        }
        
        //Try killall
        if (failed) {
            NSLog(@"[Zebra] Trying killall");
            failed = NO;
            
            @try {
                [self runCommandInPath:@"killall -9 backboardd" asRoot:YES observer:nil];
            }
            @catch (NSException *e) {
                [[FIRCrashlytics crashlytics] logWithFormat:@"Could not spawn killall. %@: %@", e.name, e.reason];
                NSLog(@"[Zebra] Could not spawn killall. %@: %@", e.name, e.reason);
                failed = YES;
            }
        }
        
        if (failed) {
            [ZBAppDelegate sendErrorToTabController:NSLocalizedString(@"Could not respring. Please respring manually.", @"")];
        }
    }
}

+ (void)uicache:(NSArray *_Nullable)arguments observer:(NSObject <ZBConsoleCommandDelegate> * _Nullable)observer {
    if (!arguments || [arguments count] == 0) {
        NSString *command = @"uicache -a";
        
        @try {
            [self runCommandInPath:command asRoot:NO observer:observer];
        }
        @catch (NSException *e) {
            [[FIRCrashlytics crashlytics] logWithFormat:@"%@ Could not spawn uicache. Reason: %@", e.name, e.reason];
            NSLog(@"[Zebra] %@ Could not spawn uicache. Reason: %@", e.name, e.reason);
        }
    }
    else {
        NSMutableString *command = [@"uicache" mutableCopy];
        for (NSString *argument in arguments) {
            [command appendString:@" "];
            [command appendString:argument];
        }
        
        @try {
            [self runCommandInPath:command asRoot:NO observer:observer];
        }
        @catch (NSException *e) {
            [[FIRCrashlytics crashlytics] logWithFormat:@"%@ Could not spawn uicache. Reason: %@", e.name, e.reason];
            NSLog(@"[Zebra] %@ Could not spawn uicache. Reason: %@", e.name, e.reason);
        }
    }
}

+ (void)runCommandInPath:(NSString *_Nonnull)command asRoot:(BOOL)sling observer:(NSObject <ZBConsoleCommandDelegate> *_Nullable)observer {
    NSDictionary *environmentDict = [[NSProcessInfo processInfo] environment];
    NSString *shellPath = [environmentDict objectForKey:@"SHELL"];
    
    NSString *binary = [command componentsSeparatedByString:@" "][0];
    if (![self locateCommandInPath:binary shell:shellPath]) {
        NSException *exception = [NSException exceptionWithName:@"Binary not found" reason:[NSString stringWithFormat:@"%@ doesn't exist in $PATH", binary] userInfo:nil];
        @throw exception;
    }
    
    NSTask *task = [[NSTask alloc] init];
    
    if (sling) {
        [task setLaunchPath:@"/usr/libexec/zebra/supersling"];
        [task setArguments:@[shellPath, @"-c", command]];
    }
    else {
        [task setLaunchPath:shellPath];
        [task setArguments:@[@"-c", command]];
    }
    
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
    
    @try {
        [task launch];
        [task waitUntilExit];
    }
    @catch (NSException *e) {
        [[FIRCrashlytics crashlytics] logWithFormat:@"%@ Could not spawn %@. Reason: %@", e.name, command, e.reason];
        NSLog(@"[Zebra] %@ Could not spawn %@. Reason: %@", e.name, command, e.reason);
        @throw e;
    }
}

+ (NSString *)locateCommandInPath:(NSString *)command shell:(NSString *)shellPath {
    NSLog(@"[Zebra] Locating %@", command);
    NSLog(@"[Zebra] Shell: %@", shellPath);
    
    NSTask *which = [[NSTask alloc] init];
    [which setLaunchPath:shellPath];
    [which setArguments:@[@"-c", [NSString stringWithFormat:@"which %@", command]]];

    NSPipe *outPipe = [NSPipe pipe];
    [which setStandardOutput:outPipe];

    [which launch];
    [which waitUntilExit];

    NSFileHandle *read = [outPipe fileHandleForReading];
    NSData *dataRead = [read readDataToEndOfFile];
    NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    if ([stringRead containsString:@"not found"] || [stringRead isEqualToString:@""]) {
        NSLog(@"[Zebra] Can't find %@", command);
        return NULL;
    }
    
    NSLog(@"[Zebra] %@ location: %@", command, stringRead);
    
    return stringRead;
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
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/dpkg"]) {
            packageManagementBinary = @"/usr/bin/dpkg";
        }
        else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/apt"]) {
            packageManagementBinary = @"/usr/bin/apt";
        }
    });
    return packageManagementBinary;
}

+ (NSString * _Nonnull)deviceType {
    return [[UIDevice currentDevice] model];
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

+ (void)openURL:(NSURL *)url sender:(UIViewController *)sender {
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

@end
