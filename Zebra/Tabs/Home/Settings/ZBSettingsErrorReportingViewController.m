//
//  ZBSettingsErrorReportingViewController.m
//  Zebra
//
//  Created by Adam Demasi on 18/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import "ZBSettingsErrorReportingViewController.h"
#import "ZBSettings.h"

@implementation ZBSettingsErrorReportingViewController

- (instancetype)init {
    self = [self initWithOptions:@[@"Don’t Send Error Reports", @"Send Error Reports"]
                          getter:@selector(sendErrorReports)
                          setter:@selector(setSendErrorReports:)
          settingChangedCallback:nil];
    if (self) {
        self.title = @"Error Reports";
        self.footerText = @[
            @"Help improve Zebra by sending a report to the Zebra Team when the app encounters errors.",
            @"Error reports contain technical details of what led to the error. This may include details about your packages, sources, and settings. We try to ensure error reports are anonymous, with no uniquely identifying information about yourself, your device, or payment vendors you’ve logged into, however it is possible for such information to be unintentionally included on occasion.",
            @"Error reports are processed and stored by Sentry. To review their policies, visit https://sentry.io/legal."
        ];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.navigationController.viewControllers.count == 1) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(doneTapped)];
    }
}

- (void)doneTapped {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
