//
//  UIBarButtonItem+blocks.m
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

#import "UIBarButtonItem+blocks.h"
#import <objc/runtime.h>

@implementation UIBarButtonItem (blocks)

- (id)initWithImage:(UIImage *)image style:(UIBarButtonItemStyle)style actionHandler:(UIBarButtonItemActionHandler)actionHandler {
	if (self = [self initWithImage:image style:style target:self action:@selector(performActionHandler)]) {
		[self setActionHandler:actionHandler];
	}
	return self;
}

- (id)initWithImage:(UIImage *)image landscapeImagePhone:(UIImage *)landscapeImagePhone style:(UIBarButtonItemStyle)style actionHandler:(UIBarButtonItemActionHandler)actionHandler {
	if (self = [self initWithImage:image landscapeImagePhone:landscapeImagePhone style:style target:self action:@selector(performActionHandler)]) {
		[self setActionHandler:actionHandler];
	}
	return self;
}

- (id)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style actionHandler:(UIBarButtonItemActionHandler)actionHandler {
	if (self = [self initWithTitle:title style:style target:self action:@selector(performActionHandler)]) {
		[self setActionHandler:actionHandler];
	}
	return self;
}

- (id)initWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem actionHandler:(UIBarButtonItemActionHandler)actionHandler {
	if (self = [self initWithBarButtonSystemItem:systemItem target:self action:@selector(performActionHandler)]) {
		[self setActionHandler:actionHandler];
	}
	return self;
}

- (void)setActionHandler:(UIBarButtonItemActionHandler)actionHandler {
	objc_setAssociatedObject(self, "actionHandler", actionHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)performActionHandler {
	UIBarButtonItemActionHandler actionHandler = objc_getAssociatedObject(self, "actionHandler");
	actionHandler();
}

@end
