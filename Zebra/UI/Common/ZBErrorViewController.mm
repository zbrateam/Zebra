//
//  ZBErrorViewController.m
//  Zebra
//
//  Created by Wilson Styres on 5/4/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBErrorViewController.h"

#import <Plains/Plains.h>

@interface ZBErrorViewController () {
    NSArray *messages;
}
@end

@implementation ZBErrorViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        self.title = @"Error Log";
        self->messages = [[PLConfig sharedInstance] errorMessages];
    }
    
    return self;
}

- (instancetype)initWithSource:(PLSource *)source {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        self.title = source.origin;
        self->messages = source.messages;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"errorCell"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"errorCell" forIndexPath:indexPath];
    
    cell.textLabel.text = self->messages[indexPath.row];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1 compatibleWithTraitCollection:self.traitCollection];
    cell.textLabel.numberOfLines = 0;
    
    return cell;
}

@end
