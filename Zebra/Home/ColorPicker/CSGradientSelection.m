//
// Created by CreatureSurvive on 4/7/19.
// Copyright (c) 2016 - 2019 CreatureCoding. All rights reserved.
//

#import "CSGradientSelection.h"
#import <Extensions/UIColor+CSColorPicker.h>
#import <Extensions/NSString+CSColorPicker.h>

@implementation CSGradientSelection {
	UIScrollView *_scrollView;
	CGFloat _height;
	CGFloat _spacing;
	CGFloat _buttonPadding;
}

- (instancetype)initWithSize:(CGSize)size target:(id)target addAction:(SEL)add removeAction:(SEL)remove selectAction:(SEL)select {
	if ((self = [super initWithFrame:CGRectMake(0, 0, size.width, size.height)])) {
		_target = target;
		_addAction = add;
		_selectAction = select;
		_removeAction = remove;
		[self commonInit];
	}
	
	return self;
}

- (void)commonInit {
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    blurView.frame = self.bounds;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    blurView.userInteractionEnabled = NO;
	[self addSubview:blurView];

	_buttonPadding = 2.5;
	
	_scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
	_scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	_scrollView.showsVerticalScrollIndicator = NO;
	_scrollView.showsHorizontalScrollIndicator = NO;
	_scrollView.hidden = YES;

	_gradient = [CAGradientLayer layer];
    _gradient.frame = CGRectMake(0, self.bounds.size.height - 15, self.bounds.size.width, 15);
	_gradient.colors = @[(id)UIColor.clearColor.CGColor, (id)UIColor.clearColor.CGColor];
    _gradient.startPoint = CGPointMake(0, 0.5);
    _gradient.endPoint = CGPointMake(1, 0.5);
	_gradient.hidden = YES;

	[blurView.layer addSublayer:self.gradient];

	[self addSubview:_scrollView];
	
	_height = self.bounds.size.height;
	_spacing = 5;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	_height = self.bounds.size.height;
	_scrollView.contentSize = CGSizeMake(_scrollView.contentSize.width, _height);
	self.gradient.frame = CGRectMake(0, self.bounds.size.height - 15, self.bounds.size.width, 15);
}

- (void)setBackgroundColor:(UIColor *)color {
	[super setBackgroundColor:color];
	_scrollView.backgroundColor = color;
}

- (void)generateButtons {

	[_scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	_buttons = [NSMutableArray new];

	__block CGFloat size = 0;
	void (^addButton)(UIButton *) = ^void(UIButton *button) {
		[self->_scrollView addSubview:button];
		
		CGRect frame = button.frame;
		frame.origin.x = size + self->_spacing;
		frame.origin.y = self->_buttonPadding;
		
		button.frame = frame;
		size += button.bounds.size.width + self->_spacing;
	};

	if ((self.colors.count)) {
		[self.colors enumerateObjectsUsingBlock:^(UIColor *color, NSUInteger index, BOOL *stop) {
			UIButton *button = [self accessoryButtonWithColor:color index:index];
            [self->_buttons addObject:button];
			addButton(button);
		}];

		addButton([self.class accessoryButtonSpace]);
	}

	addButton([self.class accessoryButtonWithTitle:@"Add" target:self.target action:self.addAction color:UIColor.whiteColor index:-1]);

	if (self.colors.count > 2) {
		addButton([self.class accessoryButtonWithTitle:@"Remove" target:self.target action:self.removeAction color:UIColor.whiteColor index:-1]);
	}

	_scrollView.contentSize = CGSizeMake(size + _spacing, _height);
	_scrollView.hidden = NO;
}

- (void)updateGradient {
	self.gradient.hidden = _colors.count ? NO : YES;
	NSMutableArray *gradientColors = [NSMutableArray new];
	for (UIColor *color in _colors) {
		[gradientColors addObject:(id)color.CGColor];
	}
	self.gradient.colors = gradientColors;
}

- (void)animateOffsetAndGradient {
	[UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self->_scrollView.contentOffset = CGPointMake(self->_scrollView.contentSize.width > self->_scrollView.bounds.size.width ? self->_scrollView.contentSize.width - self->_scrollView.bounds.size.width : 0, 0);
		[self updateGradient];
	} completion:nil];
}

