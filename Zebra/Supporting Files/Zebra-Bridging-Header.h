//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#define SWIFT

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "Headers/MobileGestalt.h"

#import <Plains/Plains.h>

#import "ZBSettings.h"
#import "Model/ZBDummySource.h"

#import "ZBHomeViewController.h"
#import "ZBSourceListViewController.h"
#import "ZBPackageListViewController.h"
#import "ZBPackageViewController.h"
#import "ZBSettingsViewController.h"
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
