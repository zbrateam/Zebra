//
//  ZBPlainsController.mm
//  Zebra
//
//  Created by Adam Demasi on 9/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#import "ZBPlainsController.h"
#import "Zebra-Swift.h"
#import <Plains/Plains.h>

@implementation ZBPlainsController

+ (NSURL *)cacheURL {
	return [[[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil] URLByAppendingPathComponent:[NSBundle mainBundle].bundleIdentifier isDirectory:YES];
}

+ (NSURL *)dataURL {
	return [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil] URLByAppendingPathComponent:[NSBundle mainBundle].bundleIdentifier isDirectory:YES];
}

+ (void)setUp {
	PLConfig *config = [PLConfig sharedInstance];

	int filedes[2];
	if (pipe(filedes) == -1) {
		NSLog(@"[Zebra] Unable to create file descriptors.");
	} else {
		[config setInteger:filedes[0] forKey:@"Plains::FinishFD::"];
		[config setInteger:filedes[1] forKey:@"Plains::FinishFD::"];
	}

	// Create directories
	NSString *slingshotPath = [ZBSlingshotController superslingPath];
	NSString *cacheDir = self.cacheURL.path;
#if TARGET_OS_SIMULATOR
	NSUInteger libraryIndex1 = [cacheDir rangeOfString:@"/Library/Developer"].location;
	NSUInteger libraryIndex2 = [cacheDir rangeOfString:@"/Library/Caches"].location;
	cacheDir = [cacheDir stringByReplacingCharactersInRange:NSMakeRange(libraryIndex1, libraryIndex2 - libraryIndex1) withString:@""];
#endif
	NSString *logDir = [NSString stringWithFormat:@"%@/logs", cacheDir];
	NSString *listDir = [NSString stringWithFormat:@"%@/lists", cacheDir];
	NSString *archiveDir = [NSString stringWithFormat:@"%@/archives/partial", cacheDir];
	[[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:NO attributes:nil error:nil];
	[[NSFileManager defaultManager] createDirectoryAtPath:logDir withIntermediateDirectories:NO attributes:nil error:nil];
	[[NSFileManager defaultManager] createDirectoryAtPath:listDir withIntermediateDirectories:NO attributes:nil error:nil];
	[[NSFileManager defaultManager] createDirectoryAtPath:archiveDir withIntermediateDirectories:YES attributes:nil error:nil];

	// Shared Options
	[config setBoolean:YES forKey:@"Acquire::AllowInsecureRepositories"];
	[config setString:logDir forKey:@"Dir::Log"];
	[config setString:listDir forKey:@"Dir::State::Lists"];
	[config setString:cacheDir forKey:@"Dir::Cache"];
	[config setString:[cacheDir stringByAppendingPathComponent:@"zebra.sources"] forKey:@"Plains::SourcesList"];
	[config setString:slingshotPath forKey:@"Dir::Bin::dpkg"];
	[config setString:slingshotPath forKey:@"Plains::Slingshot"];
	[config setString:[ZBURLController aptUserAgent] forKey:@"Acquire::http::User-Agent"];

	NSString *extendedStatesPath = [@"/" stringByAppendingString:[[config stringForKey:@"Dir::State"] stringByAppendingPathComponent:@"extended_states"]];
	symlink(extendedStatesPath.UTF8String, [cacheDir stringByAppendingPathComponent:@"extended_states"].UTF8String);
	[config setString:cacheDir forKey:@"Dir::State"];

	// Reset the default compression type ordering
	[config setString:@"zstd" forKey:@"Acquire::CompressionTypes::zst"];
	[config setString:@"xz" forKey:@"Acquire::CompressionTypes::xz"];
	[config setString:@"lzma" forKey:@"Acquire::CompressionTypes::lzma"];
	[config setString:@"lz4" forKey:@"Acquire::CompressionTypes::lz4"];
	[config setString:@"gzip" forKey:@"Acquire::CompressionTypes::gz"];
	[config setString:@"bzip2" forKey:@"Acquire::CompressionTypes::bz2"];
#if DEBUG
//    _config->Set("Debug::pkgProblemResolver", true);
//    _config->Set("Debug::pkgAcquire", true);
//    _config->Set("Debug::pkgAcquire::Worker", true);
#endif
}

@end
