//
//  ZBCreditsViewController.m
//  Zebra
//
//  Created by Wilson Styres on 10/25/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBCreditsViewController.h"

#import <Extensions/ZBColor.h>
#import <ZBDevice.h>
#import <ZBSettings.h>

@implementation ZBCreditsViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    
    if (self) {
        self.title = @"Credits";
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.credits == NULL) {
        [self fetchCredits];
    }
}

#pragma mark - Table view data source

- (void)fetchCredits {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:@"https://getzbra.com/api/credits.json"]];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data && !error) {
            self.credits = [[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil] objectForKey:@"sections"];
        }
        else {
            NSLog(@"[Zebra] Error while trying to access credits: %@", error);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            self.navigationItem.titleView = NULL;
            self.navigationItem.title = NSLocalizedString(@"Credits", @"");
        });
    }];
    
    [task resume];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.credits.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.credits[section][@"items"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    NSDictionary *item = self.credits[indexPath.section][@"items"][indexPath.row];
    
    if (indexPath.section == 3) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"libraryCreditTableViewCell"];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [cell.textLabel setTextColor:[ZBColor labelColor]];
    }
    else {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"personCreditTableViewCell"];
        if (item[@"link"]) {
            [cell.textLabel setTextColor:[ZBColor accentColor] ?: [UIColor systemBlueColor]];
        }
        else {
            [cell.textLabel setTextColor:[ZBColor labelColor]];
        }
    }
    cell.detailTextLabel.textColor = [ZBColor secondaryLabelColor];
    
    cell.textLabel.text = item[@"name"];
    cell.detailTextLabel.text = item[@"subtitle"];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(self.credits[section][@"title"], @"");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *person = self.credits[indexPath.section][@"items"][indexPath.row];
    NSURL *url = [NSURL URLWithString:person[@"link"]];
    
    if (url) {
        [ZBDevice openURL:url sender:self];
    }
}

#pragma mark - Keyboard Shortcuts

- (NSArray<UIKeyCommand *> *)keyCommands {
    // escape key
    UIKeyCommand *back = [UIKeyCommand keyCommandWithInput:@"\e" modifierFlags:0 action:@selector(back)];
    back.discoverabilityTitle = NSLocalizedString(@"Back", @"");

    return @[back];
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
