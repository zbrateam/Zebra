// ZBSourceInfo.h

// To parse this JSON:
//
//   NSError *error = NULL;
//   ZBSourceInfo *sourceInfo = [ZBSourceInfo fromData:data error:&error];

#import <Foundation/Foundation.h>
#import "ZBJSONObject.h"

@class ZBSourceInfo;
@class ZBAuthenticationBanner;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Object interfaces

@interface ZBSourceInfo : ZBJSONObject
@property (nonatomic, copy)   NSString *name;
@property (nonatomic, copy)   NSString *icon;
@property (nonatomic, copy)   NSString *theDescription;
@property (nonatomic, strong) ZBAuthenticationBanner *authenticationBanner;

- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
- (NSData *_Nullable)toData:(NSError *_Nullable *)error;
@end

@interface ZBAuthenticationBanner : ZBJSONObject
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *button;
@end

NS_ASSUME_NONNULL_END
