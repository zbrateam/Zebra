//
//  ZBCreditsTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 10/25/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBCreditsTableViewController.h"
#import "UIColor+GlobalColors.h"
#import "ZBDevice.h"
#import "ZBSettings.h"
#import "NSURLSession+Zebra.h"
#import "ZBCredits.h"

@interface ZBCreditsTableViewController ()

@end

@implementation ZBCreditsTableViewController

@synthesize credits;

- (BOOL)hasSpinner {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (credits == NULL) {
        [self fetchCredits];
    }
}

#pragma mark - Table view data source

- (void)fetchCredits {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:@"https://api.getzbra.com/credits.json"]];

    NSURLSessionDataTask *task = [[NSURLSession zbra_standardSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, __unused NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSArray <ZBCreditsSection *> *newCredits = nil;
        if (data && !error) {
            newCredits = [ZBCredits fromData:data error:nil].sections;
        }
        else {
            NSLog(@"[Zebra] Error while trying to access credits: %@", error);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self->credits = newCredits;
            [self.tableView reloadData];
            self.navigationItem.titleView = NULL;
            self.navigationItem.title = NSLocalizedString(@"Credits", @"");
        });
    }];
    
    [task resume];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return credits.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return credits[section].items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    ZBCreditsItem *item = credits[indexPath.section].items[indexPath.row];
    
    if (indexPath.section == 3) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"libraryCreditTableViewCell" forIndexPath:indexPath];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [cell.textLabel setTextColor:[UIColor primaryTextColor]];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"personCreditTableViewCell" forIndexPath:indexPath];
        if (item.link) {
            [cell.textLabel setTextColor:[UIColor accentColor] ?: [UIColor systemBlueColor]];
        }
        else {
            [cell.textLabel setTextColor:[UIColor primaryTextColor]];
        }
    }
    cell.detailTextLabel.textColor = [UIColor secondaryTextColor];
    
    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = item.subtitle;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(credits[section].title, @"");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ZBCreditsItem *person = credits[indexPath.section].items[indexPath.row];
    NSURL *url = person.link ? [NSURL URLWithString:person.link] : nil;

    if (url) {
        [ZBDevice openURL:url delegate:self];
    }
}

@end
