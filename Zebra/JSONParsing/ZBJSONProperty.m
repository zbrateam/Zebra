//
//  ZBJSONProperty.m
//  Zebra
//
//  Created by Adam Demasi on 31/10/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import "ZBJSONProperty.h"

@implementation ZBJSONProperty

+ (instancetype)propertyNamed:(NSString *)propertyName kind:(ZBJSONPropertyKind)kind objectClass:(Class)objectClass {
    ZBJSONProperty *property = [[self alloc] init];
    if (property) {
        property->_propertyName = [propertyName copy];
        property->_kind = kind;
        property->_objectClass = objectClass;
    }
    return property;
}

- (id)valueFromJSONValue:(id)value {
    if (value == nil || [value isEqual:[NSNull null]]) {
        return nil;
    }

    switch (_kind) {
    case ZBJSONPropertyKindAny:
        return value;

    case ZBJSONPropertyKindObject:
        if (![value isKindOfClass:[NSDictionary class]] || ![_objectClass respondsToSelector:@selector(fromJSONDictionary:)]) {
            return nil;
        }

        return [(Class<ZBJSONDecodable>)_objectClass fromJSONDictionary:value];

    case ZBJSONPropertyKindString:
        if ([value isKindOfClass:[NSString class]]) {
            return value;
        } else if ([value isKindOfClass:[NSNumber class]]) {
            return [value stringValue];
        }

        return nil;

    case ZBJSONPropertyKindNumber:
        if ([value isKindOfClass:[NSNumber class]]) {
            return value;
        } else if ([value isKindOfClass:[NSString class]]) {
            NSScanner *scanner = [NSScanner scannerWithString:value];
            double result = 0;
            if ([scanner scanDouble:&result] && scanner.isAtEnd) {
                return @(result);
            }
        }

        return nil;

    case ZBJSONPropertyKindArray: {
        if (![value isKindOfClass:[NSArray class]]) {
            return nil;
        }

        if (_objectClass == Nil) {
            return value;
        }
        
        NSMutableArray *elements = [NSMutableArray arrayWithCapacity:((NSArray *)value).count];
        if (![_objectClass respondsToSelector:@selector(fromJSONDictionary:)]) {
            for (id element in value) {
                if ([element isKindOfClass:_objectClass]) {
                    [elements addObject:element];
                }
            }

            return elements;
        }

        for (id element in value) {
            if (![element isKindOfClass:[NSDictionary class]]) {
                continue;
            }

            id decoded = [(Class<ZBJSONDecodable>)_objectClass fromJSONDictionary:element];
            if (decoded) {
                [elements addObject:decoded];
            }
        }
        
        return elements;
    }
    }

    return nil;
}

@end

id _ZBJSONDecode(ZBJSONProperty *property, NSData *data, NSError **error) {
    if (data == nil) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSCoderReadCorruptError userInfo:nil];
        }
        return nil;
    }

    NSError *jsonError = nil;
    id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
    id result = json ? [property valueFromJSONValue:json] : nil;
    if (result == nil && error) {
        *error = jsonError ?: [NSError errorWithDomain:NSCocoaErrorDomain code:NSCoderReadCorruptError userInfo:nil];
    }
    return result;
}
