//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

@import Foundation;
@import WebKit;

#import "MobileGestalt.h"

#import "ZBDummySource.h"
#import "ZBSourceAddViewController.h"
#import "ZBWorkspace.h"
#import "ZBPackageActions.h"

@interface UIApplication ()
- (void)suspend;
@end

@interface WKWebView (Private)
@property (setter=_setApplicationNameForUserAgent:, copy, nullable) NSString * _applicationNameForUserAgent;
@end

static inline pid_t forkplz(void) {
	return fork();
}
