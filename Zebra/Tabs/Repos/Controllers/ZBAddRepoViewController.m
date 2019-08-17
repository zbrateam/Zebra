//
//  ZBAddRepoViewController.m
//  Zebra
//
//  Created by shiftcmdk on 04/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBAddRepoViewController.h"
#import "UIColor+GlobalColors.h"

@interface ZBAddRepoViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *addRepoTextView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textFieldBottomConstraint;

@end

@implementation ZBAddRepoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    self.addRepoTextView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.addRepoTextView.textColor = [UIColor cellPrimaryTextColor];
    self.addRepoTextView.delegate = self;
    
    if (self.text) {
        self.addRepoTextView.text = self.text;
        self.addButton.enabled = self.addRepoTextView.text.length;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.addRepoTextView becomeFirstResponder];
}

- (void)keyboardWillShow:(NSNotification*)notification {
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect frame = [[notification.userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.textFieldBottomConstraint.constant = frame.size.height;
    
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification*)notification {
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.textFieldBottomConstraint.constant = 0.0;
    
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)cancelButtonTapped:(UIBarButtonItem *)sender {
    [self.addRepoTextView resignFirstResponder];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addButtonTapped:(UIBarButtonItem *)sender {
    [self.addRepoTextView resignFirstResponder];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (self.delegate) {
            [self.delegate didAddReposWithText:self.addRepoTextView.text];
        }
    }];
}

- (void)textViewDidChange:(UITextView *)textView {
    self.addButton.enabled = self.addRepoTextView.text.length != 0;
}

@end
