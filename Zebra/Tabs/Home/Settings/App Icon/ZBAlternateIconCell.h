//
//  ZBAlternateIconCell.h
//  Zebra
//
//  Created by Adam Demasi on 11/1/2022.
//  Copyright © 2022 Wilson Styres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZBAlternateIconCellDelegate <NSObject>

- (void)setAlternateIconFromSet:(NSDictionary <NSString *, id> *)iconSet atIndex:(NSInteger)index;

@end

@interface ZBAlternateIconCell : UITableViewCell

@property (nonatomic, strong) NSDictionary <NSString *, id> *iconSet;
@property (nonatomic, weak) id <ZBAlternateIconCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
