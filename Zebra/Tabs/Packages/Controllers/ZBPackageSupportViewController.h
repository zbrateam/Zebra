//
//  ZBPackageSupportViewController.h
//  Zebra
//
//  Created by Wilson Styres on 5/15/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Packages/Helpers/ZBPackageInfoController.h>

@import UIKit;
@import MessageUI;

NS_ASSUME_NONNULL_BEGIN

@interface ZBPackageSupportViewController : UIViewController <ZBPackageInfoController, MFMailComposeViewControllerDelegate>

@end

NS_ASSUME_NONNULL_END
