//
//  ZBBaseSource.h
//  Zebra
//
//  Created by Wilson Styres on 1/2/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBBaseSource : NSObject
@property (nonatomic) NSString *archiveType;
@property (nonatomic) NSString *repositoryURI;
@property (nonatomic) NSString *distribution;
@property (nonatomic) NSArray <NSString *> *components;
- (id)
@end

NS_ASSUME_NONNULL_END
