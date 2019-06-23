//
//  CSColorObject.h
//  CSColorPicker
//
//  Created by Dana Buehre on 6/22/19.
//  Copyright © 2019 CreatureCoding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIColor.h>

NS_ASSUME_NONNULL_BEGIN

@interface CSColorObject : NSObject
@property (nonatomic, assign) BOOL isGradient;
@property (nonatomic, strong) NSString *hexValue;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) NSArray<UIColor *> *colors;

+ (instancetype)colorObjectWithHex:(NSString *)hex;
+ (instancetype)colorObjectWithColor:(UIColor *)color;
+ (instancetype)gradientObjectWithHex:(NSString *)hex;
+ (instancetype)gradientObjectWithColors:(NSArray <UIColor *> *)colors;

- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
