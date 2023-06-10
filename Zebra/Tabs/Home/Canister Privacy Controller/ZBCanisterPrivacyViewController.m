//
//  ZBCanisterPrivacyViewController.m
//  Zebra
//
//  Created by Amy While on 10/06/2023.
//  Copyright © 2023 Zebra Team. All rights reserved.
//

#import "ZBCanisterPrivacyViewController.h"

@interface ZBCanisterPrivacyViewController ()

@end

NSURL *privacyPolicy;

@implementation ZBCanisterPrivacyViewController

+ (void)load {
    privacyPolicy = [[NSURL alloc] initWithString:@"https://canister.me/privacy"];
}

-(instancetype)initWithURL:(NSURL *)url {
    privacyPolicy = url;
    return [self initWithNibName:nil bundle:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIImageView *headerImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        headerImage.translatesAutoresizingMaskIntoConstraints = false;
        headerImage.image = [[UIImage imageNamed:@"Canister"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        headerImage.contentMode = UIViewContentModeScaleAspectFit;
        headerImage.tintColor = [UIColor accentColor];
        [self.view addSubview:headerImage];
        
        
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        headerLabel.translatesAutoresizingMaskIntoConstraints = false;
        headerLabel.text = NSLocalizedString(@"Canister Privacy Policy", @"");
        headerLabel.adjustsFontSizeToFitWidth = true;
        headerLabel.textColor = [UIColor primaryTextColor];
        headerLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
        headerLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:headerLabel];
        
        UIStackView *bodyStackView = [[UIStackView alloc] initWithFrame:CGRectZero];
        bodyStackView.translatesAutoresizingMaskIntoConstraints = false;
        bodyStackView.alignment = UIStackViewAlignmentFill;
        bodyStackView.axis = UILayoutConstraintAxisVertical;
        bodyStackView.distribution = UIStackViewDistributionFill;
        bodyStackView.spacing = 10;
        
        UIStackView *buttonStackView = [[UIStackView alloc] initWithFrame:CGRectZero];
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false;
        buttonStackView.axis = UILayoutConstraintAxisVertical;
        buttonStackView.spacing = 10;
        
        UILabel *bodyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false;
        bodyLabel.text = NSLocalizedString(@"Canister Data Collection", @"");
        bodyLabel.textColor = [UIColor primaryTextColor];
        bodyLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        bodyLabel.numberOfLines = 0;
        
        UIButton *privacyPolicy = [[UIButton alloc] initWithFrame:CGRectZero];
        privacyPolicy.translatesAutoresizingMaskIntoConstraints = false;
        [privacyPolicy setTitle:NSLocalizedString(@"Privacy Policy", @"") forState:UIControlStateNormal];
        [privacyPolicy setTitleColor:[UIColor accentColor] forState:UIControlStateNormal];
        [privacyPolicy addTarget:self action:@selector(openPrivacyPolicy) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *decline = [[UIButton alloc] initWithFrame:CGRectZero];
        decline.translatesAutoresizingMaskIntoConstraints = false;
        [decline setTitle:NSLocalizedString(@"Decline", @"") forState:UIControlStateNormal];
        [decline setTitleColor:[UIColor accentColor] forState:UIControlStateNormal];
        [decline addTarget:self action:@selector(openDecline) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *accept = [[UIButton alloc] initWithFrame:CGRectZero];
        accept.translatesAutoresizingMaskIntoConstraints = false;
        [accept setTitle:NSLocalizedString(@"Accept", @"") forState:UIControlStateNormal];
        [accept setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        accept.backgroundColor = [UIColor accentColor];
        accept.layer.masksToBounds = true;
        accept.layer.cornerRadius = 7.5;
        [accept addTarget:self action:@selector(openAccept) forControlEvents:UIControlEventTouchUpInside];
        
        [bodyStackView addArrangedSubview:bodyLabel];
        [bodyStackView addArrangedSubview:buttonStackView];
        [buttonStackView addArrangedSubview:privacyPolicy];
        [buttonStackView addArrangedSubview:decline];
        [buttonStackView addArrangedSubview:accept];

        double buttonHeights = 0;
        switch ((int)[UIScreen mainScreen].scale) {
            case 1:
                buttonHeights = 40;
                break;
            case 2:
                buttonHeights = 40;
                break;
            default: buttonHeights = 45;
        }
        
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        scrollView.translatesAutoresizingMaskIntoConstraints = false;
        scrollView.directionalLockEnabled = true;
        [scrollView addSubview:bodyStackView];
        
        [self.view addSubview:scrollView];
        
        [NSLayoutConstraint activateConstraints:@[
            [headerImage.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:15],
            [headerImage.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant: 15],
            [headerImage.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant: -15],
            [headerImage.heightAnchor constraintEqualToConstant:150],
            
            [headerLabel.topAnchor constraintEqualToAnchor: headerImage.bottomAnchor constant:14],
            [headerLabel.leadingAnchor constraintEqualToAnchor:headerImage.leadingAnchor],
            [headerLabel.trailingAnchor constraintEqualToAnchor:headerImage.trailingAnchor],
            
            [scrollView.topAnchor constraintEqualToAnchor:headerLabel.bottomAnchor constant:35],
            [scrollView.leadingAnchor constraintEqualToAnchor:headerImage.leadingAnchor],
            [scrollView.trailingAnchor constraintEqualToAnchor:headerImage.trailingAnchor],
            [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant: -15],
            
            [scrollView.contentLayoutGuide.leadingAnchor constraintEqualToAnchor:bodyStackView.leadingAnchor],
            [scrollView.contentLayoutGuide.trailingAnchor constraintEqualToAnchor:bodyStackView.trailingAnchor],
            [scrollView.contentLayoutGuide.topAnchor constraintEqualToAnchor:bodyStackView.topAnchor],
            [scrollView.contentLayoutGuide.bottomAnchor constraintEqualToAnchor:bodyStackView.bottomAnchor],
            
            [scrollView.frameLayoutGuide.widthAnchor constraintEqualToAnchor:bodyStackView.widthAnchor],
            
            [accept.heightAnchor constraintEqualToConstant:buttonHeights],
            [decline.heightAnchor constraintEqualToConstant:buttonHeights],
            [privacyPolicy.heightAnchor constraintEqualToConstant: buttonHeights]
        ]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor groupedTableViewBackgroundColor];
}

- (void)openPrivacyPolicy {
    [[UIApplication sharedApplication] openURL:privacyPolicy];
}

- (void)openAccept {
    [[NSUserDefaults standardUserDefaults] setObject:[[NSNumber alloc] initWithInt:1] forKey:@"CanisterIngest"];
    [self dismissViewControllerAnimated:true completion:nil];
}
 
- (void)openDecline {
    [[NSUserDefaults standardUserDefaults] setObject:[[NSNumber alloc] initWithInt:0] forKey:@"CanisterIngest"];
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
