#import <Foundation/Foundation.h>
#import "DeviceInfo.h"

#import <stdlib.h>
#import <stdio.h>

#import <spawn.h>

@interface Firmware : NSObject

- (void)exitWithError:(NSError *)error andMessage:(NSString *)message;
- (void)loadInstalledPackages;
- (void)generatePackage:(NSString *)package forVersion:(NSString *)version withDescription:(NSString *)description;
- (void)generatePackage:(NSString *)package forVersion:(NSString *)version withDescription:(NSString *)description andName:(NSString *)name;
- (void)generateCapabilityPackages;
- (void)writePackagesToStatusFile;
- (void)setupUserSymbolicLink;

@end
