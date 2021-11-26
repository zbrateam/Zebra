//
//  NSObject+Zebra.m
//  Zebra
//
//  Created by Adam Demasi on 25/11/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "NSObject+Zebra.h"

@implementation NSObject (Zebra)

- (void)zbra_setValues:(NSDictionary <NSString *, id> *)values forProperties:(NSDictionary <NSString *, NSString *> *)properties {
    if (values == nil || [values isEqual:[NSNull null]]) {
        return;
    }
    for (NSString *key in properties.allKeys) {
        id value = [values[key] isEqual:[NSNull null]] ? nil : values[key];
        [self setValue:value forKey:properties[key]];
    }
}

@end

