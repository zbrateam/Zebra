//
//  UIAlertController+Private.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 2/5/2563 BE.
//  Copyright © 2563 Wilson Styres. All rights reserved.
//

#ifndef UIAlertController_Private_h
#define UIAlertController_Private_h

@interface UIAlertController (Private)
@property (setter=_setIndexesOfActionSectionSeparators:, getter=_indexesOfActionSectionSeparators, nonatomic, copy) NSIndexSet * indexesOfActionSectionSeparators API_AVAILABLE(ios(10.0));
@end

#endif /* UIAlertController_Private_h */
