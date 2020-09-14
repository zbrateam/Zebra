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
@property NSString *command;
@property NSArray <NSString *> *_Nullable arguments;
@property (nonatomic) BOOL asRoot;
@property NSMutableString *_Nullable output;
+ (NSString *)execute:(NSString *)command withArguments:(NSArray <NSString *> *_Nullable)arguments asRoot:(BOOL)root;
- (id)initWithDelegate:(id <ZBCommandDelegate>)delegate;
- (id)initWithCommand:(NSString *)command arguments:(NSArray <NSString *> *_Nullable)arguments root:(BOOL)root delegate:(id <ZBCommandDelegate>)delegate;
- (int)execute;
@end

NS_ASSUME_NONNULL_END
