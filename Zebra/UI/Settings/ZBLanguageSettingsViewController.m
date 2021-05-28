//
//  ZBLanguageSettingsViewController.m
//  Zebra
//
//  Created by Wilson Styres on 5/28/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBLanguageSettingsViewController.h"

#import <ZBSettings.h>

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
            selectedRow = [NSIndexPath indexPathForRow:[languages indexOfObject:selectedLanguage] inSection:1];
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
    
    if (useSystemLanguage) {
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
    
    return specifiers;
}

- (void)toggleUseSystemLanguage:(UISwitch *)toggleSwitch {
    useSystemLanguage = toggleSwitch.isOn;
    
    if (useSystemLanguage) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }
    else {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)selectLanguage:(NSIndexPath *)indexPath {
    
}

@end
