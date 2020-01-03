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

@property (nonatomic) NSURL *packagesDirectoryURL;
@property (nonatomic) NSURL *releaseURL;

+ (NSArray <ZBBaseSource *> *)baseSourcesFromList:(NSString *)listPath error:(NSError **)error;
- (id)initWithArchiveType:(NSString *)archiveType repositoryURI:(NSString *)repositoryURI distribution:(NSString *)distribution components:(NSArray <NSString *> *)components;
- (id)initFromSourceLine:(NSString *)debLine;
@end

NS_ASSUME_NONNULL_END
