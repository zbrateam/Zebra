// To parse this JSON:
//
//   NSError *error;
//   ZBUserInfo *userInfo = [ZBUserInfo fromJSON:json encoding:NSUTF8Encoding error:&error];
// OR
//   NSError *error;
//   ZBUserInfo *userInfo = [ZBUserInfo fromData:data error:&error];

#import <Foundation/Foundation.h>

@class ZBUserInfo;
@class ZBUser;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Object interfaces

@interface ZBUserInfo : NSObject
@property (nonatomic, nullable, copy)   NSArray<NSString *> *items;
@property (nonatomic, nullable, strong) ZBUser *user;

+ (_Nullable instancetype)fromJSON:(NSString *)json encoding:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
+ (_Nullable instancetype)fromData:(NSData *)data error:(NSError *_Nullable *)error;
- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
- (NSData *_Nullable)toData:(NSError *_Nullable *)error;
@end

@interface ZBUser : NSObject
@property (nonatomic, nullable, copy) NSString *name;
@property (nonatomic, nullable, copy) NSString *email;
@end

NS_ASSUME_NONNULL_END
