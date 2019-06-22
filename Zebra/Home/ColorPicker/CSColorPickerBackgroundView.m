//
// Created by CreatureSurvive on 3/17/17.
// Copyright (c) 2016 - 2019 CreatureCoding. All rights reserved.
//

// credits libColorPicker https://github.com/atomikpanda/libcolorpicker/blob/master/PFColorTransparentView.m
#import "CSColorPickerBackgroundView.h"

@implementation CSColorPickerBackgroundView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.gridCount = 10;
        self.tag = 199;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    int scale = rect.size.width / 25;
    NSArray *colors = @[[UIColor whiteColor], [UIColor grayColor]];

    for (int row = 0; row < rect.size.height; row += scale) {

        int index = row % (scale * 2) == 0 ? 0 : 1;
        
        for (int column = 0; column < rect.size.width; column += scale) {
        
            [[colors objectAtIndex:index++ % 2] setFill];
            
            UIRectFill(CGRectMake(column, row, scale, scale));
        }
    }
}

@end
