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
- (void)startedSourceRefresh:(ZBBaseSource *)source;
- (void)progressUpdateForSource:(ZBBaseSource *)source progress:(CGFloat)progress;
- (void)finishedSourceRefresh:(ZBBaseSource *)source warnings:(NSArray *)warnings errors:(NSArray *)errors;
@end

#endif /* ZBSourceDelegate_h */
