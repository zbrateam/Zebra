//
//  ZBDemoViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/28/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBDemoViewController.h"

@import Plains;

@interface ZBDemoViewController ()
@property (strong, nonatomic) IBOutlet UITextView *outputView;
@end

@implementation ZBDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Plains";
    
    PLDatabase *database = [[PLDatabase alloc] init];
    
    [self appendString:@"==== SOURCE URIS ===="];
    NSArray <NSString *> *sourceURIs = [database sources];
    for (NSString *URI in sourceURIs) {
        [self appendString:URI];
    }
}

- (void)appendString:(NSString *)string {
    [self.outputView insertText:[string stringByAppendingString:@"\n"]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
