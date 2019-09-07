//
//  ZBDownloadManager.h
//  Zebra
//
//  Created by Wilson Styres on 4/14/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBQueue;
@class ZBSource;

#import <Foundation/Foundation.h>
#import "ZBDownloadDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBDownloadManager : NSObject <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>
@property (nonatomic, strong) NSArray *repos;
@property (nonatomic, strong) ZBQueue *queue;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, weak) id <ZBDownloadDelegate> downloadDelegate;
@property (nonatomic, strong) NSDictionary <NSString *, NSMutableArray *> *filenames;
- (id)initWithDownloadDelegate:(id <ZBDownloadDelegate>)delegate sourceListPath:(NSString *)trail;
- (id)initWithDownloadDelegate:(id <ZBDownloadDelegate>)delegate repo:(ZBSource *)repo;
- (id)initWithDownloadDelegate:(id <ZBDownloadDelegate>)delegate repoURLs:(NSArray <NSURL *> *)repoURLs;
- (id)initWithSourceListPath:(NSString *)trail;
- (void)downloadRepos:(NSArray <ZBSource *> *)repos ignoreCaching:(BOOL)ignore;
- (void)downloadRepo:(ZBSource *)repo;
- (void)downloadReposAndIgnoreCaching:(BOOL)ignore;
- (void)downloadPackages:(NSArray <ZBPackage *> *)packages;
- (void)stopAllDownloads;
@end

NS_ASSUME_NONNULL_END
