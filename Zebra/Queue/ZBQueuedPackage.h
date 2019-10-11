//
//  ZBQueuedPackage.h
//  Zebra
//
//  Created by Wilson Styres on 10/10/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackage.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBQueuedPackage : NSObject
@property (nonatomic, strong) ZBPackage *package;
@property (nonatomic, strong) NSArray <ZBQueuedPackage *> *dependencies;
- (id)initWithPackage:(ZBPackage *)package;
- (NSString *)key;
- (void)addDependency:(id)package;
@end

NS_ASSUME_NONNULL_END
