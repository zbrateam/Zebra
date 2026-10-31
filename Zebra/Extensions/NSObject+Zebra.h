//
//  NSObject+Zebra.h
//  Zebra
//
//  Created by Adam Demasi on 25/11/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBJSONProperty.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Zebra)

- (void)zbra_setValues:(NSDictionary <NSString *, id> *)values forProperties:(NSDictionary <NSString *, ZBJSONProperty *> *)properties;

@end

NS_ASSUME_NONNULL_END
