//
//  ZBAppSceneHelper.m
//  ZebraCatalystHelper
//
//  Created by Adam Demasi on 12/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

@import AppKit;
#import "ZBAppSceneHelper.h"

@interface MarzipanAppDelegate : NSResponder <NSApplicationDelegate>

- (nullable NSWindow *)hostWindowForSceneIdentifier:(NSString *)sceneIdentifier;

@end

@implementation ZBAppSceneHelper

+ (void)didCreateWindow:(NSNotification *)notification {
	NSString *sceneIdentifier = notification.userInfo[@"SceneIdentifier"];
	// TODO: This is broken on Monterey…
//	if ([sceneIdentifier hasSuffix:@"App"]) {
		NSWindow *window = [self getWindowForSceneIdentifier:sceneIdentifier];
		window.tabbingMode = NSWindowTabbingModeDisallowed;
//	}
}

+ (nullable NSWindow *)getWindowForSceneIdentifier:(NSString *)sceneIdentifier {
	MarzipanAppDelegate *appDelegate = (MarzipanAppDelegate *)[NSApp delegate];
	if (![appDelegate respondsToSelector:@selector(hostWindowForSceneIdentifier:)]) {
		// Better we don’t continue.
		return nil;
	}
	return [appDelegate hostWindowForSceneIdentifier:sceneIdentifier];
}

@end

__attribute__((constructor))
void setUpAppSceneHelper(void) {
	[[NSNotificationCenter defaultCenter] addObserver:[ZBAppSceneHelper class] selector:@selector(didCreateWindow:) name:@"UISBHSDidCreateWindowForSceneNotification" object:nil];
}
