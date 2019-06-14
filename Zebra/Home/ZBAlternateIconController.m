//
//  ZBAlternateIconController.m
//  Zebra
//
//  Created by midnightchips on 6/1/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <ZBDarkModeHelper.h>
#import "ZBAlternateIconController.h"
#import "UIColor+GlobalColors.h"
@interface ZBAlternateIconController ()

@end

@implementation ZBAlternateIconController{
    NSArray *icons;
    NSArray *betterNames;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    icons = @[@"Default", @"lightZebraSkin", @"darkZebraSkin", @"zWhite", @"zBlack"];
    betterNames = @[@"Original", @"Light Zebra Pattern", @"Dark Zebra Pattern", @"Zebra Pattern with Z (Light)", @"Zebra Pattern with Z (Dark)"];
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:TRUE completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [icons count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *altIcon = @"alternateIconCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:altIcon];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:altIcon];
    }
    
    cell.textLabel.text = [betterNames objectAtIndex:indexPath.row];
    
    if ([ZBDarkModeHelper darkModeEnabled]) {
        [cell.textLabel setTextColor:[UIColor whiteColor]];
    } else {
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
    }
    
    if (indexPath.row != 0) {
        cell.imageView.image = [UIImage imageNamed:[icons objectAtIndex:indexPath.row]];
    }
    else {
        cell.imageView.image = [UIImage imageNamed:@"AppIcon60x60"];
    }
    CGSize itemSize = CGSizeMake(40, 40);
    UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
    [cell.imageView.image drawInRect:imageRect];
    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [cell.imageView.layer setCornerRadius:10];
    [cell.imageView setClipsToBounds:TRUE];
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        [self setIconWithName:nil fromIndex:indexPath];
    }
    else {
        [self setIconWithName:[icons objectAtIndex:indexPath.row] fromIndex:indexPath];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)setIconWithName:(NSString *)name fromIndex:(NSIndexPath *)indexPath {
    if (@available(iOS 10.3, *)) {
        if ([[UIApplication sharedApplication] supportsAlternateIcons]) {
            [[UIApplication sharedApplication] alternateIconName];
            [[UIApplication sharedApplication] setAlternateIconName:name completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"[Zebra Icon Error] %@ %@", error.localizedDescription, [self->icons objectAtIndex:indexPath.row]);
                }
                [self dismissViewControllerAnimated:TRUE completion:nil];
            }];
        }
    } else {
        [self dismissViewControllerAnimated:TRUE completion:nil];
    }
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
