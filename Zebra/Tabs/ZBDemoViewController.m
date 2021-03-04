//
//  ZBDemoViewController.m
//  Zebra
//
//  Created by Wilson Styres on 2/28/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBDemoViewController.h"

@import Plains;

@interface ZBDemoViewController () {
    PLDatabase *database;
}
@property (strong, nonatomic) IBOutlet UITextView *outputView;
@end

@implementation ZBDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Plains";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];
    
    database = [[PLDatabase alloc] init];
    
    [self appendString:@"==== SOURCES ===="];
    NSArray <PLSource *> *sources = [database sources];
    for (PLSource *source in sources) {
        [self appendString:[NSString stringWithFormat:@"URI: %@", source.URI.absoluteString]];
        [self appendString:[NSString stringWithFormat:@"Distribution: %@", source.distribution]];
        [self appendString:[NSString stringWithFormat:@"Origin: %@", source.origin]];
        [self appendString:[NSString stringWithFormat:@"Label: %@", source.label]];
        [self appendString:@""];
    }
}

- (void)appendString:(NSString *)string {
    [self.outputView insertText:[string stringByAppendingString:@"\n"]];
}

- (void)refresh {
    NSLog(@"[Plains] Updating Database...");
    [database updateDatabase];
    self.outputView.text = @"";
    [self appendString:@"==== SOURCES ===="];
    NSArray <PLSource *> *sources = [database sources];
    NSLog(@"[Plains] Sources: %@", sources);
    for (PLSource *source in sources) {
        [self appendString:[NSString stringWithFormat:@"URI: %@", source.URI.absoluteString]];
        [self appendString:[NSString stringWithFormat:@"Origin: %@", source.origin]];
        [self appendString:[NSString stringWithFormat:@"Label: %@", source.label]];
        [self appendString:[NSString stringWithFormat:@"Type: %@", source.type]];
        [self appendString:[NSString stringWithFormat:@"Distribution: %@", source.distribution]];
        [self appendString:[NSString stringWithFormat:@"Codename: %@", source.codename]];
        [self appendString:[NSString stringWithFormat:@"Suite: %@", source.suite]];
        [self appendString:[NSString stringWithFormat:@"Release Notes: %@", source.releaseNotes]];
        [self appendString:[NSString stringWithFormat:@"Trusted: %@", source.trusted ? @"Yes" : @"No"]];
        [self appendString:@""];
    }
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
