//
//  ZBRepoListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 12/3/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import "ZBRepoListTableViewController.h"
#import <Packages/Controllers/ZBPackageListTableViewController.h>
#import <Database/ZBDatabaseManager.h>
#import <Repos/Helpers/ZBRepoManager.h>

@interface ZBRepoListTableViewController () {
    NSArray *sources;
}

@end

@implementation ZBRepoListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
    sources = [databaseManager sources];
}

- (IBAction)refreshSources:(id)sender {
    NSLog(@"Refreshing sources");
}

- (IBAction)addSource:(id)sender {
    [self showAddRepoAlert:NULL];
}

- (void)showAddRepoAlert:(NSURL *)url {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter URL" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:true completion:nil];
        
        ZBRepoManager *repoManager = [[ZBRepoManager alloc] init];
        NSString *sourceURL = alertController.textFields[0].text;
        
        UIAlertController *wait = [UIAlertController alertControllerWithTitle:@"Please Wait..." message:@"Verifying Source" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:wait animated:true completion:nil];
        
//        [repoManager addSourceWithURL:sourceURL response:^(BOOL success, NSString *error, NSURL *url) {
//            if (!success) {
//                NSLog(@"[Zebra] Could not add source %@ due to error %@", url.absoluteString, error);
//                
//                [wait dismissViewControllerAnimated:true completion:^{
//                    [self presentVerificationFailedAlert:error url:url];
//                }];
//            }
//            else {
//                [wait dismissViewControllerAnimated:true completion:^{
//                    NSLog(@"[Zebra] Added source.");
////                    AUPMRefreshViewController *refreshViewController = [[AUPMRefreshViewController alloc] initWithAction:1];
////                    [self presentViewController:refreshViewController animated:true completion:nil];
//                }];
//            }
//        }];
    }]];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        if (url != NULL) {
            textField.text = [url absoluteString];
        }
        else {
            textField.text = @"http://";
        }
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.keyboardType = UIKeyboardTypeURL;
        textField.returnKeyType = UIReturnKeyNext;
    }];
    
    [self presentViewController:alertController animated:true completion:nil];
}

- (void)presentVerificationFailedAlert:(NSString *)message url:(NSURL *)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Unable to verify Repo" message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alertController dismissViewControllerAnimated:true completion:nil];
            [self showAddRepoAlert:url];
        }];
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:true completion:nil];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return sources.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
    
    NSDictionary *source = [sources objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [source objectForKey:@"origin"];
    if ([[source objectForKey:@"secure"] boolValue]) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"https://%@/", [source objectForKey:@"baseURL"]];
    }
    else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"http://%@/", [source objectForKey:@"baseURL"]];
    }
    
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[source objectForKey:@"iconURL"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            UIImage *image = [UIImage imageWithData:data];
            if (image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UITableViewCell *updateCell = [tableView cellForRowAtIndexPath:indexPath];
                    if (updateCell) {
                        updateCell.imageView.image = image;
                        CGSize itemSize = CGSizeMake(35, 35);
                        UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
                        CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                        [cell.imageView.image drawInRect:imageRect];
                        cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
                        UIGraphicsEndImageContext();
                        [updateCell setNeedsDisplay];
                        [updateCell setNeedsLayout];
                    }
                });
            }
        }
        if (error) {
            NSLog(@"ERRPR: %@", error);
        }
    }];
    [task resume];
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ZBPackageListTableViewController *destination = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSDictionary *source = [sources objectAtIndex:indexPath.row];
    destination.repoID = [source[@"repoID"] intValue];
}

@end
