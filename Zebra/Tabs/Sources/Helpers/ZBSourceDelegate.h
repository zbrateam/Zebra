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

#ifndef ZBSourceDelegate_h
#define ZBSourceDelegate_h

@protocol ZBSourceDelegate
- (void)startedRefreshForSource:(ZBBaseSource *)source;
- (void)finishedRefreshForSource:(ZBBaseSource *)source warnings:(NSArray *)warnings errors:(NSArray *)errors;

- (void)addedSources:(NSSet <ZBBaseSource *> *)sources;
- (void)removedSources:(NSSet <ZBBaseSource *> *)sources;
@optional
- (void)progressUpdate:(CGFloat)progress forSource:(ZBBaseSource *)source;
@end

#endif /* ZBSourceDelegate_h */
