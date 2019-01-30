//
//  ZBQueueViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBQueueViewController.h"
#import "ZBQueue.h"

@interface ZBQueueViewController () {
    ZBQueue *_queue;
}

@end

@implementation ZBQueueViewController

- (void)loadView {
    [super loadView];
    
    _queue = [ZBQueue sharedInstance];
    
    UIBarButtonItem *confirmButton = [[UIBarButtonItem alloc] initWithTitle:@"Confirm" style:UIBarButtonItemStyleDone target:self action:@selector(confirm)];
    self.navigationItem.rightBarButtonItem = confirmButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.title = @"Queue";
}

- (void)confirm {
//    AUPMConsoleViewController *console = [[AUPMConsoleViewController alloc] init];
//    [[self navigationController] pushViewController:console animated:true];
}

- (void)cancel {
//    AUPMTabBarController *tabController = (AUPMTabBarController *)((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController;
//    [tabController updatePackageTableView];
//
//    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - Table view data source

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
    NSDictionary *package;
    
    if ([action isEqual:@"Install"]) {
        package = [_queue packageInQueue:ZBQueueTypeInstall atIndex:indexPath.row];
    }
    else if ([action isEqual:@"Remove"]) {
        package = [_queue packageInQueue:ZBQueueTypeRemove atIndex:indexPath.row];
    }
    else if ([action isEqual:@"Reinstall"]) {
        package = [_queue packageInQueue:ZBQueueTypeReinstall atIndex:indexPath.row];
    }
    else if ([action isEqual:@"Upgrade"]) {
        package = [_queue packageInQueue:ZBQueueTypeUpgrade atIndex:indexPath.row];
    }
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    NSString *section = [[package objectForKey:@"section"] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
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
        NSLog(@"[Zebra] %@", error);
    }
    
    cell.textLabel.text = [package objectForKey:@"name"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", [package objectForKey:@"id"], [package objectForKey:@"version"]];
    
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
            NSDictionary *package = [_queue packageInQueue:ZBQueueTypeInstall atIndex:indexPath.row];
            [_queue removePackage:package fromQueue:ZBQueueTypeInstall];
        }
        else if ([action isEqual:@"Remove"]) {
            NSDictionary *package = [_queue packageInQueue:ZBQueueTypeRemove atIndex:indexPath.row];
            [_queue removePackage:package fromQueue:ZBQueueTypeRemove];
        }
        else if ([action isEqual:@"Reinstall"]) {
            NSDictionary *package = [_queue packageInQueue:ZBQueueTypeReinstall atIndex:indexPath.row];
            [_queue removePackage:package fromQueue:ZBQueueTypeReinstall];
        }
        else if ([action isEqual:@"Upgrade"]) {
            NSDictionary *package = [_queue packageInQueue:ZBQueueTypeUpgrade atIndex:indexPath.row];
            [_queue removePackage:package fromQueue:ZBQueueTypeUpgrade];
        }
        else {
            NSLog(@"[Zebra] MY TIME HAS COME TO BURN");
        }
        
        [tableView reloadData];
        
    }
}

@end
