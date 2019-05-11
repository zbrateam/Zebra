//
//  UIBarButtonItem+blocks.h
//
//  Created by Julian Weinert on 04.08.14.
//  Copyright (c) 2014 Julian Weinert Softwareentwicklung. All rights reserved.
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 2 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import <UIKit/UIKit.h>

typedef void (^UIBarButtonItemActionHandler)();

@interface UIBarButtonItem (blocks)

- (id)initWithImage:(UIImage *)image style:(UIBarButtonItemStyle)style actionHandler:(UIBarButtonItemActionHandler)actionHandler;
- (id)initWithImage:(UIImage *)image landscapeImagePhone:(UIImage *)landscapeImagePhone style:(UIBarButtonItemStyle)style actionHandler:(UIBarButtonItemActionHandler)actionHandler NS_AVAILABLE_IOS(5_0);
- (id)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style actionHandler:(UIBarButtonItemActionHandler)actionHandler;
- (id)initWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem actionHandler:(UIBarButtonItemActionHandler)actionHandler;

- (void)setActionHandler:(UIBarButtonItemActionHandler)actionHandler;

@end
