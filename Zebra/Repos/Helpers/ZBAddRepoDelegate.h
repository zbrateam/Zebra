//
//  ZBAddRepoDelegate.h
//  Zebra
//
//  Created by shiftcmdk on 04/25/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#ifndef ZBAddRepoDelegate_h
#define ZBAddRepoDelegate_h

@protocol ZBAddRepoDelegate <NSObject>

-(void)didAddReposWithText:(NSString *)text;

@end

#endif /* ZBAddRepoDelegate_h */
