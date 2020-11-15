//
//  ZBHalfPresentationController.m
//  Zebra
//
//  Created by Wilson Styres on 11/14/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBHalfPresentationController.h"

@interface ZBHalfPresentationController () {
    UIView *shadeView;
    UITapGestureRecognizer *tapGestureRecognizer;
}
@end

@implementation ZBHalfPresentationController

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController {
    self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    
    if (self) {
        shadeView = [[UIView alloc] init];
        shadeView.backgroundColor = [UIColor blackColor];
        shadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        shadeView.userInteractionEnabled = YES;
        
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        [shadeView addGestureRecognizer:tapGestureRecognizer];
    }
    
    return self;
}

- (void)dismiss {
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (CGRect)frameOfPresentedViewInContainerView {
    return CGRectMake(0, self.containerView.frame.size.height / 2, self.containerView.frame.size.width, self.containerView.frame.size.height / 2);
}

- (void)containerViewWillLayoutSubviews {
    [super containerViewWillLayoutSubviews];
    
    self.presentedView.layer.masksToBounds = NO;
    self.presentedView.layer.cornerRadius = 10;
    self.presentedView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.presentedView.layer.shadowOpacity = 0.25;
    self.presentedView.layer.shadowOffset = CGSizeZero;
    self.presentedView.layer.shadowRadius = 20;
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
