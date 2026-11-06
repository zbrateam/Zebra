//
//  ZBCredits.h
//  Zebra
//
//  Created by Adam Demasi on 2/11/2026.
//  Copyright © 2026 Zebra Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBJSONObject.h"

@class ZBCreditsSection, ZBCreditsItem;

NS_ASSUME_NONNULL_BEGIN

@interface ZBCredits : ZBJSONObject

@property (nonatomic, copy) NSArray <ZBCreditsSection *> *sections;

@end

@interface ZBCreditsSection : ZBJSONObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray <ZBCreditsItem *> *items;

@end

@interface ZBCreditsItem : ZBJSONObject

@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy, nullable) NSString *subtitle;
@property (nonatomic, copy, nullable) NSString *link;

@end

NS_ASSUME_NONNULL_END
