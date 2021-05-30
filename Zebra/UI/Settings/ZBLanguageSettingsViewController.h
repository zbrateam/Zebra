//
//  ZBLanguageSettingsViewController.h
//  Zebra
//
//  Created by Wilson Styres on 5/28/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBPreferencesViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBLanguageSettingsViewController : ZBPreferencesViewController {
    BOOL useSystemLanguage;
    NSMutableArray *languages;
    
    NSString *selectedLanguage;
    
    BOOL originalUseSystemLanguage;
    NSString *originalLanguage;
}
@end

NS_ASSUME_NONNULL_END
