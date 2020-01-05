//
//  ZBSourceImportTableViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/5/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSourceImportTableViewController.h"

@interface ZBSourceImportTableViewController ()

@end

@implementation ZBSourceImportTableViewController

@synthesize sourceFilesToImport;

#pragma mark - Initializers

- (id)initWithSourceFiles:(NSArray <NSString *> *)filePaths {
    self = [super init];
    
    if (self) {
        self.sourceFilesToImport = filePaths;
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Import", @"");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sourceFilesToImport count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"repoImportCell" forIndexPath:indexPath];
    
    cell.textLabel.text = @"Whats up?";
    
    return cell;
}

#pragma mark - Processing Sources

@end
