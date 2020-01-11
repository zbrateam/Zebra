//
//  ZBAddSourceViewController.m
//  Zebra
//
//  Created by shiftcmdk on 04/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSourceListTableViewController.h"
#import "ZBAddSourceViewController.h"
#import "UIColor+GlobalColors.h"
#import "ZBBaseSource.h"
#import "ZBSourceManager.h"

@interface ZBAddSourceViewController ()
@property (weak, nonatomic) IBOutlet UITextView *addRepoTextView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textFieldBottomConstraint;
@property (nonatomic, copy) NSString *text;
@property id <ZBSourceVerificationDelegate> delegate;
@end

@implementation ZBAddSourceViewController

@synthesize delegate;

+ (UINavigationController *)controllerWithText:(NSString *_Nullable)text delegate:(id <ZBSourceVerificationDelegate>)delegate {
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
    self.addRepoTextView.backgroundColor = [UIColor cellBackgroundColor];
    self.addRepoTextView.textColor = [UIColor primaryTextColor];
    self.addRepoTextView.delegate = self;
    
    if (self.text && [self.text hasPrefix:@"http"]) {
        self.addRepoTextView.text = self.text;
        self.addButton.enabled = self.addRepoTextView.text.length;
    }
}

- (void)applyLocalization {
    self.addButton.title = NSLocalizedString(@"Add", @"");
    self.navigationItem.title = NSLocalizedString(@"Add Sources", @"");
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
    
    NSError *detectorError;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&detectorError];
    if (detectorError) {
        UIAlertController *errorPopup = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"An Error Occurred", @"") message:detectorError.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        
        [errorPopup addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"") style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:errorPopup animated:true completion:nil];
    }
    else {
        NSMutableArray <NSURL *> *detectedURLs = [NSMutableArray new];
        
        NSString *sourcesString = self.addRepoTextView.text;
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
    
    return true;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.addButton.enabled = self.addRepoTextView.text.length != 0;
}

@end
