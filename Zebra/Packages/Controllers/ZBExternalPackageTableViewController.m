//
//  ZBExternalPackageTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 4/21/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBExternalPackageTableViewController.h"
#import <NSTask.h>
#import <Console/ZBConsoleViewController.h>

@interface ZBExternalPackageTableViewController () {
    NSDictionary *details;
    NSArray *keys;
}
@end

@implementation ZBExternalPackageTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/Applications/Zebra.app/supersling"];
    [task setArguments:@[@"/usr/bin/dpkg-deb", @"-I", [_fileURL path], @"control"]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    [task launch];
    [task waitUntilExit];
    
    NSFileHandle *read = [pipe fileHandleForReading];
    NSData *dataRead = [read readDataToEndOfFile];
    NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *info = [NSMutableDictionary new];
    [stringRead enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        NSArray<NSString *> *pair = [line componentsSeparatedByString:@": "];
        if (pair.count != 2) pair = [line componentsSeparatedByString:@":"];
        if (pair.count != 2) return;
        NSString *key = [pair[0] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        NSString *value = [pair[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        info[key] = value;
    }];
    
    details = (NSDictionary *)info;
    keys = [info allKeys];
}

- (IBAction)install:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    ZBConsoleViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"consoleViewController"];
    vc.externalInstall = true;
    vc.externalFilePath = [_fileURL path];
    
    [[self navigationController] pushViewController:vc animated:true];
}

- (IBAction)goodbye:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : details.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"Package" : @"Information";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"externalPackageCell" forIndexPath:indexPath];
        
        cell.textLabel.text = details[@"Name"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Version %@", details[@"Version"]];
        
        NSString *iconPath = [NSString stringWithFormat:@"/Applications/Cydia.app/Sections/%@.png", details[@"Section"]];
        NSError *error;
        NSData *data = [NSData dataWithContentsOfFile:iconPath options:0 error:&error];
        UIImage *sectionImage = [UIImage imageWithData:data];
        if (sectionImage != NULL) {
            cell.imageView.image = sectionImage;
            
            CGSize itemSize = CGSizeMake(35, 35);
            UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
            [cell.imageView.image drawInRect:imageRect];
            cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        return cell;
    }
    else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"externalPackageDetailCell" forIndexPath:indexPath];
        
        cell.textLabel.text = keys[indexPath.row];
        cell.detailTextLabel.text = details[keys[indexPath.row]];
        
        return cell;
    }
}

@end
