#import "UINavigationController+Opacity.h"
#import "UIImage+ImageWithColor.h"

@implementation UINavigationController(Clear)

- (void)setClear:(BOOL)clear {
	[self setOpacity:(clear ? 0.0 : 1.0)];
}

- (void)setOpacity:(CGFloat)opacity {
	if (@available(iOS 7.0, *)) {
		UIImage *image = [UIImage imageWithColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:min(opacity, 1.0)]];
		[self.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
		self.navigationBar.shadowImage = opacity < 0.5 ? image : nil;
	}
}

@end