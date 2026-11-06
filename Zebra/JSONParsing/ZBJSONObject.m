//
//  ZBJSONObject.m
//  Zebra
//
//  Created by Adam Demasi on 6/11/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import "ZBJSONObject.h"
#import "NSObject+Zebra.h"

@implementation ZBJSONObject

+ (NSDictionary <NSString *, ZBJSONProperty *> *)properties {
    NSAssert(NO, @"+properties not set");
    return @{};
}

+ (instancetype)fromData:(NSData *)data error:(NSError **)error {
    return ZBJSONDecodeObject(self, data, error);
}

+ (NSArray *)arrayFromData:(NSData *)data error:(NSError **)error {
    return ZBJSONDecodeArray(self, data, error);
}

+ (instancetype)fromJSONDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    ZBJSONObject *object = [[self alloc] initWithJSONDictionary:dict];
    return object.isValid ? object : nil;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        [self zbra_setValues:dict forProperties:self.class.properties];
    }
    return self;
}

- (BOOL)isValid {
    return YES;
}

@end
