//
//  ZBDownloadDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 4/14/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Console/ZBLogLevel.h>

@class ZBDownloadManager;
@class ZBPackage;

NS_ASSUME_NONNULL_BEGIN

@protocol ZBDownloadDelegate
- (void)predator:(ZBDownloadManager *)downloadManager startedDownloadForFile:(NSString *)filename;
- (void)predator:(ZBDownloadManager *)downloadManager finishedDownloadForFile:(NSString *)filename withError:(NSError *_Nullable)error;
- (void)predator:(ZBDownloadManager *)downloadManager finishedAllDownloads:(NSDictionary *)filenames;
@optional
- (void)predator:(ZBDownloadManager *)downloadManager progressUpdate:(CGFloat)progress forPackage:(ZBPackage *)package;
- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level;
@end

NS_ASSUME_NONNULL_END
