//
//  ZBAccentColorTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/5/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBAccentColorTableViewController.h"
#import "UIImageView+Zebra.h"
#import "UIColor+GlobalColors.h"
#import <ZBThemeManager.h>
#import <ZBSettings.h>

@interface ZBAccentColorTableViewController () {
    NSArray *colors;
    ZBAccentColor selectedColor;
}
@end

@implementation ZBAccentColorTableViewController

- (id)init {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"accentColorPicker"];
    
    if (self) {
        colors = [ZBThemeManager colors];
        selectedColor = [ZBSettings accentColor];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return colors.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"colorCell"];
    
    ZBAccentColor color = (ZBAccentColor)[colors[indexPath.row] integerValue];
    if (color == selectedColor) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    UIColor *leftColor = [ZBThemeManager getAccentColor:color forInterfaceStyle:ZBInterfaceStyleLight];
    UIColor *rightColor = [ZBThemeManager getAccentColor:color forInterfaceStyle:ZBInterfaceStyleDark];
    [[cell imageView] setLeftColor:leftColor rightColor:rightColor];
    [[cell imageView] applyBorder];
    
    cell.textLabel.text = [ZBThemeManager localizedNameForAccentColor:color];
    cell.textLabel.textColor = [UIColor primaryTextColor];
    
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
