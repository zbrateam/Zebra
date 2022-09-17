//
//  ZBDevice.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 7/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBDevice.h"
#import "ZBSettings.h"
#import "ZBCommand.h"
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
#import <dlfcn.h>
#import <objc/runtime.h>
@import SafariServices;

static BOOL isStashed = NO;
static BOOL isPrefixed = NO;
static ZBJailbreak jailbreak = ZBJailbreakUnknown;
static ZBBootstrap bootstrap = ZBBootstrapUnknown;

@implementation ZBDevice

+ (NSString *)userAgent {
    return [NSString stringWithFormat:@"Zebra/%@ (%@; iOS/%@)", @PACKAGE_VERSION, [ZBDevice deviceType], [[UIDevice currentDevice] systemVersion]];
}

+ (NSString *)downloadUserAgent {
    return isPrefixed ? self.userAgent : @"Telesphoreo (Zebra) APT-HTTP/1.0.592";
}

+ (NSString *)webUserAgent {
    return [NSString stringWithFormat:@"%@%@ %@",
            isPrefixed ? @"" : @"Cydia/1.1.32 ",
            self.userAgent,
            self.themeName];
}

+ (NSString *)themeName {
    switch ([ZBSettings interfaceStyle]) {
    case ZBInterfaceStyleLight:     return @"Light";
    case ZBInterfaceStyleDark:      return @"Dark";
    case ZBInterfaceStylePureBlack: return @"Pure-Black";
    }
}

+ (BOOL)needsSimulation {
#if TARGET_OS_SIMULATOR
    return YES;
#else
    static BOOL value = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 14, *)) {
            value = [self isSlingshotBroken:nil];
        } else {
            value = ![[NSFileManager defaultManager] fileExistsAtPath:@INSTALL_PREFIX @"/usr/libexec/zebra/supersling"];
        }
    });
    return value;
#endif
}

+ (BOOL)isSlingshotBroken:(NSError *_Nullable*_Nullable)error {
    // Check to see if su/sling has the proper setuid/setgid bit
    // We shouldn't do a dispatch_once because who knows when the file could be changed
    // Returns YES if su/sling's setuid/setgid permissions need to be reset
    if (@available(iOS 14, *)) {
        NSString *whoAmI = [ZBCommand execute:@INSTALL_PREFIX @"/usr/bin/id" withArguments:@[@"-u"] asRoot:YES] ?: @"?";
        if (![whoAmI isEqualToString:@"0\n"]) {
            if (error) {
                *error = [NSError errorWithDomain:NSCocoaErrorDomain code:51 userInfo:@{
                    NSLocalizedDescriptionKey: NSLocalizedString(@"Zebra doesn’t have permission to install packages on this device. Please reinstall Zebra.", @"")
                }];
            }
            return YES;
        }

        return NO;
    }

    if ([ZBDevice needsSimulation]) {
        return NO; //Since simulated devices don't have su/sling, it isn't broken!
    }
    
    struct stat path_stat;
    stat(INSTALL_PREFIX "/usr/libexec/zebra/supersling", &path_stat);
    
    if (path_stat.st_uid != 0 || path_stat.st_gid != 0) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:51 userInfo:@{
                NSLocalizedDescriptionKey: NSLocalizedString(@"su/sling is not owned by root:wheel. Please verify the permissions of the file located at " @INSTALL_PREFIX @"/usr/libexec/zebra/supersling.", @"")
            }];
        }
        return YES; //If the uid/gid aren't 0 then theres a problem
    }
    
    //Check the uid/gid bits of permissions
    BOOL cannot_set_uid = (path_stat.st_mode & S_ISUID) == 0;
    BOOL cannot_set_gid = (path_stat.st_mode & S_ISGID) == 0;
    if (cannot_set_uid || cannot_set_gid) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:52 userInfo:@{
                NSLocalizedDescriptionKey: NSLocalizedString(@"su/sling does not have permission to set the uid or gid. Please verify the permissions of the file located at " @INSTALL_PREFIX @"/usr/libexec/zebra/supersling.", @"")
            }];
        }
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
    return @DEB_ARCH;
}

+ (void)hapticButton {
    if (@available(iOS 10, *)) {
        UISelectionFeedbackGenerator *feedback = [[UISelectionFeedbackGenerator alloc] init];
        [feedback prepare];
        [feedback selectionChanged];
        feedback = nil;
    }
}

