//
//  ZBLanguageSettingsTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/26/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBLanguageSettingsTableViewController.h"

#import <ZBSettings.h>
#import <Extensions/UIColor+GlobalColors.h>

@interface ZBLanguageSettingsTableViewController () {
    BOOL useSystemLanguage;
    NSMutableArray *languages;
    NSString *selectedLanguage;
    NSIndexPath *selectedRow;
    
    BOOL originalUseSystemLanguage;
    NSString *originalLanguage;
}
@end

@implementation ZBLanguageSettingsTableViewController

- (id)init API_AVAILABLE(ios(10.0)) {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        useSystemLanguage = [ZBSettings usesSystemLanguage];
        originalUseSystemLanguage = useSystemLanguage;
        
        
        languages = [[[[NSBundle mainBundle] localizations] sortedArrayUsingComparator:^NSComparisonResult(NSString *code1, NSString *code2) {
            NSString *name1 = [[NSLocale currentLocale] localizedStringForLanguageCode:code1];
            NSString *name2 = [[NSLocale currentLocale] localizedStringForLanguageCode:code2];
            
            return [name1 compare:name2];
        }] mutableCopy];
        
        [languages removeObject:@"Base"];
        
        selectedLanguage = [ZBSettings selectedLanguage];
        originalLanguage = selectedLanguage;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Language", @"");
//    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"languageCell"];
    
    [self layoutNavigationButtons];
}

- (void)layoutNavigationButtons {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(applyChanges)];
    self.navigationItem.rightBarButtonItem.enabled = [self differentSettings];
}

- (BOOL)differentSettings {
    return (useSystemLanguage != originalUseSystemLanguage || (selectedLanguage != originalLanguage && ![selectedLanguage isEqual:originalLanguage]));
}

- (void)applyChanges {
    
}

- (void)toggleSystemLanguage:(UISwitch *)sender {
    useSystemLanguage = sender.isOn;
    
    if (useSystemLanguage) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }
    else {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self layoutNavigationButtons];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return useSystemLanguage ? 1 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : [languages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(10.0)) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"languageCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"languageCell"];
    }
    
    if (indexPath.section == 0) {
        UISwitch *languageSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [languageSwitch setOn:useSystemLanguage];
        [languageSwitch addTarget:self action:@selector(toggleSystemLanguage:) forControlEvents:UIControlEventValueChanged];
        [languageSwitch setOnTintColor:[UIColor accentColor]];
        
        cell.accessoryView = languageSwitch;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = NSLocalizedString(@"Use System Language", @"");
        
        return cell;
    }
    else {
        NSString *languageCode = languages[indexPath.row];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:languageCode];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = NULL;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.textLabel.text = [[NSLocale currentLocale] localizedStringForLanguageCode:languageCode] ?: languageCode;
        
        NSString *countryName = [[NSLocale currentLocale] localizedStringForCountryCode:[locale countryCode]];
        NSString *scriptName = [[NSLocale currentLocale] localizedStringForScriptCode:[locale scriptCode]];
        if (countryName && scriptName) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", countryName, scriptName];
        }
        else if (countryName) {
            cell.detailTextLabel.text = countryName;
        }
        else if (scriptName) {
            cell.detailTextLabel.text = scriptName;
        }
        else {
            cell.detailTextLabel.text = NULL;
        }
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    if (indexPath.section == 1) {
        
        [self layoutNavigationButtons];
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
