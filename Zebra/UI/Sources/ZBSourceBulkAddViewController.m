//
//  ZBSourceBulkAddViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/9/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBSourceBulkAddViewController.h"

@interface ZBSourceBulkAddViewController ()
@property UITextView *textView;
@end

@implementation ZBSourceBulkAddViewController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.title = NSLocalizedString(@"Bulk Add", @"");
        
        self.textView = [[UITextView alloc] init];
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    [self.view addSubview:_textView];
    [NSLayoutConstraint activateConstraints:@[
        [[_textView leadingAnchor] constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:10],
        [[_textView trailingAnchor] constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-10],
        [[_textView topAnchor] constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10],
        [[_textView bottomAnchor] constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:10],
    ]];
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _textView.layer.cornerRadius = self.view.frame.size.height / 38.5;
    _textView.layer.masksToBounds = NO;
    _textView.contentInset = UIEdgeInsetsMake(10, 20, 10, 10);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

@end
