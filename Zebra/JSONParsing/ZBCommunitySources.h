//
//  ZBCommunitySources.h
//  Zebra
//
//  Created by Adam Demasi on 2/11/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBJSONObject.h"

@class ZBCommunitySource;

NS_ASSUME_NONNULL_BEGIN

@interface ZBCommunitySources : ZBJSONObject

@property (nonatomic, copy) NSArray <ZBCommunitySource *> *repos;

@end

@interface ZBCommunitySource : ZBJSONObject

@property (nonatomic, copy, nullable) NSString *type;
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy, nullable) NSString *label;
@property (nonatomic, copy, nullable) NSString *url;
@property (nonatomic, copy, nullable) NSString *ext;
@property (nonatomic, copy, nullable) NSString *icon;
@property (nonatomic, copy, nullable) NSString *appVersion;

@end

NS_ASSUME_NONNULL_END
