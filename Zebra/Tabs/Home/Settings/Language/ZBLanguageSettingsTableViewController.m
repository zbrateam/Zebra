//
//  ZBLanguageSettingsTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/26/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBLanguageSettingsTableViewController.h"
#import "UITableView+Settings.h"
#import "ZBSwitchSettingsTableViewCell.h"
#import "ZBOptionSubtitleSettingsTableViewCell.h"
#import "ZBLinkSettingsTableViewCell.h"

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

- (id)init {
    self = [super init];
    
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
    
    [self.tableView registerCellTypes:@[@(ZBSwitchSettingsCell), @(ZBOptionSubtitleSettingsCell), @(ZBLinkSettingsCell)]];
    
    [self layoutNavigationButtons];
}

- (void)layoutNavigationButtons {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Apply", @"") style:UIBarButtonItemStyleDone target:self action:@selector(applyChanges)];
    self.navigationItem.rightBarButtonItem.enabled = [self differentSettings];
}

- (BOOL)differentSettings {
    return (useSystemLanguage != originalUseSystemLanguage || (selectedRow && (selectedLanguage != originalLanguage && ![selectedLanguage isEqual:originalLanguage])));
}

- (void)applyChanges {
    if (![[[NSBundle mainBundle] preferredLocalizations][0] isEqual:selectedLanguage] || self->useSystemLanguage != self->originalUseSystemLanguage) {
        UIAlertController *confirm = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Restart Required", @"") message:NSLocalizedString(@"Zebra must be closed in order to change preferred language", @"") preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Restart", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            if (self->useSystemLanguage || !self->selectedRow) {
                [ZBSettings setSelectedLanguage:NULL];
            }
            else {
                [ZBSettings setSelectedLanguage:self->selectedLanguage];
            }
            [ZBSettings setUsesSystemLanguage:self->useSystemLanguage];
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
        [[self navigationController] popViewControllerAnimated:YES];
    }
}

- (void)toggleSystemLanguage:(NSNumber *)newUseSystemLanguage {
    useSystemLanguage = [newUseSystemLanguage boolValue];

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
    return useSystemLanguage ? 2 : 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self numberOfSectionsInTableView:tableView] == 3) {
        return section == 0 || section == 2 ? 1 : languages.count;
    }
    else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        ZBSwitchSettingsTableViewCell *cell = [tableView dequeueSwitchSettingsCellForIndexPath:indexPath];

        cell.textLabel.text = NSLocalizedString(@"Use System Language", @"");
        
        [cell setOn:useSystemLanguage];
        [cell setTarget:self action:@selector(toggleSystemLanguage:)];
        [cell applyStyling];

        return cell;
    } else if ([self numberOfSectionsInTableView:tableView] == 3 && indexPath.section == 1) {
        NSString *languageCode = languages[indexPath.row];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:languageCode];
        NSLocale *currentLocale = [NSLocale currentLocale];
        
        NSString *displayName = [[locale displayNameForKey:NSLocaleIdentifier value:languageCode] capitalizedStringWithLocale:locale];
        NSString *localizedDisplayName = [[currentLocale displayNameForKey:NSLocaleIdentifier value:languageCode] capitalizedStringWithLocale:currentLocale];
        
        ZBOptionSubtitleSettingsTableViewCell *cell = [tableView dequeueOptionSubtitleSettingsCellForIndexPath:indexPath];

        [cell setChosen:[indexPath isEqual:selectedRow]];
        [cell applyStyling];
        cell.textLabel.text = displayName;
        cell.detailTextLabel.text = localizedDisplayName;
        
        return cell;
    } else {
        ZBLinkSettingsTableViewCell *cell = [tableView dequeueLinkSettingsCellForIndexPath:indexPath];
        
        cell.textLabel.text = NSLocalizedString(@"Help translate Zebra!", @"");
        cell.imageView.image = [UIImage imageNamed:@"Translations"];
        
        [cell applyStyling];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        ZBSwitchSettingsTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell toggle];
    }
    else if ([self numberOfSectionsInTableView:tableView] == 3 && indexPath.section == 1 && ![indexPath isEqual:selectedRow]) {
        NSIndexPath *previousChoice = selectedRow;
        if (previousChoice.row != indexPath.row) {
            selectedLanguage = languages[indexPath.row];
            selectedRow = indexPath;
            
            [self layoutNavigationButtons];
            [self chooseOptionAtIndexPath:indexPath previousIndexPath:previousChoice animated:YES];
        }
    }
    else if (([self numberOfSectionsInTableView:tableView] == 3 && indexPath.section == 2) || ([self numberOfSectionsInTableView:tableView] == 2 && indexPath.section == 1)) {
        [ZBDevice openURL:[NSURL URLWithString:@"https://translate.getzbra.com/"] sender:self];
    }
}

@end
