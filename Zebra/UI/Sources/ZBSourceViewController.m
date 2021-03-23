//
//  ZBSourceViewController.m
//  Zebra
//
//  Created by Wilson Styres on 3/24/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBSourceViewController.h"

#import <Plains/PLSource.h>

@interface ZBSourceViewController ()
@property PLSource *source;
@end

@implementation ZBSourceViewController

- (instancetype)initWithSource:(PLSource *)source {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        _source = source;
        
        self.title = source.origin;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _source.sections.count;
}

@end
