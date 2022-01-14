//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#define SWIFT

#import <Foundation/Foundation.h>

#import <WebKit/WebKit.h>

#import "ZBSettings.h"
#import "Model/ZBDummySource.h"
#import <ZBDevice.h>

#import <Plains/Model/PLSource.h>
// #import <Plains/Model/PLPackage.h>

@interface WKWebView (Private)
@property (setter=_setApplicationNameForUserAgent:, copy, nullable) NSString * _applicationNameForUserAgent;
@end

#ifndef PLPACKAGE_H
@interface PLPackage : NSObject
- (NSURL *_Nullable)depictionURL;
- (NSURL *_Nullable)nativeDepictionURL;
- (NSString *_Nullable)longDescription;
@end
#endif
