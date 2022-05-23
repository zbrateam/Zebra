//
//  NSURLSession+Zebra.h
//  Zebra
//
//  Created by Adam Demasi on 21/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLSession (Zebra)

+ (instancetype)zbra_standardSession;
+ (instancetype)zbra_downloadSession;

@end

NS_ASSUME_NONNULL_END
