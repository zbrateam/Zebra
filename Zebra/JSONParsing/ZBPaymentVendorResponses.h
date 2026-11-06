//
//  ZBPaymentVendorResponses.h
//  Zebra
//
//  Created by Adam Demasi on 2/11/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBJSONObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBPurchaseResponse : ZBJSONObject

@property (nonatomic, strong, nullable) NSNumber *status;
@property (nonatomic, copy, nullable) NSString *error;
@property (nonatomic, copy, nullable) NSString *url;

@end

@interface ZBDownloadAuthorizationResponse : ZBJSONObject

@property (nonatomic, copy, nullable) NSString *url;

@end

NS_ASSUME_NONNULL_END
