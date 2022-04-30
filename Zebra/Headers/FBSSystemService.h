//
//  FBSSystemService.h
//  Zebra
//
//  Created by Adam Demasi on 1/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

@import Foundation;

@interface FBSSystemService : NSObject

+ (instancetype)sharedService;

- (void)openURL:(NSURL *)url application:(NSString *)application options:(id)options clientPort:(mach_port_t)port withResult:(id)result;

@end
