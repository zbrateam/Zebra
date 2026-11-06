// To parse this JSON:
//
//   NSError *error = NULL;
//   ZBPurchaseInfo *purchaseInfo = [ZBPurchaseInfo fromData:data error:&error];

#import <Foundation/Foundation.h>
#import "ZBJSONObject.h"

@class ZBPurchaseInfo;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Object interfaces

@interface ZBPurchaseInfo : ZBJSONObject
@property (nonatomic, nullable, copy)   NSString *price;
@property BOOL purchased;
@property BOOL available;
@property (nonatomic, nullable, copy)   NSString *error;
@property (nonatomic, nullable, copy)   NSString *recoveryURL;

- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
- (NSData *_Nullable)toData:(NSError *_Nullable *)error;
@end

NS_ASSUME_NONNULL_END
