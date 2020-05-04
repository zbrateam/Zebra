//
//  ZBRefreshViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ZBDatabaseDelegate.h>
#import "UIColor+GlobalColors.h"
#import <Sources/Helpers/ZBSourceVerificationDelegate.h>

@class ZBBaseSource;

@interface ZBRefreshViewController : UIViewController <ZBDatabaseDelegate>
@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, retain) NSSet <ZBBaseSource *> *baseSources;
@property (nonatomic) BOOL dropTables;
@property id <ZBSourceVerificationDelegate> delegate;
- (id)init;
- (id)initWithMessages:(NSArray *)messages;
- (id)initWithDropTables:(BOOL)dropTables;
- (id)initWithBaseSources:(NSSet <ZBBaseSource *> *)baseSources delegate:(id <ZBSourceVerificationDelegate>)delegate;
- (id)initWithMessages:(NSArray *)messages dropTables:(BOOL)dropTables;
- (id)initWithMessages:(NSArray *)messages baseSources:(NSSet <ZBBaseSource *> *)baseSources;
- (id)initWithDropTables:(BOOL)dropTables baseSources:(NSSet <ZBBaseSource *> *)baseSources;
- (id)initWithMessages:(NSArray *)messages dropTables:(BOOL)dropTables baseSources:(NSSet <ZBBaseSource *> *)baseSources;
@end

