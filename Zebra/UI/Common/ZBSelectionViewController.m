//
//  ZBSelectionViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/17/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSelectionViewController.h"

@interface ZBSelectionViewController () {
    id <ZBSelectionDelegate> delegate;
}
@property ZBSelectionType selectionType;
@property NSArray *choices;
@property NSMutableArray *selections;
@end

@implementation ZBSelectionViewController

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"selectionCell"];
    }
    
    return self;
}

- (instancetype)initWithChoices:(NSArray *)choices selections:(NSArray *)selections selectionType:(ZBSelectionType)selectionType delegate:(id<ZBSelectionDelegate>)delegate {
    self = [self init];
    
    if (self) {
        self->delegate = delegate;
        self.choices = choices;
        self.selections = selections ? [selections mutableCopy] : [NSMutableArray new];
        
        if (selectionType == ZBSelectionTypeInverse) {
            self.allowsMultiSelection = YES;
        }
    }
    
    return self;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.choices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"selectionCell" forIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSObject *choice = self.choices[indexPath.row];
    cell.textLabel.text = (NSString *)choice;
    
    if ([self.selections containsObject:choice]) {
        cell.accessoryType = self.selectionType == ZBSelectionTypeInverse ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = self.selectionType == ZBSelectionTypeInverse ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSObject *choice = self.choices[indexPath.row];
    if ([self.selections containsObject:choice]) {
        [self.selections removeObject:choice];
        
    } else {
        if (self.allowsMultiSelection) {
            [self.selections addObject:choice];
        } else {
            NSObject *previousChoice = self.selections.firstObject;
            
            if (previousChoice) {
                NSUInteger previousChoiceIndex = [self.choices indexOfObject:previousChoice];
                [self.selections removeObjectAtIndex:0];
                [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:previousChoiceIndex inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            }
                
            [self.selections addObject:choice];
        }
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end