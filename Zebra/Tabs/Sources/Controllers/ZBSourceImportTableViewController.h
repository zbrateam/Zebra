//
//  ZBSourceImportTableViewController.h
//  Zebra
//
//  Created by Wilson Styres on 1/5/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceImportTableViewController : UITableViewController
@property (nonatomic) NSArray <NSString *> *sourceFilesToImport;
- (id)initWithSourceFiles:(NSArray <NSString *> *)filePaths;
@end

NS_ASSUME_NONNULL_END
