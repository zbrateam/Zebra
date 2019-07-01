//
//  ZBCommunityReposTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBCommunityReposTableViewController.h"

@interface ZBCommunityReposTableViewController ()

@end

@implementation ZBCommunityReposTableViewController
@synthesize communityRepos;
@synthesize jailbreakRepo;
@synthesize availableManagers;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"Community Repos"];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    availableManagers = [NSMutableArray new];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchRepoJSON];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchRepoJSON {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:@"https://getzbra.com/api/communityrepos.json"]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          if (data && !error) {
              NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
              if ([json objectForKey:@"repos"]) {
                  self->communityRepos = json[@"repos"];
              }
              //self->changeLogArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
              dispatch_async(dispatch_get_main_queue(), ^{
                  [self.tableView reloadData];
              });
          }
          if (error){
              NSLog(@"[Zebra] Github error %@", error);
          }
      }] resume];
    
}

- (NSString *)determineJailreakRepo {
    if ([ZBDevice isChimera]) {
        return @"deb https://repo.chimera.sh ./\n";
    }
    else if ([ZBDevice isUncover]) { //uncover
        return @"deb http://apt.bingner.com/ ios/%.2f main\n";
    }
    else if ([ZBDevice isElectra]) { //electra
        return @"deb https://electrarepo64.coolstar.org/ ./\n";
    }
    else { //cydia
        return [NSString stringWithFormat:@"deb http://apt.saurik.com/ ios/%.2f main\n", kCFCoreFoundationVersionNumber];
    }
}

- (NSInteger)numberOfRowsInTransfer {
    [availableManagers removeAllObjects];
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Sileo.app"]) {
        [availableManagers addObject:@"Sileo"];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"]) {
        [availableManagers addObject:@"Cydia"];
    }
    return [availableManagers count];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [self numberOfRowsInTransfer];
    }
    else if (section == 1) {
        return 1;
    }
    return [communityRepos count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *cellIdentifier = @"transferCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        NSString *titleString = [NSString stringWithFormat:@"Transfer Sources from %@", [availableManagers objectAtIndex:indexPath.row]];
        [cell.textLabel setText:titleString];
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        return cell;
    }else if (indexPath.section == 1) {
        static NSString *cellIdentifier = @"jailbreakCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        NSString *cellText;
        NSURL *iconURL;
        if ([ZBDevice isChimera]) {
            cellText = @"Chimera";
            iconURL = [NSURL URLWithString:@"https://repo.chimera.sh/CydiaIcon.png"];
        }
        else if ([ZBDevice isUncover]) { //uncover
            cellText = @"Bingner/Elucubratus";
            iconURL = [NSURL URLWithString:@"https://apt.bingner.com/CydiaIcon.png"];
        }
        else if ([ZBDevice isElectra]) { //electra
            cellText = @"Electra's iOS Utilities";
            iconURL = [NSURL URLWithString:@"https://github.com/coolstar/electra/raw/master/electra/Resources/AppIcon60x60%402x.png"];
        }
        else { //cydia
            cellText = @"Cydia/Telesphoreo";
            iconURL = [NSURL URLWithString:@"http://apt.saurik.com/dists/ios/CydiaIcon.png"];
        }
        [cell.textLabel setText:cellText];
        [cell.imageView sd_setImageWithURL:iconURL placeholderImage:[UIImage imageNamed:@"Unknown"]];
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        
        CGSize itemSize = CGSizeMake(40, 40);
        UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
        CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
        [cell.imageView.image drawInRect:imageRect];
        cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell.imageView.layer setCornerRadius:10];
        [cell.imageView setClipsToBounds:YES];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        return cell;
        
    } else {
        static NSString *cellIdentifier = @"repoCell";
        NSDictionary *dataDict = [communityRepos objectAtIndex:indexPath.row];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        if ([dataDict objectForKey:@"name"]) {
            [cell.textLabel setText:dataDict[@"name"]];
        }
        if ([dataDict objectForKey:@"url"]) {
            [cell.detailTextLabel setText:dataDict[@"url"]];
        }
        if ([dataDict objectForKey:@"icon"]) {
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:dataDict[@"icon"]] placeholderImage:[UIImage imageNamed:@"Unknown"]];
        } else {
            [cell.imageView setImage:[UIImage imageNamed:@"Unknown"]];
        }
        [cell.textLabel setTextColor:[UIColor cellPrimaryTextColor]];
        [cell.detailTextLabel setTextColor:[UIColor cellSecondaryTextColor]];
        
        CGSize itemSize = CGSizeMake(40, 40);
        UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
        CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
        [cell.imageView.image drawInRect:imageRect];
        cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell.imageView.layer setCornerRadius:10];
        [cell.imageView setClipsToBounds:YES];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        return cell;
        
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, tableView.frame.size.width - 10, 18)];
    [view setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [label setFont:[UIFont boldSystemFontOfSize:15]];
    [label setText:[self headerTextForSection:section]];
    [label setTextColor:[UIColor cellPrimaryTextColor]];
    [view addSubview:label];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[label]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label]-5-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
    return view;
}


- (NSString *)headerTextForSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Transfer Sources";
            break;
        case 1:
            return @"Utilities";
        case 2:
            return @"Community Repositories";
        default:
            return nil;
            break;
    }
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
