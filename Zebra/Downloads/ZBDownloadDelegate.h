//
//  ZBDownloadDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 4/14/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class ZBDownloadManager;
@class ZBPackage;
@class ZBBaseSource;

@import CoreGraphics;
@import Foundation;

#import <Console/ZBLogLevel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZBDownloadDelegate <NSObject>
- (void)startedDownloads;
- (void)finishedAllDownloads;
@optional
- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level;

- (void)startedDownloadingSource:(ZBBaseSource *)source;
- (void)progressUpdate:(CGFloat)progress forSource:(ZBBaseSource *)source;
- (void)finishedDownloadingSource:(ZBBaseSource *)source withError:(NSArray <NSError *> *_Nullable)errors;

- (void)startedPackageDownload:(ZBPackage *)package;
- (void)progressUpdate:(CGFloat)progress forPackage:(ZBPackage *)package;
- (void)finishedPackageDownload:(ZBPackage *)package withError:(NSError *_Nullable)error;
@end

NS_ASSUME_NONNULL_END
