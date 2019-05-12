//
//  ZBRepoPurchases.m
//  Zebra
//
//  Created by midnightchips on 5/11/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBRepoPurchases.h"
#import <sys/utsname.h>
#import "MobileGestalt.h"
#import "UIBarButtonItem+blocks.h"
#import "ZBPackageTableViewCell.h"
#import "ZBPackageDepictionViewController.h"

@interface ZBRepoPurchases ()

@end

@implementation ZBRepoPurchases

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.databaseManager = [ZBDatabaseManager sharedInstance];
    _keychain = [UICKeyChainStore keyChainStoreWithService:@"xyz.willy.Zebra" accessGroup:nil];
    self.packages = [NSMutableArray new];
    if (self.repoImage != NULL) {
        UIView *container = [[UIView alloc] initWithFrame:self.navigationItem.titleView.frame];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        imageView.center = self.navigationItem.titleView.center;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.image = self.repoImage;
        imageView.layer.cornerRadius = 5;
        imageView.layer.masksToBounds = YES;
        [container addSubview:imageView];
        
        self.navigationItem.titleView = container;
    }
    self.title = self.repoName;
    self.logOut = [[UIBarButtonItem alloc] initWithTitle:@"Log Out" style:UIBarButtonItemStylePlain actionHandler:^{
        [self logoutRepo];
    }];
    [self.navigationItem setRightBarButtonItem:self.logOut];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBPackageTableViewCell" bundle:nil]
         forCellReuseIdentifier:@"packageTableViewCell"];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:TRUE];
    [self listPurchasedSileoPackages];
}

-(void)listPurchasedSileoPackages{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    
    NSDictionary *test = @{ @"token": _keychain[self.repoEndpoint],
                            @"udid": [self deviceUDID],
                            @"device":[self deviceModelID]};
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:test options:(NSJSONWritingOptions)0 error:nil];
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@user_info", self.repoEndpoint]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        //self.packages = json[@"items"];
        [self.packages removeAllObjects];
        for(NSString *packageID in json[@"items"]){
            @try{
                ZBPackage *package = [self.databaseManager topVersionForPackageID:packageID];
                [self.packages addObject:package];
            }
            @catch (NSException *exception){
                NSLog(@"Package Unavailable %@ %@", exception.reason, packageID);
            }
            
        }
        if(json[@"user"]){
            if([json valueForKeyPath:@"user.name"]){
                self.userName = [json valueForKeyPath:@"user.name"];
            }
            if([json valueForKeyPath:@"user.email"]){
                self.userEmail = [json valueForKeyPath:@"user.email"];
            }
            
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        
    }] resume];
}

-(void)logoutRepo{
    [_keychain removeItemForKey:self.repoEndpoint];
    UINavigationController *navigationController = self.navigationController;
    [navigationController popViewControllerAnimated:YES];
}

-(NSString *)deviceUDID {
    
    NSString *udid = (__bridge NSString*)MGCopyAnswer(CFSTR("UniqueDeviceID"));
    return udid;
    
}

- (NSString *)deviceModelID {
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if(section == 0){
        return 0;
    }else{
        return 30;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0){
        return 2;
    }else{
        return [self.packages count];
    }
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyIdentifier"];//[tableView dequeueReusableCellWithIdentifier:@"basicCell" forIndexPath:indexPath];
    if(indexPath.section == 0){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserInfo"];
        if (cell == nil) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UserInfo"];
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
        }
        if(indexPath.row == 0){
            cell.textLabel.text = self.userName;
        }else{
            cell.textLabel.text = self.userEmail;
        }
        return cell;
    }else{
        /*UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Packages"];
        if (cell == nil) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Packages"];
            
            //cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
        }*/
        //ZBPackage *package = [self.databaseManager topVersionForPackageID:[self.packages objectAtIndex:indexPath.row]];
           //ZBPackage *package = [self.databaseManager topVersionForPackageID:[self.packages objectAtIndex:indexPath.row]];
            //cell.textLabel.text = package.name;
        
        /*ZBPackage *package = [self.packages objectAtIndex:indexPath.row];
        cell.textLabel.text = package.name;
        return cell;*/
        ZBPackageTableViewCell *cell = (ZBPackageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"packageTableViewCell" forIndexPath:indexPath];
        
        ZBPackage *package = (ZBPackage *)[_packages objectAtIndex:indexPath.row];
        
        [cell updateData:package];
        return cell;
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 1){
        [self performSegueWithIdentifier:@"seguePurchasesToPackageDepiction" sender:indexPath];
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


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"seguePurchasesToPackageDepiction"]) {
        ZBPackageDepictionViewController *destination = (ZBPackageDepictionViewController *)[segue destinationViewController];
        NSIndexPath *indexPath = sender;
        
        destination.package = [_packages objectAtIndex:indexPath.row];
        
        [_databaseManager closeDatabase];
    }
}


@end
