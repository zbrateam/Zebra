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
#import "ZBWebViewController.h"
#import "ZBPackageDepictionViewController.h"
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
            @"packageID",
            @"Version",
            @"Size",
            @"Repo",
            @"Installed Files"
        ];
    });
    return packageInfoOrder;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    infos = [NSMutableDictionary new];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = [UIColor clearColor];
}

- (void)readIcon:(ZBPackage *)package {
    self.packageName.text = package.name;
    self.packageName.textColor = [UIColor cellPrimaryTextColor];
    
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
            [self.packageIcon.layer setCornerRadius:20];
            [self.packageIcon.layer setMasksToBounds:TRUE];
        }
    });
}

- (void)readPackageID:(ZBPackage *)package{
    if(package.identifier) {
        infos[@"packageID"] = package.identifier;
    }else{
        [infos removeObjectForKey:@"packageID"];
    }
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

-(void)readFiles:(ZBPackage *)package{
    if([package isInstalled:NO]){
        infos[@"Installed Files"] = @"TRUE";
    }else{
        [infos removeObjectForKey:@"Installed Files"];
    }
}

- (void)setPackage:(ZBPackage *)package {
    [self readIcon:package];
    [self readVersion:package];
    [self readSize:package];
    [self readRepo:package];
    [self readFiles:package];
    [self readPackageID:package];
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
    
    NSString *property = [[self class] packageInfoOrder][indexPath.row];
    NSString *value = infos[property];
    if([value isEqualToString:@"TRUE"]){
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = property;
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        return cell;
    }else if([property isEqualToString:@"packageID"]){
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        cell.textLabel.text = value;
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return cell;
    }else{
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        
        if (value) {
            cell.textLabel.text = property;
            cell.detailTextLabel.text = infos[property];
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            cell.detailTextLabel.textColor = [UIColor cellSecondaryTextColor];
            
        }
        else {
            cell.textLabel.text = nil;
            cell.detailTextLabel.text = nil;
        }
        
        return cell;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self class] packageInfoOrder].count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath == [self lastObjectInIndexPath]){
        NSLog(@"View is tapped");
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ZBWebViewController *filesController = [storyboard instantiateViewControllerWithIdentifier:@"webController"];
        filesController.navigationDelegate = (ZBPackageDepictionViewController *)self.parentVC;
        filesController.navigationItem.title = @"Installed Files";
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"installed_files" withExtension:@".html"];
        [filesController setValue:url forKey:@"_url"];
        
        [[self.parentVC navigationController] pushViewController:filesController animated:true];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
}

- (NSIndexPath *)lastObjectInIndexPath {
    // First figure out how many sections there are
    NSInteger lastSectionIndex = [self.tableView numberOfSections] - 1;
    
    // Then grab the number of rows in the last section
    NSInteger lastRowIndex = [self.tableView numberOfRowsInSection:lastSectionIndex] - 1;
    
    // Now just construct the index path
    NSIndexPath *pathToLastRow = [NSIndexPath indexPathForRow:lastRowIndex inSection:lastSectionIndex];
    return pathToLastRow;
}

@end
