//
//  ZBPaymentVendorError.h
//  Zebra
//
//  Created by Adam Demasi on 3/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBJSONObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBPaymentVendorError : ZBJSONObject
@property (nonatomic, copy)   NSString *error;
@property (nonatomic, copy)   NSString *recoveryURL;
@property (nonatomic)         BOOL invalidate;

- (NSString *_Nullable)toJSON:(NSStringEncoding)encoding error:(NSError *_Nullable *)error;
- (NSData *_Nullable)toData:(NSError *_Nullable *)error;
@end

NS_ASSUME_NONNULL_END
