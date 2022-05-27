//
//  ZBPackageSupportViewController.m
//  Zebra
//
//  Created by Wilson Styres on 5/15/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBPackageSupportViewController.h"
#import "Zebra-Swift.h"
#import <Plains/Plains.h>

@interface ZBPackageSupportViewController ()
@property (nonatomic, strong) PLPackage *package;
@end

@implementation ZBPackageSupportViewController

- (id)initWithPackage:(PLPackage *)package {
    self = [super init];
    
    if (self) {
        self.package = package;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor systemBackgroundColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // This is a temporary support view, will be replaced with a redesigned view in a later beta
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Support" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    if (self.package.author.email) {
        UIAlertAction *authorAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@ (Author)", self.package.author.name] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self sendEmailTo:self.package.author.email];
        }];
        [alert addAction:authorAction];
    }
    
    if (self.package.maintainer.email) {
        UIAlertAction *authorAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@ (Maintainer)", self.package.maintainer.name] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self sendEmailTo:self.package.maintainer.email];
        }];
        [alert addAction:authorAction];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)sendEmailTo:(NSString *)address {
    NSString *subject = [NSString stringWithFormat:@"Zebra/APT(A): %@ (%@)", self.package.name, self.package.version];
    NSString *body = [NSString stringWithFormat:@"%@-%@: %@", [UIDevice currentDevice].zbra_machine, [UIDevice currentDevice].systemVersion, [UIDevice currentDevice].zbra_udid];
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        [mail setSubject:subject];
        [mail setMessageBody:body isHTML:NO];
        [mail setToRecipients:@[address]];
        
        [self presentViewController:mail animated:YES completion:NULL];
    } else {
        NSString *email = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@", address, subject, body];
        NSString *url = [email stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        
        [self dismissViewControllerAnimated:YES completion:nil];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
