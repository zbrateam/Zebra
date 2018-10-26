//
//  AUPMQueueViewController.m
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "AUPMQueueViewController.h"
#import "AUPMQueue.h"
#import "AUPMTabBarController.h"
#import "AUPMPackage.h"
#import "AUPMConsoleViewController.h"
#import "AUPMAppDelegate.h"

@interface AUPMQueueViewController () {
    AUPMQueue *_queue;
}

@end

@implementation AUPMQueueViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _queue = [AUPMQueue sharedInstance];
    
    UIBarButtonItem *confirmButton = [[UIBarButtonItem alloc] initWithTitle:@"Confirm" style:UIBarButtonItemStyleDone target:self action:@selector(confirm)];
    self.navigationItem.rightBarButtonItem = confirmButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.title = @"Queue";
    
}

- (void)confirm {
    AUPMConsoleViewController *console = [[AUPMConsoleViewController alloc] init];
    [[self navigationController] pushViewController:console animated:true];
}

- (void)cancel {
    AUPMTabBarController *tabController = (AUPMTabBarController *)((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController;
    [tabController updatePackageTableView];
    
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[_queue actionsToPerform] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *action = [[_queue actionsToPerform] objectAtIndex:section];
    return [_queue numberOfPackagesForQueue:action];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[_queue actionsToPerform] objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"QueuePackageTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    NSString *action = [[_queue actionsToPerform] objectAtIndex:indexPath.section];
    AUPMPackage *package;
    
    if ([action isEqual:@"Install"]) {
        package = [_queue packageInQueueForAction:AUPMQueueActionInstall atIndex:(int)indexPath.row];
    }
    else if ([action isEqual:@"Remove"]) {
        package = [_queue packageInQueueForAction:AUPMQueueActionRemove atIndex:(int)indexPath.row];
    }
    else if ([action isEqual:@"Reinstall"]) {
        package = [_queue packageInQueueForAction:AUPMQueueActionReinstall atIndex:(int)indexPath.row];
    }
    else if ([action isEqual:@"Upgrade"]) {
        package = [_queue packageInQueueForAction:AUPMQueueActionUpgrade atIndex:(int)indexPath.row];
    }
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    NSString *section = [[package section] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    if ([section characterAtIndex:[section length] - 1] == ')') {
        NSArray *items = [section componentsSeparatedByString:@"("]; //Remove () from section
        section = [items[0] substringToIndex:[items[0] length] - 1];
    }
    NSString *iconPath = [NSString stringWithFormat:@"/Applications/Cydia.app/Sections/%@.png", section];
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:iconPath options:0 error:&error];
    UIImage *sectionImage = [UIImage imageWithData:data];
    if (sectionImage != NULL) {
        cell.imageView.image = sectionImage;
    }
    
    if (error != nil) {
        NSLog(@"[AUPM] %@", error);
    }
    
    cell.textLabel.text = [package packageName];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", [package packageIdentifier], [package version]];
    
    CGSize itemSize = CGSizeMake(35, 35);
    UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
    [cell.imageView.image drawInRect:imageRect];
    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return cell;
}

#pragma mark - Table View Delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *action = [[_queue actionsToPerform] objectAtIndex:indexPath.section];
        
        if ([action isEqual:@"Install"]) {
            AUPMPackage *package = [_queue packageInQueueForAction:AUPMQueueActionInstall atIndex:(int)indexPath.row];
            [_queue removePackage:package fromQueueWithAction:AUPMQueueActionInstall];
        }
        else if ([action isEqual:@"Remove"]) {
            AUPMPackage *package = [_queue packageInQueueForAction:AUPMQueueActionRemove atIndex:(int)indexPath.row];
            [_queue removePackage:package fromQueueWithAction:AUPMQueueActionRemove];
        }
        else if ([action isEqual:@"Reinstall"]) {
            AUPMPackage *package = [_queue packageInQueueForAction:AUPMQueueActionReinstall atIndex:(int)indexPath.row];
            [_queue removePackage:package fromQueueWithAction:AUPMQueueActionReinstall];
        }
        else if ([action isEqual:@"Upgrade"]) {
            AUPMPackage *package = [_queue packageInQueueForAction:AUPMQueueActionUpgrade atIndex:(int)indexPath.row];
            [_queue removePackage:package fromQueueWithAction:AUPMQueueActionUpgrade];
        }
        else {
            NSLog(@"[AUPM] MY TIME HAS COME TO BURN");
        }
        
        //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadData];
        
    }
}

@end
