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

- (void)startedSourceDownload:(ZBBaseSource *)baseSource;
- (void)progressUpdate:(CGFloat)progress forSource:(ZBBaseSource *)baseSource;
- (void)finishedSourceDownload:(ZBBaseSource *)baseSource withErrors:(NSArray <NSError *> *_Nullable)errors;

- (void)startedPackageDownload:(ZBPackage *)package;
- (void)progressUpdate:(CGFloat)progress forPackage:(ZBPackage *)package;
- (void)finishedPackageDownload:(ZBPackage *)package withError:(NSError *_Nullable)error;

- (void)startedDownloadForFile:(NSString *)filename __deprecated_msg("Use a specific download started method instead");
- (void)finishedAllDownloads:(NSDictionary *)filenames __deprecated_msg("Use a specific download finished method instead");
- (void)finishedDownloadForFile:(NSString *_Nullable)filename withError:(NSError *_Nullable)error __deprecated_msg("Use a specific download finished method instead");
@end

NS_ASSUME_NONNULL_END
