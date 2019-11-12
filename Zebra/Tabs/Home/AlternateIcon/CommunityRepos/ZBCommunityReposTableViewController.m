//
//  ZBCommunityReposTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBCommunityReposTableViewController.h"
#import <Database/ZBRefreshViewController.h>
#import <Sources/Cells/ZBSourceTableViewCell.h>

enum ZBSourcesOrder {
    ZBTransfer,
    ZBJailbreakRepo,
    ZBCommunity
};

@interface ZBCommunityReposTableViewController ()
@end

@implementation ZBCommunityReposTableViewController
@synthesize communityRepos;
@synthesize jailbreakRepo;
@synthesize availableManagers;

- (void)viewDidLoad {
    [super viewDidLoad];
    // self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    [self.navigationItem setTitle:NSLocalizedString(@"Community Repos", @"")];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRepoTableViewCell" bundle:nil] forCellReuseIdentifier:@"repoTableViewCell"];
    availableManagers = [NSMutableArray new];
    self.repoManager = [ZBSourceManager sharedInstance];

    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = FALSE;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchRepoJSON];
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
              // self->changeLogArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
              dispatch_async(dispatch_get_main_queue(), ^{
                  [self.tableView reloadData];
              });
          }
          if (error){
              NSLog(@"[Zebra] Github error %@", error);
          }
      }] resume];

}

- (NSArray *)determineJailbreakRepo {
    if ([ZBDevice isCheckrain]) {
        return @[@"https://checkra.in/assets/mobilesubstrate/", @"https://apt.bingner.com/"];
    }
    else if ([ZBDevice isChimera]) {
        return @[@"https://repo.chimera.sh/"];
    } else if ([ZBDevice isUncover]) { // uncover
        return @[@"http://apt.bingner.com/"];
    } else if ([ZBDevice isElectra]) { // electra
        return @[@"https://electrarepo64.coolstar.org/"];
    } else { // cydia
        return @[@"http://apt.saurik.com/"];
    }
}

- (NSInteger)numberOfRowsInTransfer {
    [availableManagers removeAllObjects];
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Sileo.app"]) {
        [availableManagers addObject:@"Sileo"];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"]) {
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
    } else if (section == 1) {
        if ([ZBDevice isCheckrain]) {
            return 2;
        }
        return 1;
    }
    return [communityRepos count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBSourceTableViewCell *cell = (ZBSourceTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
    NSString *cellText = nil;
    NSURL *iconURL = nil;
    NSURL *repoURL = nil;
    NSString *subText = nil;
    if (indexPath.section == 0) {
        if ([[availableManagers objectAtIndex:indexPath.row] isEqualToString:@"Cydia"]) {
            iconURL = [NSURL URLWithString:@"http://apt.saurik.com/dists/ios/CydiaIcon.png"];
        } else {
            iconURL = [NSURL URLWithString:@"https://xtm3x.github.io/repo/depictions/icons/sileo@3x.png"];
        }
        cellText = [NSString stringWithFormat:NSLocalizedString(@"Transfer Sources from %@", @""), [availableManagers objectAtIndex:indexPath.row]];
        subText = [NSString stringWithFormat:NSLocalizedString(@"Move all sources from %@ to Zebra", @""), [availableManagers objectAtIndex:indexPath.row]];
    } else if (indexPath.section == 1) {
        if ([ZBDevice isCheckrain]) {
            if (indexPath.row == 0) {
                cellText = @"checkra1n Substrate Repo";
                iconURL = NULL;
                subText = [NSString stringWithFormat:NSLocalizedString(@"Utility repo for %@", @""), @"checkra1n jailbreak"];
            }
            else {
                cellText = @"Bingner/Elucubratus";
                iconURL = [NSURL URLWithString:@"https://apt.bingner.com/CydiaIcon.png"];
                subText = [NSString stringWithFormat:NSLocalizedString(@"Utility repo for %@", @""), @"checkra1n jailbreak"];
            }
        }
        else if ([ZBDevice isChimera]) { // chimera
            cellText = @"Chimera";
            iconURL = [NSURL URLWithString:@"https://repo.chimera.sh/CydiaIcon.png"];
            subText = [NSString stringWithFormat:NSLocalizedString(@"Utility repo for %@", @""), @"Chimera jailbreak"];
        } else if ([ZBDevice isUncover]) { // uncover
            cellText = @"Bingner/Elucubratus";
            iconURL = [NSURL URLWithString:@"https://apt.bingner.com/CydiaIcon.png"];
            subText = [NSString stringWithFormat:NSLocalizedString(@"Utility repo for %@", @""), @"unc0ver jailbreak"];
        } else if ([ZBDevice isElectra]) { // electra
            cellText = @"Electra's iOS Utilities";
            iconURL = [NSURL URLWithString:@"https://github.com/coolstar/electra/raw/master/electra/Resources/AppIcon60x60%402x.png"];
            subText = [NSString stringWithFormat:NSLocalizedString(@"Utility repo for %@", @""), @"Electra jailbreak"];
        } else { // cydia
            cellText = @"Cydia/Telesphoreo";
            iconURL = [NSURL URLWithString:@"http://apt.saurik.com/dists/ios/CydiaIcon.png"];
            subText = [NSString stringWithFormat:NSLocalizedString(@"Utility repo for %@", @""), @"Cydia"];
        }
    } else {
        NSDictionary *dataDict = [communityRepos objectAtIndex:indexPath.row];
        cellText = dataDict[@"name"];
        repoURL = [NSURL URLWithString:dataDict[@"url"]];
        iconURL = [NSURL URLWithString:dataDict[@"icon"]];
    }

    if (cellText) {
        [cell.sourceNameLabel setText:cellText];
//        [cell.repoLabel setTextColor:[UIColor cellPrimaryTextColor]];
    } else {
        cell.sourceNameLabel.text = nil;
    }

    if (subText && !repoURL) {
        [cell.sourceNameLabel setText:subText];
//        [cell.urlLabel setTextColor:[UIColor cellSecondaryTextColor]];
    } else if (repoURL) {
        [cell.sourceNameLabel setText:repoURL.absoluteString];
//        [cell.urlLabel setTextColor:[UIColor cellSecondaryTextColor]];
    } else {
        cell.sourceNameLabel.text = nil;
    }
    [cell.iconImageView sd_setImageWithURL:iconURL placeholderImage:[UIImage imageNamed:@"Unknown"]];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.font = [UIFont boldSystemFontOfSize:15];
//    header.textLabel.textColor = [UIColor cellPrimaryTextColor];
    header.tintColor = [UIColor clearColor];
    [(UIView *)[header valueForKey:@"_backgroundView"] setBackgroundColor:[UIColor clearColor]];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"Transfer Sources", @"");
        case 1:
            return NSLocalizedString(@"Utilities", @"");
        case 2:
            return NSLocalizedString(@"Community Repos", @"");
        default:
            return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ZBTransfer:
            if ([[availableManagers objectAtIndex:indexPath.row] isEqualToString:@"Cydia"]) {
                [self.repoManager transferFromCydia];
                [self presentConsole];
            } else if ([[availableManagers objectAtIndex:indexPath.row] isEqualToString:@"Sileo"]) {
                [self.repoManager transferFromSileo];
                [self presentConsole];
            }
            break;
        case ZBJailbreakRepo: {
            NSArray *jailbreakRepos = [self determineJailbreakRepo];
            [self addReposWithText:jailbreakRepos[indexPath.row]];
            break;
        }
        case ZBCommunity: {
            NSDictionary *dict = [communityRepos objectAtIndex:indexPath.row];
            [self addReposWithText:dict[@"clickLink"]];
            break;
        }
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)presentConsole {
    ZBRefreshViewController *refreshController = [[ZBRefreshViewController alloc] init];
    [self presentViewController:refreshController animated:YES completion:nil];
}

