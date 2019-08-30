//
//  ZBAlternateIconController.m
//  Zebra
//
//  Created by midnightchips on 6/1/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
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
    
    if (indexPath.row != 0) {
        cell.imageView.image = [UIImage imageNamed:[icons objectAtIndex:indexPath.row]];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"AppIcon60x60"];
    }
    CGSize itemSize = CGSizeMake(40, 40);
    UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
    [cell.imageView.image drawInRect:imageRect];
    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    cell.imageView.layer.cornerRadius = 10;
    cell.imageView.clipsToBounds = YES;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        [self setIconWithName:nil fromIndex:indexPath];
    } else {
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
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
