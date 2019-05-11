//
//  ZBRepoSectionsListTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBRepoSectionsListTableViewController.h"
#import <Database/ZBDatabaseManager.h>
#import <Repos/Helpers/ZBRepo.h>
#import <Packages/Controllers/ZBPackageListTableViewController.h>
#import <Repos/Helpers/ZBRepoManager.h>
#import <sys/utsname.h>
#import "MobileGestalt.h"
#import "UIBarButtonItem+blocks.h"


@interface ZBRepoSectionsListTableViewController ()

@end

@implementation ZBRepoSectionsListTableViewController

@synthesize repo;
@synthesize sectionReadout;
@synthesize sectionNames;
@synthesize databaseManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    _keychain = [UICKeyChainStore keyChainStoreWithService:@"xyz.willy.zebra"];
    
    databaseManager = [ZBDatabaseManager sharedInstance];
    sectionReadout = [databaseManager sectionReadoutForRepo:repo];
    sectionNames = [[sectionReadout allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    // Purchased Buttons
    self.login = [[UIBarButtonItem alloc] initWithTitle:@"Login" style:UIBarButtonItemStylePlain actionHandler:^{
        [self setupRepoLogin];
    }];
    
    self.purchased = [[UIBarButtonItem alloc] initWithTitle:@"Purchased" style:UIBarButtonItemStylePlain actionHandler:^{
        
    }];
    
    
    UIImage *image = [databaseManager iconForRepo:repo];
    if (image != NULL) {
        UIView *container = [[UIView alloc] initWithFrame:self.navigationItem.titleView.frame];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        imageView.center = self.navigationItem.titleView.center;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.image = image;
        imageView.layer.cornerRadius = 5;
        imageView.layer.masksToBounds = YES;
        [container addSubview:imageView];
        
        self.navigationItem.titleView = container;
    }
    self.title = [repo origin];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    if(!self.repoEndpoint){
        if(repo.isSecure){
            NSString *requestURL;
            if([repo.baseURL hasSuffix:@"/"]){
                requestURL = [NSString stringWithFormat:@"https://%@payment_endpoint",repo.baseURL];
            }else{
                requestURL = [NSString stringWithFormat:@"https://%@/payment_endpoint",repo.baseURL];
            }
            NSURL *url = [NSURL URLWithString:requestURL];
            NSError *error = nil;
            NSString *endpoint = [[NSString alloc] initWithContentsOfURL: url
                                                                encoding: NSUTF8StringEncoding
                                                                   error: &error];
            NSLog(@"Endpoint %@", endpoint);
            if([endpoint length] != 0){
               //[_keychain removeItemForKey:endpoint];
                self.repoEndpoint = endpoint;
                if(![self checkAuthenticated]){
                    [self.navigationItem setRightBarButtonItem:self.login];
                }else{
                    [self.navigationItem setRightBarButtonItem:self.purchased];
                }
            }
        }
    }
}
-(void)setupRepoLogin{
    if(self.repoEndpoint){
        NSURL *destinationUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@authenticate?udid=%@&model=%@",self.repoEndpoint,[self deviceUDID], [self deviceModelID]]];
        self.session = [[SFAuthenticationSession alloc]
                        initWithURL:destinationUrl
                        callbackURLScheme:@"sileo"
                        completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
                            // TODO: Nothing to do here?
                            if(callbackURL){
                                NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:callbackURL resolvingAgainstBaseURL:NO];
                                NSArray *queryItems = urlComponents.queryItems;
                                NSMutableDictionary *queryByKeys = [NSMutableDictionary new];
                                for (NSURLQueryItem *q in queryItems) {
                                    [queryByKeys setValue:[q value] forKey:[q name]];
                                }
                                NSString *token = queryByKeys[@"token"];
                                NSString *payment = queryByKeys[@"payment_secret"];
                                NSLog(@"TOKEN %@", token);
                                NSLog(@"PAYMENT %@", payment);
                                self->_keychain[self.repoEndpoint] = token;
                                self->_keychain[[self.repoEndpoint stringByAppendingString:@"payment"]] = payment;
                                [self.navigationItem setRightBarButtonItem:self.purchased];
                            }else{
                                return;
                            }
                                
                                
                        }];
        [self.session start];
    }
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

-(BOOL)checkAuthenticated{
    if([_keychain stringForKey:self.repoEndpoint]){
        return TRUE;
    }else{
        return FALSE;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [sectionNames count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"repoSectionCell" forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"All Packages";
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc]init];
        numberFormatter.locale = [NSLocale currentLocale];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        numberFormatter.usesGroupingSeparator = YES;
        
        cell.detailTextLabel.text = [numberFormatter stringFromNumber:[NSNumber numberWithInt:[databaseManager numberOfPackagesInRepo:repo]]];
    }
    else {
        NSString *section = [sectionNames objectAtIndex:indexPath.row - 1];
        cell.textLabel.text = [section stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc]init];
        numberFormatter.locale = [NSLocale currentLocale];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        numberFormatter.usesGroupingSeparator = YES;
        
        cell.detailTextLabel.text = [numberFormatter stringFromNumber:(NSNumber *)[sectionReadout objectForKey:section]];
    }
    
    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ZBPackageListTableViewController *destination = [segue destinationViewController];
    UITableViewCell *cell = (UITableViewCell *)sender;
    destination.repo = repo;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    if (indexPath.row != 0) {
        NSString *section = [sectionNames objectAtIndex:indexPath.row - 1];
        destination.section = section;
        destination.title = section;
    }
    else {
        destination.title = @"All Packages";
    }
}

//3D Touch Actions

- (NSArray *)previewActionItems {
    UIPreviewAction *refresh = [UIPreviewAction actionWithTitle:@"Refresh" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
//        ZBDatabaseManager *databaseManager = [[ZBDatabaseManager alloc] init];
//        [databaseManager updateDatabaseUsingCaching:true singleRepo:self->repo completion:^(BOOL success, NSError * _Nonnull error) {
//            NSLog(@"Updated repo %@", self->repo);
//        }];
    }];
    
    if (![[repo origin] isEqualToString:@"xTM3x Repo"]) {
        UIPreviewAction *delete = [UIPreviewAction actionWithTitle:@"Delete" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteRepoTouchAction" object:self userInfo:@{@"repo": self->repo}];
        }];
        
        return @[refresh, delete];
    }
    
    return @[refresh];
}

@end
