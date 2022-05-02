//
//  ZBSafariAuthenticationSession.h
//  Zebra
//
//  Created by Adam Demasi on 30/4/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ZBSafariAuthenticationErrorDomain;

typedef NS_ENUM(NSInteger, ZBSafariAuthenticationError) {
    ZBSafariAuthenticationErrorCanceledLogin = 1
};

typedef void (^ZBSafariAuthenticationCompletionHandler)(NSURL *_Nullable callbackURL, NSError *_Nullable error);

@interface ZBSafariAuthenticationSession : NSObject

+ (void)handleCallbackURL:(NSURL *)url;

- (instancetype)initWithURL:(NSURL *)url callbackURLScheme:(nullable NSString *)callbackURLScheme completionHandler:(ZBSafariAuthenticationCompletionHandler)completionHandler;

- (void)start;

@end

NS_ASSUME_NONNULL_END
