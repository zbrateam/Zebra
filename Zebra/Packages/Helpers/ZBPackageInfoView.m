//
//  ZBPackageInfo.m
//  Zebra
//
//  Created by midnightchips on 6/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <ZBDarkModeHelper.h>
#import "ZBPackageInfoView.h"
#import <UIColor+GlobalColors.h>
#import <Repos/Helpers/ZBRepo.h>
@import SDWebImage;

enum ZBPackageInfoOrder {
    ZBPackageInfoVersion = 0,
    ZBPackageInfoSize
};

@interface ZBPackageInfoView () {
    NSMutableDictionary *infos;
}
@end

@implementation ZBPackageInfoView

+ (CGFloat)rowHeight {
    return 45;
}

+ (NSArray *)packageInfoOrder {
    static NSArray *packageInfoOrder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        packageInfoOrder = @[
            @"Version",
            @"Size",
            @"Repo"
        ];
    });
    return packageInfoOrder;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    infos = [NSMutableDictionary new];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)readIcon:(ZBPackage *)package {
    self.packageName.text = package.name;
    if ([ZBDarkModeHelper darkModeEnabled]) {
        self.packageName.textColor = [UIColor whiteColor];
    }
    else {
        self.packageName.textColor = [UIColor cellPrimaryTextColor];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *sectionImage = [UIImage imageNamed:package.sectionImageName];
        if (sectionImage == NULL) {
            sectionImage = [UIImage imageNamed:@"Other"];
        }
        
        NSString *iconURL = @"";
        if (package.iconPath) {
            iconURL = [package iconPath];
        }
        else {
            iconURL = [NSString stringWithFormat:@"data:image/png;base64,%@", [UIImagePNGRepresentation(sectionImage) base64EncodedStringWithOptions:0]];
        }
        
        if (iconURL.length) {
            [self.packageIcon sd_setImageWithURL:[NSURL URLWithString:iconURL] placeholderImage:sectionImage];
        }
    });
}

- (void)readVersion:(ZBPackage *)package {
    if (![package isInstalled:NO] || [package installedVersion] == nil) {
        infos[@"Version"] = [package version];
    }
    else {
        infos[@"Version"] = [NSString stringWithFormat:@"%@ (Installed Version: %@)", [package version], [package installedVersion]];
    }
}

- (void)readSize:(ZBPackage *)package {
    NSString *size = [package size];
    NSString *installedSize = [package installedSize];
    if (size && installedSize) {
        infos[@"Size"] = [NSString stringWithFormat:@"%@ (Installed Size: %@)", size, installedSize];
    }
    else if (size) {
        infos[@"Size"] = size;
    }
    else {
        [infos removeObjectForKey:@"Size"];
    }
}

- (void)readRepo:(ZBPackage *)package {
    NSString *repoName = [[package repo] origin];
    if (repoName) {
        infos[@"Repo"] = repoName;
    }
    else {
        [infos removeObjectForKey:@"Repo"];
    }
}

- (void)setPackage:(ZBPackage *)package {
    [self readIcon:package];
    [self readVersion:package];
    [self readSize:package];
    [self readRepo:package];
    [self.tableView reloadData];
}

- (NSUInteger)rowCount {
    return infos.count;
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *property = [[self class] packageInfoOrder][indexPath.row];
    NSString *value = infos[property];
    return value ? [[self class] rowHeight] : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"PackageInfoTableViewCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
    }
    
    NSString *property = [[self class] packageInfoOrder][indexPath.row];
    NSString *value = infos[property];
    
    if (value) {
        cell.textLabel.text = property;
        cell.detailTextLabel.text = infos[property];
        if ([ZBDarkModeHelper darkModeEnabled]) {
            cell.textLabel.textColor = [UIColor whiteColor];//[UIColor cellPrimaryTextColor];
            cell.detailTextLabel.textColor = [UIColor lightGrayColor];//[UIColor cellSecondaryTextColor];
        } else {
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            cell.detailTextLabel.textColor = [UIColor cellSecondaryTextColor];
        }
    }
    else {
        cell.textLabel.text = nil;
        cell.detailTextLabel.text = nil;
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self class] packageInfoOrder].count;
}

@end
