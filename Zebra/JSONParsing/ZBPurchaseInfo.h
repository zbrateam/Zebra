// To parse this JSON:
//
//   NSError *error;
//   ZBPurchaseInfo *purchaseInfo = [ZBPurchaseInfo fromJSON:json encoding:NSUTF8Encoding error:&error];

#import <Foundation/Foundation.h>

@class ZBPurchaseInfo;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Object interfaces

@interface ZBPurchaseInfo : NSObject
@property (nonatomic, nullable, copy)   NSString *price;
@property (nonatomic, nullable, strong) NSNumber *purchased;
@property (nonatomic, nullable, strong) NSNumber *available;
@property (nonatomic, nullable, copy)   NSString *error;
@property (nonatomic, nullable, copy)   NSString *recoveryURL;

+ (_Nullable instancetype)fromJSON:(NSString *)json encoding:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
+ (_Nullable instancetype)fromData:(NSData *)data error:(NSError *_Nullable *)error;
- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
- (NSData *_Nullable)toData:(NSError *_Nullable *)error;
@end

NS_ASSUME_NONNULL_END
