//
//  ZBSourceImportViewController.h
//  Zebra
//
//  Created by Wilson Styres on 1/5/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Extensions/ZBTableViewController.h>

#import "ZBSourceVerificationDelegate.h"

@class ZBDummySource;

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceImportViewController : UITableViewController <ZBSourceVerificationDelegate>
@property (nonatomic) NSMutableArray <NSURL *> *sourceFilesToImport;
- (instancetype)initWithPaths:(NSArray <NSURL *> *)filePaths;
- (instancetype)initWithPaths:(NSArray <NSURL *> *)filePaths extension:(NSString *)extension;
- (instancetype)initWithSources:(NSSet <ZBDummySource *> *)sources;
@end

NS_ASSUME_NONNULL_END
