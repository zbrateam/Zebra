//
//  ZBPartialPresentationController.m
//  Zebra
//
//  Created by Wilson Styres on 11/14/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBPartialPresentationController.h"

@interface ZBPartialPresentationController () {
    UIView *shadeView;
    UITapGestureRecognizer *tapGestureRecognizer;
    CGFloat proportion;
}
@end

@implementation ZBPartialPresentationController

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController {
    self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    
    if (self) {
        shadeView = [[UIView alloc] init];
        shadeView.backgroundColor = [UIColor blackColor];
        shadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        shadeView.userInteractionEnabled = YES;
        
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        [shadeView addGestureRecognizer:tapGestureRecognizer];
        
        proportion = 2;
    }
    
    return self;
}

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController scale:(CGFloat)scale {
    if (scale <= 0 || scale >= 1) return NULL;
    
    self = [self initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    
    if (self) {
        self->proportion = 1 / scale;
    }
    
    return self;
}

- (void)dismiss {
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (CGRect)frameOfPresentedViewInContainerView {
    return CGRectMake(0, self.containerView.frame.size.height - self.containerView.frame.size.height / proportion, self.containerView.frame.size.width, self.containerView.frame.size.height / proportion);
}

- (void)containerViewWillLayoutSubviews {
    [super containerViewWillLayoutSubviews];
    
    self.presentedView.layer.masksToBounds = YES;
    self.presentedView.layer.cornerRadius = 20;
}

- (void)containerViewDidLayoutSubviews {
    [super containerViewDidLayoutSubviews];
    
    self.presentedView.frame = self.frameOfPresentedViewInContainerView;
    shadeView.frame = self.containerView.bounds;
}

- (void)presentationTransitionWillBegin {
    shadeView.alpha = 0;
    [self.containerView addSubview:shadeView];
    
    [self.presentedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self->shadeView.alpha = 0.5;
    } completion:nil];
}

- (void)dismissalTransitionWillBegin {
    [self.presentedViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self->shadeView.alpha = 0;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self->shadeView removeFromSuperview];
    }];
}

@end
