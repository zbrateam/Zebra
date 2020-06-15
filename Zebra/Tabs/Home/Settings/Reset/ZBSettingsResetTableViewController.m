//
//  ZBSettingsResetTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/20/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SDWebImage;

#import "ZBSettingsResetTableViewController.h"
#import "ZBButtonSettingsTableViewCell.h"

#import <UIColor+GlobalColors.h>
#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <Database/ZBRefreshViewController.h>
#import <WebKit/WebKit.h>

@interface ZBSettingsResetTableViewController ()

@end

@implementation ZBSettingsResetTableViewController

+ (NSArray <NSArray <NSString *> *> *)titles {
    return @[@[@"Restart SpringBoard", @"Refresh Icon Cache"], @[@"Clear Image Cache", @"Clear Web Cache", @"Clear Sources Cache"], @[@"Reset All Settings", @"Erase All Sources", @"Erase All Sources and Settings"]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Reset", @"");

    [self.tableView registerClass:[ZBButtonSettingsTableViewCell class] forCellReuseIdentifier:@"settingsButtonCell"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self class] titles].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self class] titles][section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBButtonSettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsButtonCell" forIndexPath:indexPath];
    
    cell.textLabel.text = NSLocalizedString([[self class] titles][indexPath.section][indexPath.row], @"");
    [cell applyStyling];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    [self restartSpringBoard:indexPath];
                    break;
                case 1:
                    [self refreshIconCache:indexPath];
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    [self resetImageCache:indexPath];
                    break;
                case 1:
                    [self resetWebCache:indexPath];
                    break;
                case 2:
                    [self resetSourcesCache:indexPath];
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    [self resetAllSettings:YES indexPath:indexPath];
                    break;
                case 1:
                    [self eraseAllSources:YES indexPath:indexPath];
                    break;
                case 2:
                    [self eraseSourcesAndSettings:indexPath];
                    break;
            }
            break;
    }
}

#pragma mark - Button Actions

- (void)restartSpringBoard:(NSIndexPath *)indexPath {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Restart SpringBoard", @"") message:NSLocalizedString(@"Are you sure you want to restart the SpringBoard?", @"") callback:^{
        [ZBDevice restartSpringBoard];
    } indexPath:indexPath];
}

- (void)refreshIconCache:(NSIndexPath *)indexPath {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Refresh Icon Cache", @"") message:NSLocalizedString(@"Are you sure you want to refresh the icon cache? Your device may become unresponsive until the process is complete.", @"") callback:^{
        [ZBDevice uicache:nil observer:nil];
    } indexPath:indexPath];
}

- (void)resetImageCache:(NSIndexPath *)indexPath {
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Image Cache Cleared", @"") message:NULL preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)resetSourcesCache:(NSIndexPath *)indexPath {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Clear Sources Cache", @"") message:NSLocalizedString(@"Are you sure you want to reset Zebra's source cache? This will remove all cached information from Zebra's database and redownload it. Your sources will not be deleted.", @"") callback:^{
        ZBRefreshViewController *refreshController = [[ZBRefreshViewController alloc] initWithDropTables:YES];
        [self presentViewController:refreshController animated:YES completion:nil];
    } indexPath:indexPath];
}

- (void)resetWebCache:(NSIndexPath *)indexPath {
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

- (void)resetAllSettings:(BOOL)confirm indexPath:(NSIndexPath *)indexPath {
    if (confirm) {
        [self confirmationControllerWithTitle:NSLocalizedString(@"Reset All Settings", @"") message:NSLocalizedString(@"Are you sure you want to reset Zebra's settings? This will reset all of Zebra's settings back to their default values and Zebra will restart.", @"") callback:^{
            [self resetAllSettings:NO indexPath:indexPath];
            [ZBDevice exitZebra];
        } indexPath:indexPath];
    }
    else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *dict = [defaults dictionaryRepresentation];
        for (id key in dict) {
            [defaults removeObjectForKey:key];
        }
        [defaults synchronize];
    }
}

- (void)eraseAllSources:(BOOL)confirm indexPath:(NSIndexPath *)indexPath {
    if (confirm) {
        [self confirmationControllerWithTitle:NSLocalizedString(@"Erase All Sources", @"") message:NSLocalizedString(@"Are you sure you want to erase all sources? All of your sources will be removed from Zebra and Zebra will restart.", @"") callback:^{
            [self eraseAllSources:NO indexPath:indexPath];
            [ZBDevice exitZebra];
        } indexPath:indexPath];
    }
    else {
        NSError *error = NULL;
        [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate listsLocation] error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"] error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate sourcesListPath] error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate databaseLocation] error:&error];
        if (error) {
            NSLog(@"[Zebra] Error while removing path: %@", error.localizedDescription);
        }
    }
}

- (void)eraseSourcesAndSettings:(NSIndexPath *)indexPath {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Erase All Sources and Settings", @"") message:NSLocalizedString(@"Are you sure you want to erase all sources and settings? All of your sources will be removed from Zebra and your settings will be reset.", @"") callback:^{
        [self confirmationControllerWithTitle:NSLocalizedString(@"Are you sure?", @"") message:NSLocalizedString(@"All of your sources will be deleted and be gone forever and Zebra will restart.", @"") callback:^{
            [self resetAllSettings:NO indexPath:indexPath];
            
            NSError *error = NULL;
            [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate listsLocation] error:&error];
            [[NSFileManager defaultManager] removeItemAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"] error:&error];
            [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate sourcesListPath] error:&error];
            [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate databaseLocation] error:&error];
            if (error) {
                NSLog(@"[Zebra] Error while removing path: %@", error.localizedDescription);
            }
            
            [ZBDevice exitZebra];
        } indexPath:indexPath];
    } indexPath:indexPath];
}

- (void)confirmationControllerWithTitle:(NSString *)title message:(NSString *)message callback:(void(^)(void))callback indexPath:(NSIndexPath *)indexPath {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:[self alertControllerStyle]];
    
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callback();
        });
    }];
    [alert addAction:yesAction];
    
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:noAction];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (UIAlertControllerStyle)alertControllerStyle {
    return [[ZBDevice deviceType] isEqualToString:@"iPad"] ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet;
}

@end
