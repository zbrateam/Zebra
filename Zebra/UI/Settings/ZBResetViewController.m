//
//  ZBResetViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/20/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SDWebImage;

#import "ZBResetViewController.h"

#import "Zebra-Swift.h"
#import "ZBAppDelegate.h"

@import WebKit;

@interface ZBResetViewController ()

@end

@implementation ZBResetViewController

- (NSArray <NSArray <NSDictionary *> *> *)specifiers {
    return @[
        @[
            @{
                @"text": @"Restart SpringBoard",
                @"type": @(ZBPreferencesCellTypeButton),
                @"action": @"restartSpringBoard:"
            },
            @{
                @"text": @"Refresh Icon Cache",
                @"type": @(ZBPreferencesCellTypeButton),
                @"action": @"refreshIconCache:"
            }
        ],
        @[
            @{
                @"text": @"Clear Image Cache",
                @"type": @(ZBPreferencesCellTypeButton),
                @"action": @"resetImageCache"
            },
            @{
                @"text": @"Clear Web Cache",
                @"type": @(ZBPreferencesCellTypeButton),
                @"action": @"resetWebCache"
            },
            @{
                @"text": @"Clear Sources Cache",
                @"type": @(ZBPreferencesCellTypeButton),
                @"action": @"resetSourcesCache:"
            }
        ],
        @[
            @{
                @"text": @"Reset All Settings",
                @"type": @(ZBPreferencesCellTypeButton),
                @"action": @"resetAllSettings:"
            },
            @{
                @"text": @"Erase All Sources",
                @"type": @(ZBPreferencesCellTypeButton),
                @"action": @"eraseAllSources:"
            },
            @{
                @"text": @"Erase All Sources and Settings",
                @"type": @(ZBPreferencesCellTypeButton),
                @"action": @"eraseSourcesAndSettings:"
            }
        ]
    ];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Reset", @"");
}

#pragma mark - Button Actions

- (void)restartSpringBoard:(id)sender {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Restart SpringBoard", @"") message:NSLocalizedString(@"Are you sure you want to restart the SpringBoard?", @"") callback:^{
        [ZBDeviceCommands restartSystemApp];
    } cell:sender];
}

- (void)refreshIconCache:(id)sender {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Refresh Icon Cache", @"") message:NSLocalizedString(@"Are you sure you want to refresh the icon cache? Your device may become unresponsive until the process is complete.", @"") callback:^{
        [ZBDeviceCommands uicacheWithPaths:nil];
    } cell:sender];
}

- (void)resetImageCache {
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Image Cache Cleared", @"") message:NULL preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)resetWebCache {
    NSSet *dataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeDiskCache,
                                             WKWebsiteDataTypeMemoryCache,
    ]];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:dataTypes
                                               modifiedSince:[NSDate dateWithTimeIntervalSince1970:0]
                                           completionHandler:^{
    }];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Web Cache Cleared", @"") message:NULL preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil]];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)resetSourcesCache:(id)sender {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Clear Sources Cache", @"") message:NSLocalizedString(@"Are you sure you want to reset Zebra's source cache? This will remove all cached information and Zebra will restart. Your sources will not be deleted.", @"") callback:^{
        NSString *cacheDirectory = nil;//[ZBAppDelegate cacheDirectory];
        [[NSFileManager defaultManager] removeItemAtPath:[cacheDirectory stringByAppendingPathComponent:@"lists"] error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[cacheDirectory stringByAppendingPathComponent:@"logs"] error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[cacheDirectory stringByAppendingPathComponent:@"archives"] error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[cacheDirectory stringByAppendingPathComponent:@"extended_states"] error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[cacheDirectory stringByAppendingPathComponent:@"pkgcache.bin"] error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[cacheDirectory stringByAppendingPathComponent:@"srcpkgcache.bin"] error:nil];
        [ZBDeviceCommands relaunchZebra];
    } cell:sender];
}

- (void)resetAllSettings:(id)sender {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Reset All Settings", @"") message:NSLocalizedString(@"Are you sure you want to reset Zebra's settings? This will reset all of Zebra's settings back to their default values and Zebra will restart.", @"") callback:^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *dict = [defaults dictionaryRepresentation];
        for (id key in dict) {
            [defaults removeObjectForKey:key];
        }
        [defaults synchronize];
        [ZBDeviceCommands relaunchZebra];
    } cell:sender];
}

- (void)eraseAllSources:(id)sender {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Erase All Sources", @"") message:NSLocalizedString(@"Are you sure you want to erase all sources? All of your sources will be removed and Zebra will restart.", @"") callback:^{
        NSString *cacheDirectory = nil;//[ZBAppDelegate cacheDirectory];
        [[NSFileManager defaultManager] removeItemAtPath:[cacheDirectory stringByAppendingPathComponent:@"zebra.sources"] error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[cacheDirectory stringByAppendingPathComponent:@"lists"] error:nil];
        [ZBDeviceCommands relaunchZebra];
    } cell:sender];
}

- (void)eraseSourcesAndSettings:(id)sender {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Erase All Sources and Settings", @"") message:NSLocalizedString(@"Are you sure you want to erase all sources and settings? All of your sources will be removed, your settings will be reset, and Zebra will restart.", @"") callback:^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *dict = [defaults dictionaryRepresentation];
        for (id key in dict) {
            [defaults removeObjectForKey:key];
        }
        [defaults synchronize];
        
        NSString *cacheDirectory = nil;//[ZBAppDelegate cacheDirectory];
        [[NSFileManager defaultManager] removeItemAtPath:[cacheDirectory stringByAppendingPathComponent:@"zebra.sources"] error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[cacheDirectory stringByAppendingPathComponent:@"lists"] error:nil];
        [ZBDeviceCommands relaunchZebra];
    } cell:sender];
}

- (void)confirmationControllerWithTitle:(NSString *)title message:(NSString *)message callback:(void(^)(void))callback cell:(UITableViewCell *)cell {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        callback();
    }];
    [alert addAction:yesAction];
    
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:noAction];
    
    alert.popoverPresentationController.sourceView = cell;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

@end
