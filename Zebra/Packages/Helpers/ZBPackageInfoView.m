//
//  ZBPackageInfo.m
//  Zebra
//
//  Created by midnightchips on 6/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageInfoView.h"
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

+ (NSArray *)packageInfoOrder {
    static NSArray *packageInfoOrder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        packageInfoOrder = @[
            @"Version",
            @"Size"
        ];
    });
    return packageInfoOrder;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    infos = [NSMutableDictionary new];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)setPackage:(ZBPackage *)package {
    self.packageName.text = package.name;
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
    if (![package isInstalled:NO] || [package installedVersion] == nil) {
        infos[@"Version"] = [package version];
    }
    else {
        infos[@"Version"] = [NSString stringWithFormat:@"%@ (Installed: %@)", [package version], [package installedVersion]];
    }
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"PackageInfoTableViewCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:simpleTableIdentifier];
    }
    
    NSString *property = [[self class] packageInfoOrder][indexPath.row];
    
    cell.textLabel.text = property;
    cell.detailTextLabel.text = infos[property];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return infos.count;
}

@end
