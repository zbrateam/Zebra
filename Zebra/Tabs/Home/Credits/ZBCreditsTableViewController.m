//
//  ZBCreditsTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 10/25/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBCreditsTableViewController.h"
#import <Extensions/UIColor+GlobalColors.h>
#import <ZBDevice.h>
#import <ZBSettings.h>

@interface ZBCreditsTableViewController ()

@end

@implementation ZBCreditsTableViewController

@synthesize credits;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.titleView = spinner;
    [spinner startAnimating];
    
    switch ([ZBSettings interfaceStyle]) {
        case ZBInterfaceStyleLight:
            break;
        case ZBInterfaceStyleDark:
        case ZBInterfaceStylePureBlack:
            spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
            break;
    }
    
    [self.tableView setBackgroundColor:[UIColor groupedTableViewBackgroundColor]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor cellSeparatorColor];
    
    if (credits == NULL) {
        [self fetchCredits];
    }
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

#pragma mark - Table view data source

- (void)fetchCredits {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:@"https://getzbra.com/api/credits.json"]];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data && !error) {
            self->credits = [[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil] objectForKey:@"sections"];
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
    return [credits count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[credits objectAtIndex:section] objectForKey:@"items"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    NSDictionary *item = [[[credits objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];
    
    if (indexPath.section == 3) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"libraryCreditTableViewCell" forIndexPath:indexPath];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [cell.textLabel setTextColor:[UIColor primaryTextColor]];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"personCreditTableViewCell" forIndexPath:indexPath];
        if ([item objectForKey:@"link"] != NULL) {
            [cell.textLabel setTextColor:[UIColor accentColor]];
        }
        else {
            [cell.textLabel setTextColor:[UIColor primaryTextColor]];
        }
    }
    [cell.detailTextLabel setTextColor:[UIColor secondaryTextColor]];
    
    cell.textLabel.text = [item objectForKey:@"name"];
    cell.detailTextLabel.text = [item objectForKey:@"subtitle"];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString([[credits objectAtIndex:section] objectForKey:@"title"], @"");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *person = [[[credits objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];
    NSURL *url = [NSURL URLWithString:[person objectForKey:@"link"]];
    
    if (url) {
        [ZBDevice openURL:url delegate:self];
    }
}

@end
