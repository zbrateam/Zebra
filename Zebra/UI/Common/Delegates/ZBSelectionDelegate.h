//
//  ZBSelectionDelegate.h
//  Zebra
//
//  Created by Wilson Styres on 11/17/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#ifndef ZBSelectionDelegate_h
#define ZBSelectionDelegate_h

@protocol ZBSelectionDelegate
- (void)selectedChoices:(NSArray *)choices fromIndexPath:(NSIndexPath *)indexPath;
@end

#endif /* ZBSelectionDelegate_h */
