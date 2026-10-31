//
//  NSObject+Zebra.m
//  Zebra
//
//  Created by Adam Demasi on 25/11/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "NSObject+Zebra.h"

@implementation NSObject (Zebra)

- (void)zbra_setValues:(NSDictionary <NSString *, id> *)values forProperties:(NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    if (![values isKindOfClass:[NSDictionary class]]) {
        return;
    }

    for (NSString *key in properties.allKeys) {
        ZBJSONProperty *property = properties[key];
        id value = [property valueFromJSONValue:values[key]];
        if (value == nil) {
            continue;
        }

        [self setValue:value forKey:property.propertyName];
    }
}

@end
