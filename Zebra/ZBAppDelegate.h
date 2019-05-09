//
//  ZBAppDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZBAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
+ (NSString *)documentsDirectory;
+ (BOOL)needsSimulation;
+ (NSString *)listsLocation;
+ (NSURL *)sourcesListURL;
+ (NSString *)sourcesListPath;
+ (NSString *)databaseLocation;
+ (NSString *)debsLocation;
@end

