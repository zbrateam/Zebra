//
//  ZBSourceDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 8/23/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@class ZBBaseSource;

@import Foundation;
@import CoreGraphics;

NS_ASSUME_NONNULL_BEGIN

#ifndef ZBSourceDelegate_h
#define ZBSourceDelegate_h

@protocol ZBSourceDelegate
@optional
- (void)startedSourceRefresh;
- (void)startedDownloadForSource:(ZBBaseSource *)source;
- (void)finishedDownloadForSource:(ZBBaseSource *)source warnings:(NSArray <NSError *> *_Nullable)warnings errors:(NSArray <NSError *> *_Nullable)errors;
- (void)startedImportForSource:(ZBBaseSource *)source;
- (void)finishedImportForSource:(ZBBaseSource *)source errors:(NSArray <NSError *> *_Nullable)errors;
- (void)finishedSourceRefresh;
- (void)addedSources:(NSSet <ZBBaseSource *> *)sources;
- (void)removedSources:(NSSet <ZBBaseSource *> *)sources;
- (void)progressUpdate:(CGFloat)progress forSource:(ZBBaseSource *)source;
@end

#endif /* ZBSourceDelegate_h */

NS_ASSUME_NONNULL_END
