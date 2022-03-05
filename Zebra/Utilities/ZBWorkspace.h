//
//  ZBWorkspace.h
//  Zebra
//
//  Created by Adam Demasi on 5/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Workspace)
@interface ZBWorkspace : NSObject

+ (nullable NSString *)appNameForOpeningURL:(NSURL *)url NS_SWIFT_NAME(appNameForOpening(url:));

#if !TARGET_OS_MACCATALYST
+ (BOOL)isSafariDefaultBrowser;
#endif

@end

NS_ASSUME_NONNULL_END
