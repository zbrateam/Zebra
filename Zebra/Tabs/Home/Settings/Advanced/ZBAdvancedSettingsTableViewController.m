//
//  ZBAdvancedSettingsTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/20/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SDWebImage;

#import "ZBAdvancedSettingsTableViewController.h"
#import <UIColor+GlobalColors.h>
#import <ZBAppDelegate.h>
#import <ZBDevice.h>
#import <Database/ZBRefreshViewController.h>

@interface ZBAdvancedSettingsTableViewController ()

@end

@implementation ZBAdvancedSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Advanced", @"");
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
        case 1:
            return 2;
        case 2:
            return 2;
        default:
            return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"settingsAdvancedCell"];
    
    NSArray <NSArray <NSString *> *> *titles = @[@[@"Restart SpringBoard", @"Refresh Icon Cache"], @[@"Reset Image Cache", @"Reset Sources Cache"], @[@"Reset All Settings", @"Erase All Sources and Settings"]];
    cell.textLabel.text = NSLocalizedString(titles[indexPath.section][indexPath.row], @"");
    cell.textLabel.textColor = [UIColor accentColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:true];
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    [self restartSpringBoard];
                    break;
                case 1:
                    [self refreshIconCache];
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    [self resetImageCache];
                    break;
                case 1:
                    [self resetSourcesCache];
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    [self resetAllSettings:true];
                    break;
                case 1:
                    [self eraseSourcesAndSettings];
                    break;
            }
            break;
    }
            
}

#pragma mark - Button Actions

- (void)restartSpringBoard {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Restart SpringBoard", @"") message:NSLocalizedString(@"Are you sure you want to restart the SpringBoard?", @"") callback:^{
        [ZBDevice restartSpringBoard];
    }];
}

- (void)refreshIconCache {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Refresh Icon Cache", @"") message:NSLocalizedString(@"Are you sure you want to refresh the icon cache? Your device may become unresponsive until the process is complete.", @"") callback:^{
        [ZBDevice uicache:nil observer:nil];
    }];
}

- (void)resetImageCache {
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Image Cache Reset", @"") message:NULL preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:true completion:nil];
    });
}

- (void)resetSourcesCache {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Reset Sources Cache", @"") message:NSLocalizedString(@"Are you sure you want to reset Zebra's source cache? This will remove all cached information from Zebra's database and redownload it. Your sources will not be deleted.", @"") callback:^{
        ZBRefreshViewController *refreshController = [[ZBRefreshViewController alloc] initWithDropTables:true];
        [self presentViewController:refreshController animated:YES completion:nil];
    }];
}

- (void)resetAllSettings:(BOOL)confirm {
    if (confirm) {
        [self confirmationControllerWithTitle:NSLocalizedString(@"Reset All Settings", @"") message:NSLocalizedString(@"Are you sure you want to reset Zebra's settings? This will reset all of Zebra's settings back to their default values and Zebra will restart.", @"") callback:^{
            [self resetAllSettings:false];
            [ZBDevice exitZebra];
        }];
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

- (void)eraseSourcesAndSettings {
    [self confirmationControllerWithTitle:NSLocalizedString(@"Erase All Sources and Settings", @"") message:NSLocalizedString(@"Are you sure you want to erase all sources and settings? All of your sources will be removed from Zebra and your settings will be reset.", @"") callback:^{
        [self confirmationControllerWithTitle:NSLocalizedString(@"Are You Sure?", @"") message:NSLocalizedString(@"All of your sources will be deleted and be gone forever and Zebra will restart.", @"") callback:^{
            [self resetAllSettings:false];
            
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate listsLocation] error:&error];
            [[NSFileManager defaultManager] removeItemAtPath:[[ZBAppDelegate documentsDirectory] stringByAppendingPathComponent:@"featured.plist"] error:&error];
            [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate sourcesListPath] error:&error];
            [[NSFileManager defaultManager] removeItemAtPath:[ZBAppDelegate databaseLocation] error:&error];
            if (error) {
                NSLog(@"[Zebra] Error while removing path: %@", error.localizedDescription);
            }
            
            [ZBDevice exitZebra];
        }];
    }];
}

- (void)confirmationControllerWithTitle:(NSString *)title message:(NSString *)message callback:(void(^)(void))callback {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callback();
        });
    }];
    [alert addAction:yesAction];
    
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:noAction];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:true completion:nil];
    });
}

@end
