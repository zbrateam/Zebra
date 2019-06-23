//
//  CSColorPickerDelegate.h
//  CSColorPicker
//
//  Created by Dana Buehre on 6/22/19.
//  Copyright © 2019 CreatureCoding. All rights reserved.
//


@class CSColorPickerViewController, CSColorObject;
@protocol CSColorPickerDelegate <NSObject>

@optional
- (void)colorPicker:(CSColorPickerViewController *)picker didPickColor:(CSColorObject *)colorObject;

@end
