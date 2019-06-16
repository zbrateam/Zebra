//
//  ZBPackageInfo.m
//  Zebra
//
//  Created by midnightchips on 6/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageInfoView.h"
@import SDWebImage;

@implementation ZBPackageInfoView

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    [self commonInit];
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self commonInit];
    return self;
}

- (void)commonInit {
    if (self) {
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        [self.tableView reloadData];
    }
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
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"PackageInfoTableViewCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = @"HI";
    cell.textLabel.backgroundColor = [UIColor whiteColor];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

@end
