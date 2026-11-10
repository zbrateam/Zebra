//
//  ZBCommand.h
//  Zebra
//
//  Created by Wilson Styres on 9/9/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import Foundation;

#import "ZBCommandDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBCommand : NSObject
@property (nonatomic, strong) NSString *command;
@property (nonatomic, strong, nullable) NSArray <NSString *> *arguments;
@property (nonatomic) BOOL asRoot;
@property (nonatomic) BOOL useFinishFd;
@property (nonatomic, strong, nullable) NSMutableString *output;
+ (nullable NSString *)execute:(NSString *)command withArguments:(NSArray <NSString *> *_Nullable)arguments asRoot:(BOOL)root;
- (instancetype)initWithDelegate:(nullable id <ZBCommandDelegate>)delegate;
- (instancetype)initWithCommand:(NSString *)command arguments:(NSArray <NSString *> *_Nullable)arguments root:(BOOL)root delegate:(nullable id <ZBCommandDelegate>)delegate;
- (int)execute;
@end

NS_ASSUME_NONNULL_END
