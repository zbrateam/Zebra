//
//  ZBHomeViewController.m
//  Zebra
//
//  Created by midnightchips on 7/1/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBHomeViewController.h"

#import "ZBQueueViewController.h"
#import "ZBCreditsViewController.h"

#import "ZBAppDelegate.h"
#import "ZBSettingsViewController.h"

#import <SafariServices/SafariServices.h>
#import "Zebra-Swift.h"

@interface ZBHomeViewController ()
@end

@implementation ZBHomeViewController

- (instancetype)init {
    if (@available(iOS 13.0, *)) {
        self = [super initWithStyle:UITableViewStyleInsetGrouped];
    } else {
        self = [super initWithStyle:UITableViewStyleGrouped];
    }
    
    if (self) {
        self.title = NSLocalizedString(@"Home", @"");
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // The world (and I) isn't ready for settings yet.
//    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
//    self.navigationItem.rightBarButtonItem = settingsButton;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"homeCell"];
}

#pragma mark - Table view data source

- (NSArray <NSString *> *)titles {
    return @[NSLocalizedString(@"Info", @""), @"", NSLocalizedString(@"Community", @""), @""];
}

- (NSArray <NSArray <NSDictionary *> *> *)cells {
    return @[
        @[
            @{@"text": NSLocalizedString(@"Welcome to Zebra!", @"")},
            @{
                @"text": NSLocalizedString(@"Report a Bug", @""),
                @"icon": @"Bugs",
                @"link": @"https://getzbra.com/repo/depictions/xyz.willy.Zebra/bug_report.html"
            }
        ],
        @[
            @{
                @"text": NSLocalizedString(@"Changelog", @""),
                @"icon": @"Changelog",
                @"class": @"ZBChangelogViewController"
            }
        ],
        @[
            @{
                @"text": NSLocalizedString(@"Join our Discord", @""),
                @"icon": @"Discord",
                @"link": @"https://discord.gg/6CPtHBU"
            },
            @{
                @"text": NSLocalizedString(@"Follow us on Twitter", @""),
                @"icon": @"Twitter",
                @"link": @"https://twitter.com/getzebra"
            }
        ],
        @[
            @{
                @"text": NSLocalizedString(@"Credits", @""),
                @"icon": @"Credits",
                @"class": @"ZBCreditsViewController"
            }
        ]
    ];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self cells] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self cells][section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"homeCell" forIndexPath:indexPath];
    
    NSDictionary *info = [self cells][indexPath.section][indexPath.row];
    cell.textLabel.text = info[@"text"];
    
    NSString *imageName = info[@"icon"];
    if (imageName) {
        cell.imageView.image = [UIImage imageNamed:imageName];
        
        CGSize itemSize = CGSizeMake(29, 29);
        UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
        CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
        [cell.imageView.image drawInRect:imageRect];
        cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell.imageView.layer setCornerRadius:7];
        [cell.imageView setClipsToBounds:YES];
    }
    
    if (info[@"link"] || info[@"class"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = [self titles][section];
    if (![title isEqual:@""]) {
        return title;
    }
    return NULL;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == [self cells].count - 1) {
        UIDevice *device = [UIDevice currentDevice];
        return [NSString stringWithFormat:@"%@ - %@ %@ - Zebra %@\n%@", device.zbra_machine, device.zbra_osName, device.zbra_osVersion, PACKAGE_VERSION, device.zbra_udid];
    }
    return NULL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *info = [self cells][indexPath.section][indexPath.row];
    
    if (info[@"class"]) {
        Class class = NSClassFromString(info[@"class"]);
        NSObject *vc = [[class alloc] init];
        if (vc && [vc respondsToSelector:@selector(presentViewController:animated:completion:)]) {
            [[self navigationController] pushViewController:(UIViewController *)vc animated:YES];
        } else if (class) {
            UIAlertController *cannotPresent = [UIAlertController alertControllerWithTitle:@"Cannot present controller" message:[NSString stringWithFormat:@"The class \"%@\" cannot be presented.", info[@"class"]] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
            [cannotPresent addAction:okAction];
            
            [self presentViewController:cannotPresent animated:YES completion:nil];
        }
    } else if (info[@"link"]) {
        NSURL *url = [NSURL URLWithString:info[@"link"]];
        if (url && ([url.scheme isEqual:@"http"] || [url.scheme isEqual:@"https"])) {
            SFSafariViewController *sfVC = [[SFSafariViewController alloc] initWithURL:url];
            [self presentViewController:sfVC animated:YES completion:nil];
        }
    }
}

#pragma mark - Settings

- (void)showQueue {
    ZBQueueViewController *queue = [[ZBQueueViewController alloc] init];
    [self presentViewController:queue animated:YES completion:nil];
}

- (void)showSettings {
    ZBSettingsViewController *settingsController = [[ZBSettingsViewController alloc] init];
    [[self navigationController] presentViewController:settingsController animated:YES completion:nil];
}

@end
