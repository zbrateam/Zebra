//
//  ZBNoScrollHeaderTableView.m
//  Zebra
//
//  Created by midnightchips on 7/2/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBNoScrollHeaderTableView.h"


@implementation ZBNoScrollHeaderTableView

- (BOOL)allowsFooterViewsToFloat {
    return NO;
}

- (BOOL)allowsHeaderViewsToFloat {
    return NO;
}

@end
