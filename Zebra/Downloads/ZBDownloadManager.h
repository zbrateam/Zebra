//
//  ZBDownloadManager.h
//  Zebra
//
//  Created by Wilson Styres on 4/14/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBQueue;
@class ZBSource;

@import Foundation;

#import "ZBDownloadDelegate.h"
#import <Tabs/Sources/Helpers/ZBBaseSource.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBDownloadManager : NSObject <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, weak) id <ZBDownloadDelegate> downloadDelegate;
- (id)initWithDownloadDelegate:(id <ZBDownloadDelegate>)delegate;
- (void)downloadSources:(NSSet <ZBBaseSource *> *)sources useCaching:(BOOL)useCaching;
- (void)downloadPackages:(NSArray <ZBPackage *> *)packages;
- (void)stopAllDownloads;
@end

NS_ASSUME_NONNULL_END
