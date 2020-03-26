//
//  ZBLanguageSettingsTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/26/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBLanguageSettingsTableViewController.h"

#import <ZBDevice.h>
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
        
        if (selectedLanguage) {
            selectedRow = [NSIndexPath indexPathForRow:[languages indexOfObject:selectedLanguage] inSection:1];
        }
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
    return (useSystemLanguage != originalUseSystemLanguage || (selectedRow && (selectedLanguage != originalLanguage && ![selectedLanguage isEqual:originalLanguage])));
}

- (void)applyChanges {
    if (![[[NSBundle mainBundle] preferredLocalizations][0] isEqual:selectedLanguage]) {
        UIAlertController *confirm = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Restart Required", @"") message:NSLocalizedString(@"Zebra must be closed in order to change preferred language", @"") preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Restart", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if (self->useSystemLanguage) {
                [defaults removeObjectForKey:@"AppleLanguages"];
            }
            else {
                [defaults setObject:@[self->selectedLanguage] forKey:@"AppleLanguages"];
            }
            
            [defaults synchronize];
            [ZBDevice exitZebra];
        }];
        [confirm addAction:confirmAction];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Close", @"") style:UIAlertActionStyleCancel handler:nil];
        [confirm addAction:cancelAction];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:confirm animated:YES completion:nil];
        });
    }
    else {
        [[self navigationController] popViewControllerAnimated:true];
    }
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
        
        cell.accessoryView = NULL;
        cell.accessoryType = [indexPath isEqual:selectedRow] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
    
    if (indexPath.section == 1 && ![indexPath isEqual:selectedRow]) {
        NSString *newLanguage = languages[indexPath.row];
        
        selectedLanguage = newLanguage;
        selectedRow = [NSIndexPath indexPathForRow:[languages indexOfObject:selectedLanguage] inSection:1];
        
        [self layoutNavigationButtons];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
