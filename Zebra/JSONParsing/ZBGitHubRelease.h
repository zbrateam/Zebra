//
//  ZBGitHubRelease.h
//  Zebra
//
//  Created by Adam Demasi on 2/11/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBJSONObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBGitHubRelease : ZBJSONObject

@property (nonatomic, copy) NSString *tagName;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *bodyHTML;
@property (nonatomic) BOOL prerelease;

@end

NS_ASSUME_NONNULL_END
