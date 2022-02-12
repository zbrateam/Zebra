//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#define SWIFT

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "Headers/MobileGestalt.h"

#import "ZBSettings.h"
#import "Model/ZBDummySource.h"

#import <Plains/Model/PLSource.h>
// #import <Plains/Model/PLPackage.h>
#import "ZBPlainsController.h"

#import "ZBHomeViewController.h"
#import "ZBSourceListViewController.h"
#import "ZBPackageListViewController.h"
#import "ZBSettingsViewController.h"

@interface UIApplication ()
- (void)suspend;
@end

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
