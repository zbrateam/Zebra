//
//  ZBResetViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/20/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SDWebImage;

#import "ZBResetViewController.h"
#import "UITableView+Settings.h"
#import "ZBButtonSettingsTableViewCell.h"

#import <Extensions/ZBColor.h>
#import <ZBAppDelegate.h>
#import <ZBDevice.h>

@import WebKit;

@interface ZBResetViewController ()

@end

@implementation ZBResetViewController

- (NSArray <NSArray <NSDictionary *> *> *)specifiers {
    return @[
        @[
            @{
                @"text": @"Restart SpringBoard",
                @"action": @"restartSpringBoard:"
            },
            @{
                @"text": @"Refresh Icon Cache",
                @"action": @"refreshIconCache:"
            }
        ],
        @[
            @{
                @"text": @"Clear Image Cache",
                @"action": @"resetImageCache"
            },
            @{
                @"text": @"Clear Web Cache",
                @"action": @"resetWebCache"
            },
            @{
                @"text": @"Clear Sources Cache",
                @"action": @"resetSourcesCache:"
            }
        ],
        @[
            @{
                @"text": @"Reset All Settings",
                @"action": @"resetAllSettings:"
            },
            @{
                @"text": @"Erase All Sources",
                @"action": @"eraseAllSources:"
            },
            @{
                @"text": @"Erase All Sources and Settings",
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
        [ZBDevice restartSpringBoard];
    } cell:sender];
}

- (void)refreshIconCache:(id)sender {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Refresh Icon Cache", @"") message:NSLocalizedString(@"Are you sure you want to refresh the icon cache? Your device may become unresponsive until the process is complete.", @"") callback:^{
        [ZBDevice uicache:nil];
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
//    [self confirmationControllerWithTitle:NSLocalizedString(@"Clear Sources Cache", @"") message:NSLocalizedString(@"Are you sure you want to reset Zebra's source cache? This will remove all cached information from Zebra's database and redownload it. Your sources will not be deleted.", @"") callback:^{
//        ZBMigrationViewController *refreshController = [[ZBMigrationViewController alloc] init];
//        [self presentViewController:refreshController animated:YES completion:nil];
//    } indexPath:indexPath];
}

- (void)resetAllSettings:(id)sender {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Reset All Settings", @"") message:NSLocalizedString(@"Are you sure you want to reset Zebra's settings? This will reset all of Zebra's settings back to their default values and Zebra will restart.", @"") callback:^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *dict = [defaults dictionaryRepresentation];
        for (id key in dict) {
            [defaults removeObjectForKey:key];
        }
        [defaults synchronize];
        [ZBDevice relaunchZebra];
    } cell:sender];
}

- (void)eraseAllSources:(id)sender {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Erase All Sources", @"") message:NSLocalizedString(@"Are you sure you want to erase all sources? All of your sources will be removed from Zebra and Zebra will restart.", @"") callback:^{
        NSError *error = NULL;
        [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate listsLocation] error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"] error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate sourcesListPath] error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate databaseLocation] error:&error];
        if (error) {
            NSLog(@"[Zebra] Error while removing path: %@", error.localizedDescription);
        }
        [ZBDevice relaunchZebra];
    } cell:sender];
}

- (void)eraseSourcesAndSettings:(id)sender {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Erase All Sources and Settings", @"") message:NSLocalizedString(@"Are you sure you want to erase all sources and settings? All of your sources will be removed from Zebra and your settings will be reset.", @"") callback:^{
        [self confirmationControllerWithTitle:NSLocalizedString(@"Are you sure?", @"") message:NSLocalizedString(@"All of your sources will be deleted and be gone forever and Zebra will restart.", @"") callback:^{
            
            NSError *error = NULL;
            [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate listsLocation] error:&error];
            [[NSFileManager defaultManager] removeItemAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"] error:&error];
            [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate sourcesListPath] error:&error];
            [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate databaseLocation] error:&error];
            if (error) {
                NSLog(@"[Zebra] Error while removing path: %@", error.localizedDescription);
            }
            
            [ZBDevice relaunchZebra];
        } cell:sender];
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
