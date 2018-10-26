//
//  AUPMPackageViewController.h
//  AUPM
//
//  Created by Wilson Styres on 10/26/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "NSTask.h"

@class AUPMPackage;


NS_ASSUME_NONNULL_BEGIN

@interface AUPMPackageViewController : UIViewController <WKNavigationDelegate>
- (id)initWithPackage:(AUPMPackage *)package;
@end

NS_ASSUME_NONNULL_END
