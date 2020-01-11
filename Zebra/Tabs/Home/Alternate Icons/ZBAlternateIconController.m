//
//  ZBAlternateIconController.m
//  Zebra
//
//  Created by midnightchips on 6/1/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBAlternateIconController.h"
#import "UIColor+GlobalColors.h"
#import <ZBDevice.h>

@interface ZBAlternateIconController ()

@end

@implementation ZBAlternateIconController{
    NSArray *icons;
    NSArray *betterNames;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    icons = @[@"Default", @"originalBlack", @"lightZebraSkin", @"darkZebraSkin", @"zWhite", @"zBlack"];
    betterNames = @[@"Original", @"Original (Dark)", @"Zebra Pattern (Light)", @"Zebra Pattern (Dark)", @"Embossed Zebra Pattern (Light)", @"Embossed Zebra Pattern (Dark)"];
    self.title = NSLocalizedString(@"Alternate Icons", @"");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return icons.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *altIcon = @"alternateIconCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:altIcon];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:altIcon];
    }
    
    cell.textLabel.text = [betterNames objectAtIndex:indexPath.row];
    cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
    cell.detailTextLabel.textColor = [UIColor cellSecondaryTextColor];
    
    if (indexPath.row != 0) {
        cell.imageView.image = [UIImage imageNamed:[icons objectAtIndex:indexPath.row]];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"AppIcon60x60"];
    }
    CGSize itemSize = CGSizeMake(60, 60);
    UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
    [cell.imageView.image drawInRect:imageRect];
    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    cell.imageView.layer.cornerRadius = 10.5;
    cell.imageView.clipsToBounds = YES;
    
    NSString *iconSelected;
    if (@available(iOS 10.3, *)) {
        iconSelected = [[UIApplication sharedApplication] alternateIconName];
    }
    else {
        iconSelected = @"You shouldn't be here";
    }
    
    NSString *iconName = nil;
    if ([indexPath row] > 0) {
        iconName = [icons objectAtIndex:indexPath.row];
    }
    if ([iconSelected isEqualToString:iconName] || iconSelected == iconName) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    [cell setTintColor: [UIColor tintColor]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [ZBDevice hapticButton];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0) {
        [self setIconWithName:nil fromIndex:indexPath];
    } else {
        [self setIconWithName:[icons objectAtIndex:indexPath.row] fromIndex:indexPath];
    }
}

- (void)setIconWithName:(NSString *)name fromIndex:(NSIndexPath *)indexPath {
    if (@available(iOS 10.3, *)) {
        if ([[UIApplication sharedApplication] supportsAlternateIcons]) {
            [[UIApplication sharedApplication] setAlternateIconName:name completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"[Zebra Icon Error] %@ %@", error.localizedDescription, [self->icons objectAtIndex:indexPath.row]);
                }
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 75.0;
}

@end
