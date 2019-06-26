//
//  ZBPackageInfo.m
//  Zebra
//
//  Created by midnightchips on 6/15/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageInfoView.h"
#import <UIColor+GlobalColors.h>
#import <Repos/Helpers/ZBRepo.h>
#import "ZBWebViewController.h"
#import "ZBPackageDepictionViewController.h"
@import SDWebImage;

enum ZBPackageInfoOrder {
    ZBPackageInfoID = 0,
    ZBPackageInfoAuthor,
    ZBPackageInfoVersion,
    ZBPackageInfoSize,
    ZBPackageInfoRepo,
    ZBPackageInfoWishList,
    ZBPackageInfoMoreBy,
    ZBPackageInfoInstalledFiles
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
            @"Author",
            @"Version",
            @"Size",
            @"Repo",
            @"wishList",
            @"moreBy",
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
    [self.packageIcon.layer setCornerRadius:20];
    [self.packageIcon.layer setMasksToBounds:YES];
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
        }
    });
}

- (void)readPackageID:(ZBPackage *)package {
    if (package.identifier) {
        infos[@"packageID"] = package.identifier;
    }
    else {
        [infos removeObjectForKey:@"packageID"];
    }
}

- (void)checkWishList:(ZBPackage *)package {
    NSArray *wishList = [[NSUserDefaults standardUserDefaults] objectForKey:@"wishList"];
    if ([wishList containsObject:package.identifier]) {
        infos[@"wishList"] = @"Remove from Wishlist";
    } else {
        infos[@"wishList"] = @"Add to Wishlist";
    }
}

- (void)setMoreByText:(ZBPackage *)package {
    if (package.author) {
        infos[@"moreBy"] = @"More by this Developer";
    } else {
        [infos removeObjectForKey:@"moreBy"];
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

- (void)readFiles:(ZBPackage *)package {
    if ([package isInstalled:NO]) {
        infos[@"Installed Files"] = @"";
    }
    else {
        [infos removeObjectForKey:@"Installed Files"];
    }
}

- (void)readAuthor:(ZBPackage *)package {
    NSString *authorName = [package author];
    if (authorName) {
        infos[@"Author"] = [self stripEmailFromAuthor];
    } else {
        [infos removeObjectForKey:@"Author"];
    }
}

- (void)setPackage:(ZBPackage *)package {
    self.depictionPackage = package;
    [self readIcon:package];
    [self readAuthor:package];
    [self readVersion:package];
    [self readSize:package];
    [self readRepo:package];
    [self readFiles:package];
    [self readPackageID:package];
    [self checkWishList:package];
    [self setMoreByText:package];
    [self.tableView reloadData];
}

- (NSUInteger)rowCount {
    return infos.count;
}

- (void)generateWishlist {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *wishList = [[defaults objectForKey:@"wishList"] mutableCopy];
    if (!wishList) {
        wishList = [NSMutableArray new];
    }
    if ([wishList containsObject:self.depictionPackage.identifier]) {
        [wishList removeObject:self.depictionPackage.identifier];
        [defaults setObject:wishList forKey:@"wishList"];
        [defaults synchronize];
        [self checkWishList:self.depictionPackage];
        [self.tableView reloadData];
    } else {
        [wishList addObject:self.depictionPackage.identifier];
        [defaults setObject:wishList forKey:@"wishList"];
        [defaults synchronize];
        [self checkWishList:self.depictionPackage];
        [self.tableView reloadData];
    }
}

- (NSString *)stripEmailFromAuthor {
    NSArray *authorName = [self.depictionPackage.author componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSMutableArray *cleanedStrings = [NSMutableArray new];
    for(NSString *cut in authorName) {
        if (![cut hasPrefix:@"<"] && ![cut hasSuffix:@">"]) {
            [cleanedStrings addObject:cut];
        } else {
            NSString *cutCopy = [cut copy];
            cutCopy = [cut substringFromIndex:1];
            cutCopy = [cutCopy substringWithRange:NSMakeRange(0, cutCopy.length - 1)];
            self.authorEmail = cutCopy;
        }
    }

    return [cleanedStrings componentsJoinedByString:@" "];
}

- (void)sendEmailToDeveloper {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        [mail.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
        NSString *subject = [NSString stringWithFormat:@"Zebra %@: %@ Support (%@)", PACKAGE_VERSION, self.depictionPackage.name, self.depictionPackage.version];
        [mail setSubject:subject];
        NSString *body = [NSString stringWithFormat:@"%@: %@\n%@", [ZBDevice deviceModelID], [[UIDevice currentDevice] systemVersion], [ZBDevice UDID]];
        [mail setMessageBody:body isHTML:NO];
        [mail setToRecipients:@[self.authorEmail]];
        
        [self.parentVC presentViewController:mail animated:YES completion:NULL];
    } else {
        NSString *email = [NSString stringWithFormat:@"mailto:%@?subject=%@ Support Zebra %@", self.authorEmail, self.depictionPackage.name, @"Arbitrary Number"];
        NSString *url = [email stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication]  openURL: [NSURL URLWithString: url]];
        }
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    //handle any error
    [controller dismissViewControllerAnimated:YES completion:nil];
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
    
    if (indexPath.row == ZBPackageInfoInstalledFiles) {
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = property;
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
    }
    else if (indexPath.row == ZBPackageInfoMoreBy || indexPath.row == ZBPackageInfoWishList) {
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = value;
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
    }
    else if (indexPath.row == ZBPackageInfoID) {
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        cell.textLabel.text = value;
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    else if (indexPath.row == ZBPackageInfoAuthor) {
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        }
        cell.textLabel.text = value;
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        if (self.authorEmail) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
    }
    else {
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        if (value) {
            cell.textLabel.text = property;
            cell.detailTextLabel.text = value;
            cell.textLabel.textColor = [UIColor cellPrimaryTextColor];
            cell.detailTextLabel.textColor = [UIColor cellSecondaryTextColor];
        }
        else {
            cell.textLabel.text = nil;
            cell.detailTextLabel.text = nil;
        }
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self class] packageInfoOrder].count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == ZBPackageInfoInstalledFiles) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ZBWebViewController *filesController = [storyboard instantiateViewControllerWithIdentifier:@"webController"];
        filesController.navigationDelegate = (ZBPackageDepictionViewController *)self.parentVC;
        filesController.navigationItem.title = @"Installed Files";
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"installed_files" withExtension:@".html"];
        [filesController setValue:url forKey:@"_url"];
        
        [[self.parentVC navigationController] pushViewController:filesController animated:true];
    }
    else if (indexPath.row == ZBPackageInfoWishList) {
        [self generateWishlist];
    } else if (indexPath.row == ZBPackageInfoMoreBy) {
        [self.parentVC performSegueWithIdentifier:@"seguePackageDepictionToMorePackages" sender:[self stripEmailFromAuthor]];
    } else if (indexPath.row == ZBPackageInfoAuthor && self.authorEmail) {
        [self sendEmailToDeveloper];
    }
        
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
