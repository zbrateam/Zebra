//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

@import Foundation;

#import <WebKit/WebKit.h>

#import "Model/ZBDummySource.h"
#import <Extensions/ZBColor.h>
#import <ZBDevice.h>

#import <Plains/Model/PLSource.h>
// #import <Plains/Model/PLPackage.h>

@interface WKWebView (Private)
@property (setter=_setApplicationNameForUserAgent:,copy) NSString * _applicationNameForUserAgent;
@end

@interface PLPackage : NSObject
- (NSURL *_Nullable)depictionURL;
- (NSURL *_Nullable)nativeDepictionURL;
- (NSString *_Nullable)longDescription;
@end
