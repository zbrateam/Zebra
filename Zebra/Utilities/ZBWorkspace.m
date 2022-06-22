//
//  ZBWorkspace.m
//  Zebra
//
//  Created by Adam Demasi on 5/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import "ZBWorkspace.h"
@import CoreServices;

#if TARGET_OS_MACCATALYST
@interface NSWorkspace : NSObject
+ (instancetype)sharedWorkspace;
- (NSURL *)URLForApplicationToOpenURL:(NSURL *)url;
@end
#else
@interface LSApplicationProxy : NSObject
@property (nonatomic, strong, readonly) NSString *bundleIdentifier;
@property (nonatomic, strong, readonly) NSString *localizedName;
@end

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (NSArray <LSApplicationProxy *> *)applicationsAvailableForOpeningURL:(NSURL *)url;
@end
#endif

@implementation ZBWorkspace

+ (nullable NSString *)appNameForOpeningURL:(NSURL *)url {
#if TARGET_OS_MACCATALYST
	NSURL *appURL = [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:url];
	if (!appURL) {
		return nil;
	}
	NSString *name = [[NSFileManager defaultManager] displayNameAtPath:appURL.path];
	if ([name.pathExtension isEqualToString:@"app"]) {
		name = name.stringByDeletingPathExtension;
	}
	return name;
#else
	LSApplicationProxy *app = [[LSApplicationWorkspace defaultWorkspace] applicationsAvailableForOpeningURL:url].firstObject;
	return app.localizedName;
#endif
}

#if !TARGET_OS_MACCATALYST
+ (BOOL)isSafariDefaultBrowser {
	NSURL *url = [NSURL URLWithString:@"https://"];
	LSApplicationProxy *app = [[LSApplicationWorkspace defaultWorkspace] applicationsAvailableForOpeningURL:url].firstObject;
	// If we don’t have the right entitlement, we’ll get nil back. Just assume Safari is the default
	// browser in that case.
	return app == nil || [app.bundleIdentifier isEqualToString:@"com.apple.mobilesafari"];
}
#endif

@end
