//
//  ZBJSONProperty.h
//  Zebra
//
//  Created by Adam Demasi on 31/10/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZBJSONDecodable <NSObject>
+ (nullable instancetype)fromJSONDictionary:(NSDictionary *)dict;
@end

typedef NS_ENUM(NSUInteger, ZBJSONPropertyKind) {
    ZBJSONPropertyKindAny,
    ZBJSONPropertyKindObject,
    ZBJSONPropertyKindString,
    ZBJSONPropertyKindNumber,
    ZBJSONPropertyKindArray
};

@interface ZBJSONProperty : NSObject

@property (nonatomic, copy, readonly) NSString *propertyName;
@property (nonatomic, readonly) ZBJSONPropertyKind kind;
@property (nonatomic, readonly, nullable) Class objectClass;

+ (instancetype)propertyNamed:(NSString *)propertyName kind:(ZBJSONPropertyKind)kind objectClass:(nullable Class)objectClass;

- (nullable id)valueFromJSONValue:(id)value;

@end

#define ZBJSONAny(name)          [ZBJSONProperty propertyNamed:name kind:ZBJSONPropertyKindAny objectClass:Nil]
#define ZBJSONObject(name, cls)  [ZBJSONProperty propertyNamed:name kind:ZBJSONPropertyKindObject objectClass:cls]
#define ZBJSONString(name)       [ZBJSONProperty propertyNamed:name kind:ZBJSONPropertyKindString objectClass:Nil]
#define ZBJSONNumber(name)       [ZBJSONProperty propertyNamed:name kind:ZBJSONPropertyKindNumber objectClass:Nil]
#define ZBJSONArray(name)        [ZBJSONProperty propertyNamed:name kind:ZBJSONPropertyKindArray objectClass:Nil]
#define ZBJSONArrayOf(name, cls) [ZBJSONProperty propertyNamed:name kind:ZBJSONPropertyKindArray objectClass:cls]

NS_INLINE NSArray <NSString *> *ZBJSONPropertyNames(NSDictionary <NSString *, ZBJSONProperty *> *properties) {
    NSMutableArray <NSString *> *names = [NSMutableArray arrayWithCapacity:properties.count];
    for (ZBJSONProperty *property in properties.allValues) {
        [names addObject:property.propertyName];
    }
    return names;
}

NS_ASSUME_NONNULL_END
