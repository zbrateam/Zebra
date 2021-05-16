//
//  ZBSourceBulkAddViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/9/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBSourceBulkAddViewController.h"

#import <Extensions/ZBColor.h>
#import <UI/Sources/ZBSourceImportViewController.h>

@interface ZBSourceBulkAddViewController ()
@property UITextView *textView;
@property NSLayoutConstraint *textViewBottomConstraint;
@end

@implementation ZBSourceBulkAddViewController

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.title = NSLocalizedString(@"Bulk Add", @"");
        
        self.textView = [[UITextView alloc] init];
        self.textView.delegate = self;
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [ZBColor systemGroupedBackgroundColor];
    self.textViewBottomConstraint = [[_textView bottomAnchor] constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-10];
    
    [self.view addSubview:_textView];
    [NSLayoutConstraint activateConstraints:@[
        [[_textView leadingAnchor] constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:10],
        [[_textView trailingAnchor] constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-10],
        [[_textView topAnchor] constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10],
        self.textViewBottomConstraint
    ]];
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _textView.layer.cornerRadius = self.view.frame.size.height / 38.5;
    _textView.layer.masksToBounds = NO;
    _textView.textContainerInset = UIEdgeInsetsMake(10, 20, 10, 10);
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Verify", @"") style:UIBarButtonItemStyleDone target:self action:@selector(verifySources)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [_textView becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)verifySources {
//    [_textView resignFirstResponder];
//    
//    NSError *detectorError = nil;
//    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&detectorError];
//    if (detectorError) {
//        UIAlertController *errorPopup = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"An Error Occurred", @"") message:detectorError.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
//        
//        [errorPopup addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil]];
//        
//        [self presentViewController:errorPopup animated:YES completion:nil];
//    } else {
//        NSMutableArray <NSURL *> *detectedURLs = [NSMutableArray new];
//        
//        NSString *fullText = _textView.textStorage.string;
//        [detector enumerateMatchesInString:fullText options:0 range:NSMakeRange(0, fullText.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
//            if (result.resultType == NSTextCheckingTypeLink) {
//                [detectedURLs addObject:result.URL];
//            }
//        }];
//        
//        NSSet *baseSources = [ZBBaseSource baseSourcesFromURLs:detectedURLs];
//        ZBSourceImportViewController *importVC = [[ZBSourceImportViewController alloc] initWithSources:baseSources];
//        [self.navigationController pushViewController:importVC animated:YES];
//    }
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = ((NSValue *)notification.userInfo[UIKeyboardFrameEndUserInfoKey]).CGRectValue;
    self.textViewBottomConstraint.constant = -keyboardFrame.size.height;
    self.textViewBottomConstraint.active = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.textViewBottomConstraint.constant = 10;
    self.textViewBottomConstraint.active = YES;
}

#pragma mark - Text View Delegate

- (void)textViewDidChange:(UITextView *)textView {
    self.navigationItem.rightBarButtonItem.enabled = ![[textView.textStorage.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""];
}

#pragma mark - Keyboard Shortcuts

- (NSArray<UIKeyCommand *> *)keyCommands {
    // escape key
    UIKeyCommand *back = [UIKeyCommand keyCommandWithInput:@"\e" modifierFlags:0 action:@selector(back)];
    back.discoverabilityTitle = NSLocalizedString(@"Back", @"");

    return @[back];
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
