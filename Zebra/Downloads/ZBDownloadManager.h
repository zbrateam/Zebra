//
//  ZBDownloadManager.h
//  Zebra
//
//  Created by Wilson Styres on 4/14/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBQueue;
@class ZBRepo;

#import <Foundation/Foundation.h>
#import "ZBDownloadDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBDownloadManager : NSObject <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>
@property (nonatomic, strong) NSArray *repos;
@property (nonatomic, strong) ZBQueue *queue;
@property (nonatomic, weak) id <ZBDownloadDelegate> downloadDelegate;
@property (nonatomic, strong) NSDictionary <NSString *, NSArray *> *filenames;
- (id)initWithSourceListPath:(NSString *)trail;
- (void)downloadRepos:(NSArray <ZBRepo *> *)repos ignoreCaching:(BOOL)ignore;
- (void)downloadRepo:(ZBRepo *)repo;
- (void)downloadReposAndIgnoreCaching:(BOOL)ignore;
- (void)downloadPackages:(NSArray <ZBPackage *> *)packages;
@end

NS_ASSUME_NONNULL_END