+ (void)restartSpringBoard {
    if (![self needsSimulation]) {
        if (@available(iOS 11, *)) {
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

+ (void)load {
    [super load];

    isPrefixed = ![@INSTALL_PREFIX isEqualToString:@""];

    if (self.needsSimulation) {
        jailbreak = ZBJailbreakSimulated;
    } else if ([self _isRegularFile:@"/var/checkra1n.dmg"] || [self _isRegularDirectory:@"/binpack"]) {
        jailbreak = ZBJailbreakCheckrain;
    } else if ([self _isRegularFile:@"/.installed_unc0ver"]) {
        jailbreak = ZBJailbreakUncover;
    } else if ([self _isRegularDirectory:@"/electra"]) {
        jailbreak = ZBJailbreakElectra;
    } else if ([self _isRegularDirectory:@"/chimera"]) {
        jailbreak = ZBJailbreakChimera;
    } else if ([self _isRegularFile:@"/.installed_odyssey"]) {
        jailbreak = ZBJailbreakOdyssey;
    } else if ([self _isRegularFile:@"/.installed_taurine"]) {
        jailbreak = ZBJailbreakTaurine;
    } else if ([self _isRegularFile:@INSTALL_PREFIX @"/.installed_cheyote"]) {
        jailbreak = ZBJailbreakCheyote;
    } else if (@available(iOS 11, *)) {
        jailbreak = ZBJailbreakUnknown;
    } else {
        jailbreak = ZBJailbreakLegacy;
    }

    if (self.needsSimulation) {
        bootstrap = ZBBootstrapSimulated;
    } else if (@available(iOS 11, *)) {
        if ([self _isRegularFile:@INSTALL_PREFIX @"/.procursus_strapped"]) {
            bootstrap = ZBBootstrapProcursus;
        } else {
            bootstrap = ZBBootstrapElucubratus;
        }
    } else {
        bootstrap = ZBBootstrapTelesphoreo;
        isStashed = [self _isRegularDirectory:@"/var/stash"] && ![self _isRegularFile:@"/.cydia_no_stash"];
    }
}

+ (BOOL)isStashed {
    return isStashed;
}

+ (BOOL)isPrefixed {
    return isPrefixed;
}

+ (ZBBootstrap)bootstrap {
    return bootstrap;
}

+ (ZBJailbreak)jailbreak {
    return jailbreak;
}

+ (NSString *)bootstrapName {
    switch (bootstrap) {
    case ZBBootstrapUnknown:     return @"Unknown";
    case ZBBootstrapSimulated:   return @"Simulated";
    case ZBBootstrapTelesphoreo: return @"Telesphoreo";
    case ZBBootstrapProcursus:   return @"Procursus";
    case ZBBootstrapElucubratus: return @"Elucubratus";
    }
}

+ (NSString *)jailbreakName {
    switch (jailbreak) {
    case ZBJailbreakUnknown:   return @"Unknown";
    case ZBJailbreakSimulated: return @"Simulated";
    case ZBJailbreakLegacy:    return @"Legacy Jailbreak";
    case ZBJailbreakCheckrain: return @"checkra1n";
    case ZBJailbreakUncover:   return @"unc0ver";
    case ZBJailbreakElectra:   return @"Electra";
    case ZBJailbreakChimera:   return @"Chimera";
    case ZBJailbreakOdyssey:   return @"Odyssey";
    case ZBJailbreakTaurine:   return @"Taurine";
    case ZBJailbreakCheyote:   return @"Cheyote";
    }
}

+ (NSString *)packageManagementBinary {
    static NSString *packageManagementBinary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:@INSTALL_PREFIX @"/usr/bin/apt"]) {
            packageManagementBinary = @INSTALL_PREFIX @"/usr/bin/apt";
        }
        else if ([[NSFileManager defaultManager] fileExistsAtPath:@INSTALL_PREFIX @"/usr/bin/dpkg"]) {
            packageManagementBinary = @INSTALL_PREFIX @"/usr/bin/dpkg";
        }
    });
    return packageManagementBinary;
}

+ (NSString *)path {
    // Construct a safe PATH. This will be set app-wide.
    NSArray <NSString *> *path = @[@"/usr/sbin", @"/usr/bin", @"/sbin", @"/bin"];
    if (isPrefixed) {
        NSMutableArray <NSString *> *prefixedPath = [NSMutableArray array];
        for (NSString *item in path) {
            [prefixedPath addObject:[@INSTALL_PREFIX stringByAppendingPathComponent:item]];
        }
        path = [prefixedPath arrayByAddingObjectsFromArray:path];
    }
    return [path componentsJoinedByString:@":"];
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
        return @"iPod touch";
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
    if (@available(iOS 10, *)) {
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

+ (BOOL)buttonShapesEnabled {
    if (@available(iOS 14, *)) {
        return UIAccessibilityButtonShapesEnabled();
    }

    // Use the old private function for this. Its implementation is identical to the public one.
    static BOOL (*_UIAccessibilityButtonShapesEnabled)(void);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void *uikit = dlopen("/System/Library/Frameworks/UIKit.framework/UIKit", RTLD_LAZY);
        if (uikit) {
            _UIAccessibilityButtonShapesEnabled = dlsym(uikit, "_UIAccessibilityButtonShapesEnabled");
        }
    });
    return _UIAccessibilityButtonShapesEnabled ? _UIAccessibilityButtonShapesEnabled() : NO;
}

@end
