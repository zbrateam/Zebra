//
//  ZBFilterSettingsTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/12/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import SDWebImage;

#import "ZBFilterSettingsTableViewController.h"
#import <UIColor+GlobalColors.h>
#import <Sources/Views/ZBRepoTableViewCell.h>
#import <Sources/Helpers/ZBSource.h>

@interface ZBFilterSettingsTableViewController () {
    NSMutableArray <NSString *> *baseFilenames;
    NSDictionary <NSString *, NSArray *> *filteredSources;
}
@end

@implementation ZBFilterSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!filteredSources) filteredSources = [[ZBSettings filteredSources] mutableCopy];
    if (!baseFilenames) baseFilenames = [[filteredSources allKeys] mutableCopy];
    
    self.navigationItem.title = NSLocalizedString(@"Filters", @"");
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZBRepoTableViewCell" bundle:nil] forCellReuseIdentifier:@"repoTableViewCell"];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
        case 1:
            return [filteredSources count] + 1;
        case 2:
            return 1;
        case 3:
            return 1;
        default:
            return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"filterCell"];
    
    switch (indexPath.section) {
        case 0: {
            break;
        }
        case 1: {
            if (indexPath.row < [filteredSources count]) {
                ZBRepoTableViewCell *repoCell = [tableView dequeueReusableCellWithIdentifier:@"repoTableViewCell" forIndexPath:indexPath];
                NSString *baseFilename = baseFilenames[indexPath.row];
                ZBSource *source = [ZBSource sourceFromBaseFilename:baseFilename];
                
                repoCell.repoLabel.text = [source label];
                
                unsigned long numberOfSections = (unsigned long)[filteredSources[baseFilename] count];
                repoCell.urlLabel.text = numberOfSections == 1 ? NSLocalizedString(@"1 Section Filtered", @"") : [NSString stringWithFormat:NSLocalizedString(@"%lu Sections Hidden", @""), numberOfSections];
                
                [repoCell.iconImageView sd_setImageWithURL:[source iconURL] placeholderImage:[UIImage imageNamed:@"Unknown"]];
                
                return repoCell;
            }
            break;
        }
        case 2: {
            break;
        }
        case 3: {
            break;
        }
    }
    
    cell.textLabel.text = @"Add Filter";
    cell.textLabel.textColor = [UIColor accentColor];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"Sections", @"");
        case 1:
            return NSLocalizedString(@"Sources", @"");
        case 2:
            return NSLocalizedString(@"Ignored Updates", @"");
        case 3:
            return NSLocalizedString(@"Blocked Authors", @"");
    }
    return NULL;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"Hide packages in these sections.", @"");
        case 1:
            return NSLocalizedString(@"Hide packages in these sections from specific sources.", @"");
        case 2:
            return NSLocalizedString(@"Ignore any future updates from these packages.", @"");
        case 3:
            return NSLocalizedString(@"Hide all packages from these authors.", @"");
    }
    return NULL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    UIAlertController *addFilter = [UIAlertController alertControllerWithTitle:@"Add Filter" message:@"Add a Filter" preferredStyle:UIAlertControllerStyleAlert];
    
    [addFilter addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Enter Filter";
    }];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:nil];
    [addFilter addAction:action];
    
    [self presentViewController:addFilter animated:true completion:nil];
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
