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
- (id)initWithDelegate:(id <ZBCommandDelegate>)delegate;
- (int)runCommand:(NSString *)command withArguments:(NSArray *)arguments asRoot:(BOOL)root;
@end

NS_ASSUME_NONNULL_END
