//
//  ZBQueueViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBQueue.h"
#import <Packages/Helpers/ZBPackage.h>
#import <Console/ZBConsoleViewController.h>
#import <UIColor+GlobalColors.h>

@interface ZBQueueViewController () {
    ZBQueue *_queue;
}

@end

@implementation ZBQueueViewController

- (void)loadView {
    [super loadView];
    
    _queue = [ZBQueue sharedInstance];
    
    self.navigationController.navigationBar.tintColor = [UIColor tintColor];
    
    if ([[_queue failedDepQueue] count] > 0 || [[_queue failedConQueue] count] > 0) {
        self.navigationItem.rightBarButtonItem.enabled = false;
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = true;
    }
    
    self.title = @"Queue";
}

- (IBAction)confirm:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    ZBConsoleViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"consoleViewController"];
    [[self navigationController] pushViewController:vc animated:true];
}

- (IBAction)cancel:(id)sender {
    if (!self.navigationItem.rightBarButtonItem.enabled) {
        [_queue clearQueue];
    }
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)refreshTable {
    if ([[_queue failedDepQueue] count] > 0 || [[_queue failedConQueue] count] > 0) {
        self.navigationItem.rightBarButtonItem.enabled = false;
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = true;
    }
    
    [self.tableView reloadData];
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
    ZBPackage *package;
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    cell.backgroundColor = [UIColor whiteColor];
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
    else if ([action isEqual:@"Unresolved Dependencies"]) {
        cell.backgroundColor = [UIColor colorWithRed:0.98 green:0.40 blue:0.51 alpha:1.0];
        
        NSArray *failedQ = [_queue failedDepQueue];
        cell.textLabel.text = failedQ[indexPath.row][0];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Could not resolve dependency for %@", [(ZBPackage *)failedQ[indexPath.row][1] name]];
        
        return cell;
    }
    else if ([action isEqual:@"Conflictions"]) {
        cell.backgroundColor = [UIColor colorWithRed:0.98 green:0.40 blue:0.51 alpha:1.0];
        
        NSArray *failedQ = [_queue failedConQueue];
        
        int type = [failedQ[indexPath.row][0] intValue];
        ZBPackage *confliction = (ZBPackage *)failedQ[indexPath.row][1];
        ZBPackage *package = (ZBPackage *)failedQ[indexPath.row][2];
        
        cell.textLabel.text = [confliction name];
        switch (type) {
            case 0:
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ conflicts with %@", [package name], [confliction name]];
                break;
            case 1:
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ conflicts with %@", [confliction name], [package name]];
                break;
            case 2:
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ depends on %@", [confliction name], [package name]];
                break;
            default:
                cell.detailTextLabel.text = @"Are you proud of yourself?";
                break;
        }
        
        return cell;
    }
    
    NSString *section = [package sectionImageName];
    
    UIImage *sectionImage = [UIImage imageNamed:section];
    if (sectionImage != NULL) {
        cell.imageView.image = sectionImage;
    }

    cell.textLabel.text = package.name;
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", package.identifier, package.version];
    
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
    if ([[_queue failedDepQueue] count] > 0 || [[_queue failedConQueue] count] > 0) {
        return NO;
    }
    else {
        return YES;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *action = [[_queue actionsToPerform] objectAtIndex:indexPath.section];
        
        if ([action isEqual:@"Install"]) {
            ZBPackage *package = [_queue packageInQueue:ZBQueueTypeInstall atIndex:indexPath.row];
            [_queue removePackage:package fromQueue:ZBQueueTypeInstall];
        }
        else if ([action isEqual:@"Remove"]) {
            ZBPackage *package = [_queue packageInQueue:ZBQueueTypeRemove atIndex:indexPath.row];
            [_queue removePackage:package fromQueue:ZBQueueTypeRemove];
        }
        else if ([action isEqual:@"Reinstall"]) {
            ZBPackage *package = [_queue packageInQueue:ZBQueueTypeReinstall atIndex:indexPath.row];
            [_queue removePackage:package fromQueue:ZBQueueTypeReinstall];
        }
        else if ([action isEqual:@"Upgrade"]) {
            ZBPackage *package = [_queue packageInQueue:ZBQueueTypeUpgrade atIndex:indexPath.row];
            [_queue removePackage:package fromQueue:ZBQueueTypeUpgrade];
        }
        else if ([action isEqual:@"Unresolved Dependencies"]) {
            for (NSArray *array in [_queue failedDepQueue]) {
                ZBPackage *package = array[1];
                [_queue removePackage:package fromQueue:ZBQueueTypeInstall];
            }
            [_queue.failedDepQueue removeAllObjects];
        }
//        else if ([action isEqual:@"Unresolved Dependencies"]) {
//            for (NSArray *array in [_queue failedQueue]) {
//                ZBPackage *package = array[1];
//                [_queue removePackage:package fromQueue:ZBQueueTypeInstall];
//            }
//            [_queue.failedDepQueue removeAllObjects];
//        }
        else {
            NSLog(@"[Zebra] MY TIME HAS COME TO BURN");
        }
        
        [self refreshTable];
        
    }
}

@end