#pragma mark Add Repos

- (void)addReposWithText:(NSString *)text {
    UIAlertController *wait = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please Wait...", @"") message:NSLocalizedString(@"Verifying Source(s)", @"") preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:wait animated:YES completion:nil];

    __weak typeof(self) weakSelf = self;
    __weak typeof(ZBSourceManager *) repoManager = self.repoManager;

    [repoManager addSourcesFromString:text response:^(BOOL success, NSString * _Nonnull error, NSArray<NSURL *> * _Nonnull failedURLs) {
        [weakSelf dismissViewControllerAnimated:YES completion:^{
            if (!success) {
                UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"") message:error preferredStyle:UIAlertControllerStyleAlert];

                if (failedURLs.count) {
                    UIAlertAction *retryAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [weakSelf addReposWithText:text];
                    }];

                    [errorAlert addAction:retryAction];

                    UIAlertAction *editAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Edit", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        if ([failedURLs count] > 1) {
                            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                            ZBAddRepoViewController *addRepo = [storyboard instantiateViewControllerWithIdentifier:@"addSourcesController"];
                            addRepo.delegate = weakSelf;
                            addRepo.text = text;

                            UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:addRepo];

                            [weakSelf presentViewController:navCon animated:YES completion:nil];
                        }
                        /*else {
                            NSURL *failedURL = [failedURLs[0] URLByDeletingLastPathComponent];
                            [weakSelf showAddRepoAlert:failedURL];
                        }*/
                    }];

                    [errorAlert addAction:editAction];
                }

                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil];

                [errorAlert addAction:cancelAction];

                [weakSelf presentViewController:errorAlert animated:YES completion:nil];
            } else {
                ZBRefreshViewController *refreshController = [[ZBRefreshViewController alloc] initWithRepoURLs:[repoManager verifiedURLs]];                
                [weakSelf presentViewController:refreshController animated:YES completion:nil];
            }
        }];
    }];
}

- (void)didAddReposWithText:(NSString *)text {
    [self addReposWithText:text];
}

@end
