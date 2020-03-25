// ZBSourceInfo.h

// To parse this JSON:
//
//   NSError *error;
//   ZBSourceInfo *sourceInfo = [ZBSourceInfo fromJSON:json encoding:NSUTF8Encoding error:&error];

#import <Foundation/Foundation.h>

@class ZBSourceInfo;
@class ZBAuthenticationBanner;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Object interfaces

@interface ZBSourceInfo : NSObject
@property (nonatomic, copy)   NSString *name;
@property (nonatomic, copy)   NSString *icon;
@property (nonatomic, copy)   NSString *theDescription;
@property (nonatomic, strong) ZBAuthenticationBanner *authenticationBanner;

+ (_Nullable instancetype)fromJSON:(NSString *)json encoding:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
+ (_Nullable instancetype)fromData:(NSData *)data error:(NSError *_Nullable *)error;
- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
- (NSData *_Nullable)toData:(NSError *_Nullable *)error;
@end

@interface ZBAuthenticationBanner : NSObject
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *button;
@end

NS_ASSUME_NONNULL_END
