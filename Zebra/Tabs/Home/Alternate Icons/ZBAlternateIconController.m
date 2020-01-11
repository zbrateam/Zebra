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
#import "UIImageView+Zebra.h"

@interface ZBAlternateIconController ()

@end

@implementation ZBAlternateIconController

+ (NSArray <NSDictionary *> *)icons {
    return @[
        @{
            @"iconName": @"AppIcon60x60",
            @"readableName": @"White with Black Stripes",
            @"shortName": @"Black Stripes",
            @"border": @YES
        },
        @{
            @"iconName": @"originalBlack",
            @"author": @"Carson Katri",
            @"readableName": @"Black with White Stripes",
            @"shortName": @"White Stripes",
            @"border": @NO
        },
        @{
            @"iconName": @"lightZebraSkin",
            @"author": @"xerus",
            @"readableName": @"Zebra Pattern (Light)",
            @"shortName": @"Pattern (Light)",
            @"border": @NO
        },
        @{
            @"iconName": @"darkZebraSkin",
            @"author": @"xerus",
            @"readableName": @"Zebra Pattern (Dark)",
            @"shortName": @"Pattern (Dark)",
            @"border": @NO
        },
        @{
            @"iconName": @"zWhite",
            @"author": @"xerus",
            @"readableName": @"Embossed Zebra Pattern (Light)",
            @"shortName": @"Embossed (Light)",
            @"border": @NO
        },
        @{
            @"iconName": @"zBlack",
            @"author": @"xerus",
            @"readableName": @"Embossed Zebra Pattern (Dark)",
            @"shortName": @"Embossed (Dark)",
            @"border": @NO
        },
        @{
            @"iconName": @"AUPM",
            @"readableName": @"AUPM",
            @"shortName": @"AUPM",
            @"border": @YES
        }
    ];
}

+ (NSDictionary *)iconForName:(NSString *)name {
    if (!name) return [self icons][0];
    
    for (NSDictionary *icon in [self icons]) {
        if ([[icon objectForKey:@"iconName"] isEqualToString:name]) {
            return icon;
        }
    }
    
    return NULL;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    return [[ZBAlternateIconController icons] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *icon = [[ZBAlternateIconController icons] objectAtIndex:indexPath.row];
    
    BOOL border = [[icon objectForKey:@"border"] boolValue];
    BOOL author = [icon objectForKey:@"author"] != NULL;
    NSString *cellIdentifier = author ? @"alternateIconCellSubtitle" : @"alternateIconCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = [icon objectForKey:@"readableName"];
    cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
    
    if (author) {
        cell.detailTextLabel.text = [icon objectForKey:@"author"];
        cell.detailTextLabel.textColor = [UIColor cellSecondaryTextColor];
    }
    
    cell.imageView.image = [UIImage imageNamed:[icon objectForKey:@"iconName"]];
    [cell.imageView resize:CGSizeMake(60.0, 60.0) applyRadius:true];
    if (border) [cell.imageView applyBorder];

    NSString *iconSelected;
    if (@available(iOS 10.3, *)) {
        iconSelected = [[UIApplication sharedApplication] alternateIconName];
    }
    else {
        iconSelected = @"You shouldn't be here";
    }
    
    NSString *iconName = nil;
    if ([indexPath row] > 0) {
        iconName = [icon objectForKey:@"iconName"];
    }
    
    if ([iconSelected isEqualToString:iconName] || iconSelected == iconName) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    [cell setTintColor:[UIColor tintColor]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [ZBDevice hapticButton];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *iconName = [[[ZBAlternateIconController icons] objectAtIndex:indexPath.row] objectForKey:@"iconName"];
    [self setIconWithName:iconName fromIndex:indexPath];
}

- (void)setIconWithName:(NSString *)name fromIndex:(NSIndexPath *)indexPath {
    if (@available(iOS 10.3, *)) {
        if ([[UIApplication sharedApplication] supportsAlternateIcons]) {
            if ([name isEqualToString:@"AppIcon60x60"]) name = nil;
            
            [[UIApplication sharedApplication] setAlternateIconName:name completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"[Zebra Icon Error] %@ %@", error.localizedDescription, name);
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
