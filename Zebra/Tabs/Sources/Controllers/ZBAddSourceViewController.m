//
//  ZBAddSourceViewController.m
//  Zebra
//
//  Created by shiftcmdk on 04/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSourceListTableViewController.h"
#import "ZBAddSourceViewController.h"
#import "ZBBaseSource.h"
#import "ZBSourceManager.h"

#import <Extensions/UIColor+GlobalColors.h>
#import <Theme/ZBThemeManager.h>

@interface ZBAddSourceViewController ()
@property (weak, nonatomic) IBOutlet UITextView *addSourceTextView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textFieldBottomConstraint;
@property (nonatomic, copy) NSString *text;
@property id <ZBSourceVerificationDelegate> delegate;
@end

@implementation ZBAddSourceViewController

@synthesize delegate;

+ (UINavigationController *)controllerWithText:(NSString * _Nullable)text delegate:(id <ZBSourceVerificationDelegate>)delegate {
    ZBAddSourceViewController *addSourceVC = [[ZBAddSourceViewController alloc] initWithText:text delegate:delegate];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addSourceVC];
    
    return navController;
}

- (id)initWithText:(NSString *)text delegate:(id <ZBSourceVerificationDelegate>)delegate {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"addSourcesController"];
    
    if (self) {
        self.text = text;
        self.delegate = delegate;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyLocalization];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    self.addSourceTextView.backgroundColor = [UIColor cellBackgroundColor];
    self.addSourceTextView.textColor = [UIColor primaryTextColor];
    self.addSourceTextView.delegate = self;
    
    if (self.text && [self.text hasPrefix:@"http"]) {
        self.addSourceTextView.text = self.text;
        [self textViewDidChange:self.addSourceTextView];
    }
}

- (void)applyLocalization {
    self.addButton.title = NSLocalizedString(@"Add", @"");
    self.navigationItem.title = NSLocalizedString(@"Add Sources", @"");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[ZBThemeManager sharedInstance] configureKeyboard:self.addSourceTextView];
    [self.addSourceTextView becomeFirstResponder];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    double duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect frame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.textFieldBottomConstraint.constant = frame.size.height;
    
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    double duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.textFieldBottomConstraint.constant = 0.0;
    
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)cancelButtonTapped:(UIBarButtonItem *)sender {
    [self.addSourceTextView resignFirstResponder];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addButtonTapped:(UIBarButtonItem *)sender {
    [self.addSourceTextView resignFirstResponder];
    
    NSError *detectorError = nil;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&detectorError];
    if (detectorError) {
        UIAlertController *errorPopup = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"An Error Occurred", @"") message:detectorError.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        
        [errorPopup addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:errorPopup animated:YES completion:nil];
    }
    else {
        NSMutableArray <NSURL *> *detectedURLs = [NSMutableArray new];
        
        NSString *sourcesString = self.addSourceTextView.text;
        [detector enumerateMatchesInString:sourcesString options:0 range:NSMakeRange(0, sourcesString.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            if (result.resultType == NSTextCheckingTypeLink) {
                [detectedURLs addObject:result.URL];
            }
        }];
        
        NSSet *baseSources = [ZBBaseSource baseSourcesFromURLs:detectedURLs];
        
        [self dismissViewControllerAnimated:YES completion:^{
            if (self->delegate) {
                [self->delegate verifyAndAdd:baseSources];
            }
        }];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        textView.text = [textView.text stringByAppendingString:@"\nhttps://"];
        return NO;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    // check if it is URL or not
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http(s)?://((\\w)|([0-9])|([-|_]))+(\\.|/)+((\\w)|([0-9])|([-|_]))+" options:NSRegularExpressionCaseInsensitive
    error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:textView.text options:0 range:NSMakeRange(0, textView.text.length)];
    
    if (match) {
        [self.addButton setEnabled:YES];
    }
    else {
        [self.addButton setEnabled:NO];
    }
}

@end
