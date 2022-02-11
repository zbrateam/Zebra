//
//  ZBPlainsController.h
//  Zebra
//
//  Created by Adam Demasi on 9/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBPlainsController : NSObject

@property (class, nonatomic, strong, readonly) NSURL *cacheURL;
@property (class, nonatomic, strong, readonly) NSURL *dataURL;

+ (void)setUp;

@end

NS_ASSUME_NONNULL_END
