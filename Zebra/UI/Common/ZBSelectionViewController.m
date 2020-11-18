//
//  ZBSelectionViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/17/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBSelectionViewController.h"

#import <Extensions/UIColor+GlobalColors.h>

@interface ZBSelectionViewController () {
    id <ZBSelectionDelegate> delegate;
    NSIndexPath *indexPath;
}
@end

@implementation ZBSelectionViewController

@synthesize selections = _selections;
@synthesize selectionType = _selectionType;

#pragma mark - Initializers

- (instancetype)init {
    if (@available(iOS 13.0, *)) {
        self = [super initWithStyle:UITableViewStyleInsetGrouped];
    } else {
        self = [super initWithStyle:UITableViewStyleGrouped];
    }
    
    if (self) {
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"selectionCell"];
        self.view.tintColor = [UIColor accentColor];
    }
    
    return self;
}

- (instancetype)initWithDelegate:(id<ZBSelectionDelegate>)delegate indexPath:(NSIndexPath *)indexPath {
    self = [self init];
    
    if (self) {
        self->delegate = delegate;
        self->indexPath = indexPath;
        self.selections = [NSMutableArray new];
//        self.choices = choices;
//        self.selections = selections ? [selections mutableCopy] : [NSMutableArray new];
//
//        if (selectionType == ZBSelectionTypeInverse) {
//            self.allowsMultiSelection = YES;
//        }
    }
    
    return self;
}

#pragma mark - Properties

- (void)setSelections:(NSMutableArray *)selections {
    if (selections) {
        _selections = selections;
    } else {
        _selections = [NSMutableArray new];
    }
}

- (NSMutableArray *)selections {
    return _selections;
}

- (void)setSelectionType:(ZBSelectionType)selectionType {
    if (selectionType == ZBSelectionTypeInverse) {
        self.allowsMultiSelection = YES;
    }
    
    _selectionType = selectionType;
}

- (ZBSelectionType)selectionType {
    return _selectionType;
}

#pragma mark - View Controller Lifecycle

- (void)viewWillDisappear:(BOOL)animated {
    [delegate selectedChoices:self.selections fromIndexPath:indexPath];
    
    [super viewWillDisappear:animated];
}

#pragma mark - Table View Data Source

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
        cell.accessoryType = self.selectionType == ZBSelectionTypeNormal ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = self.selectionType == ZBSelectionTypeNormal ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.footer;
}

@end