- (void)addColor:(UIColor *)color {
	if (!_colors) _colors = [NSMutableArray new];
	
	[_colors addObject:color];
	[self generateButtons];
	[self animateOffsetAndGradient];
}

- (void)addColors:(NSArray *)colors {
	if (!_colors) _colors = [NSMutableArray new];
	
	[_colors addObjectsFromArray:colors];
	[self generateButtons];
	[self animateOffsetAndGradient];
}

- (void)removeColorAtIndex:(NSInteger)index {
	if (!_colors || _colors.count < index) return;
	
	[_colors removeObjectAtIndex:index];
	[self generateButtons];
	[self animateOffsetAndGradient];
}

- (void)setColor:(UIColor *)color atIndex:(NSInteger)index {
	if ((!_colors || _colors.count < index) || (!_buttons || _buttons.count < index)) return;

	_colors[index] = color;

	UIColor *titleColor = (!color.cscp_light && color.cscp_alpha > 0.5) ? UIColor.whiteColor : UIColor.blackColor;
	UIColor *shadowColor = titleColor == UIColor.blackColor ? UIColor.whiteColor : UIColor.blackColor;
	UIButton *button = _buttons[index];
	[button.layer setBackgroundColor:color.CGColor];
	[button.titleLabel.layer setShadowColor:shadowColor.CGColor];
	[button setTitle:color.cscp_hexString forState:UIControlStateNormal];
	[button setTitleColor:titleColor forState:UIControlStateNormal];
	[button setTitleColor:[titleColor colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
	
	[self updateGradient];
}

- (UIButton *)accessoryButtonWithColor:(UIColor *)color index:(NSInteger)index {
	return [self.class accessoryButtonWithTitle:color.cscp_hexString target:self.target action:self.selectAction color:color index:index];
}

+ (UIButton *)accessoryButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action color:(UIColor *)color index:(NSInteger)index {
	UIColor *titleColor = (!color.cscp_light && color.cscp_alpha > 0.5) ? UIColor.whiteColor : UIColor.blackColor;
    UIColor *shadowColor = titleColor == UIColor.blackColor ? UIColor.whiteColor : UIColor.blackColor;
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
	button.layer.backgroundColor = color.CGColor;
	button.layer.borderColor = UIColor.lightGrayColor.CGColor;
	button.layer.borderWidth = 1;
	button.layer.cornerRadius = 9.0;
	button.tag = 199;

	[button.titleLabel.layer setShadowOffset:CGSizeZero];
    [button.titleLabel.layer setShadowRadius:1];
    [button.titleLabel.layer setShadowOpacity:1];
    [button.titleLabel.layer setShadowColor:shadowColor.CGColor];
	
	[button.titleLabel setTag:index];
	[button.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
	[button.titleLabel setAdjustsFontSizeToFitWidth:YES];
	[button setTitle:@"0000000" forState:UIControlStateNormal];
	[button setTitleColor:titleColor forState:UIControlStateNormal];
	[button setTitleColor:[titleColor colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];

	[button sizeToFit];
	[button setTitle:title forState:UIControlStateNormal];
	
	[button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];

	return button;
}

+ (UIButton *)accessoryButtonSpace {
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.contentEdgeInsets = UIEdgeInsetsMake(-3.0f, 2.0f, -3.0f, 2.0f);
	button.tag = 199;

	[button setTitle:@"" forState:UIControlStateNormal];
	[button setTitleColor:[[UIColor darkTextColor] colorWithAlphaComponent:0.2] forState:UIControlStateNormal];

	[button sizeToFit];
	
	return button;
}

@end
