//
//  ZBLanguageSettingsViewController.m
//  Zebra
//
//  Created by Wilson Styres on 5/28/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBLanguageSettingsViewController.h"

#import <ZBDevice.h>
#import <ZBSettings.h>

#import <SafariServices/SafariServices.h>

@implementation ZBLanguageSettingsViewController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.title = @"Languages";
        
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
            self.selectedRows = [NSMutableDictionary dictionaryWithDictionary:@{@1: @([languages indexOfObject:selectedLanguage])}];
        }
    }
    
    return self;
}

- (NSArray <NSArray <NSDictionary *> *> *)specifiers {
    NSMutableArray *specifiers = [NSMutableArray new];
    
    [specifiers addObject:@[@{
        @"text": @"Use System Language",
        @"type": @(ZBPreferencesCellTypeSwitch),
        @"enabled": @(useSystemLanguage),
        @"action": @"toggleUseSystemLanguage:"
    }]];
    
    if (!useSystemLanguage) {
        NSMutableArray *languageSpecifiers = [NSMutableArray new];
        
        for (NSString *languageCode in languages) {
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:languageCode];
            NSLocale *currentLocale = [NSLocale currentLocale];
            
            NSString *displayName = [[locale displayNameForKey:NSLocaleIdentifier value:languageCode] capitalizedStringWithLocale:locale];
            NSString *localizedDisplayName = [[currentLocale displayNameForKey:NSLocaleIdentifier value:languageCode] capitalizedStringWithLocale:currentLocale];
            
            [languageSpecifiers addObject:@{
                @"text": displayName,
                @"subtext": localizedDisplayName,
                @"type": @(ZBPreferencesCellTypeSelection),
                @"action": @"selectLanguage:"
            }];
        }
        
        [specifiers addObject:languageSpecifiers];
    }
    
    [specifiers addObject:@[@{
        @"text": @"Help translate Zebra!",
        @"type": @(ZBPreferencesCellTypeDisclosure),
        @"action": @"showCrowdIn",
        @"icon": [UIImage imageNamed:@"Translations"]
    }]];
    
    return specifiers;
}

- (void)layoutNavigationButtons {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Apply", @"") style:UIBarButtonItemStyleDone target:self action:@selector(applyButton:)];
        self.navigationItem.rightBarButtonItem.enabled = [self differentSettings];
    });
}

- (BOOL)differentSettings {
    return (useSystemLanguage != originalUseSystemLanguage || (selectedLanguage != originalLanguage && ![selectedLanguage isEqual:originalLanguage]));
}

- (void)toggleUseSystemLanguage:(UISwitch *)toggleSwitch {
    useSystemLanguage = toggleSwitch.isOn;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (useSystemLanguage) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        }
        else {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        }
    });
    
#if TARGET_OS_IOS
    [self layoutNavigationButtons];
#endif
}

- (void)selectLanguage:(NSIndexPath *)indexPath {
    selectedLanguage = languages[indexPath.row];
    
#if TARGET_OS_IOS
    [self layoutNavigationButtons];
#endif
}

#if TARGET_OS_MACCATALYST
- (NSArray *)toolbarItems {
    return @[@"applyButton"];
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
    return [self differentSettings];
}
#endif

- (void)showCrowdIn {
    SFSafariViewController *sfvc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://translate.getzbra.com/"]];
    
    [self presentViewController:sfvc animated:YES completion:nil];
}

- (void)applyButton:(id)sender {
    if (![[[NSBundle mainBundle] preferredLocalizations][0] isEqual:selectedLanguage] || self->useSystemLanguage != self->originalUseSystemLanguage) {
        UIAlertController *confirm = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Restart Required", @"") message:NSLocalizedString(@"Zebra must be closed in order to change preferred language", @"") preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Restart", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            if (self->useSystemLanguage) {
                [ZBSettings setSelectedLanguage:NULL];
            }
            else {
                [ZBSettings setSelectedLanguage:self->selectedLanguage];
            }
            [ZBSettings setUsesSystemLanguage:self->useSystemLanguage];
            [ZBDevice relaunchZebra];
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

@end
