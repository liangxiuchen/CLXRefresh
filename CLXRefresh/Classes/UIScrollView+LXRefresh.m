//
//  UIScrollView+LXRefresh.m
//  LXSIPRefresh
//
//  Created by liangxiu chen on 2019/1/4.
//  Copyright © 2019 liangxiu chen. All rights reserved.
//

#import "UIScrollView+LXRefresh.h"
#import "LXRefreshBaseView+Internal.h"
#import "UIScrollView+LXInternal.h"
#import <objc/runtime.h>

static const void *const footerKey = &footerKey, *const headerKey = &headerKey;
void swizzle(Class class, SEL target, SEL beSwizzled);
@implementation UIScrollView (CLXRefresh)

#pragma mark -
#pragma mark - getter & setter
- (LXRefreshBaseView *)lx_refreshHeaderView {
    return objc_getAssociatedObject(self, headerKey);
}

- (void)setLx_refreshHeaderView:(LXRefreshBaseView *)LX_refreshHeaderView {
    if (self.lx_refreshHeaderView == LX_refreshHeaderView) {
        return;
    }
    [self removePreviousRefreshHeaderView];
    objc_setAssociatedObject(self, headerKey, LX_refreshHeaderView, OBJC_ASSOCIATION_ASSIGN);
    [self addRefreshHeaderView:LX_refreshHeaderView];
    [self addKVO:LX_refreshHeaderView withContext:LXRefreshBaseView.headerKVOContext];
}

- (LXRefreshBaseView *)lx_refreshFooterView {
    return objc_getAssociatedObject(self, footerKey);
}

- (void)setLx_refreshFooterView:(LXRefreshBaseView *)LX_refreshFooterView {
    if (self.lx_refreshFooterView == LX_refreshFooterView) {
        return;
    }
    [self removePreviousRefreshFooterView];
    objc_setAssociatedObject(self, footerKey, LX_refreshFooterView, OBJC_ASSOCIATION_ASSIGN);
    [self addRefreshFooterView:LX_refreshFooterView];
    [self addKVO:LX_refreshFooterView withContext:LXRefreshBaseView.footerKVOContext];
}

#pragma mark -
#pragma mark - utility

- (void)addKVO:(LXRefreshBaseView * _Nonnull)observer withContext:(void *)context {
    //will be removed at LXRefreshView's dealloc method
    [self addObserver:observer forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld context:context];
    [self addObserver:observer forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial context:context];
    [self.panGestureRecognizer addObserver:observer forKeyPath:@"state" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial context:context];
}

- (void)removePreviousRefreshHeaderView {
    LXRefreshBaseView *old = (LXRefreshBaseView *)[self lx_refreshHeaderView];
    if (![old isKindOfClass:LXRefreshBaseView.class]) {
        return;
    }
    if (old.superview && [old.superview isKindOfClass:UIScrollView.class]) {
        [old removeFromSuperview];
    }
}

- (void)removePreviousRefreshFooterView {
    LXRefreshBaseView *old = (LXRefreshBaseView *)[self lx_refreshFooterView];
    if (![old isKindOfClass:LXRefreshBaseView.class]) {
        return;
    }
    if (old.superview && [old.superview isKindOfClass:UIScrollView.class]) {
        [old removeFromSuperview];
    }
}

- (void)addRefreshHeaderView:(LXRefreshBaseView * _Nonnull)lx_refreshHeaderView {
    [self addSubview:lx_refreshHeaderView];
    lx_refreshHeaderView.scrollView = self;
    
    UIEdgeInsets insets = lx_refreshHeaderView.extendInsets;
    if (insets.top == 0.f) {
        insets.top = lx_refreshHeaderView.bounds.size.height;
        lx_refreshHeaderView.extendInsets = insets;
    }
    
    if (lx_refreshHeaderView.isAutoPosition) {
        CGRect headerFrame = lx_refreshHeaderView.frame;
        CGSize size = headerFrame.size;
        headerFrame.origin.x = (self.bounds.size.width - headerFrame.size.width) / 2.f;
        headerFrame.origin.y = -size.height;
        lx_refreshHeaderView.frame = headerFrame;
        [lx_refreshHeaderView updateStatusMetric];
    }
}

- (void)addRefreshFooterView:(LXRefreshBaseView * _Nonnull)lx_refreshFooterView {
    [self addSubview:lx_refreshFooterView];
    lx_refreshFooterView.scrollView = self;
    
    UIEdgeInsets insets = lx_refreshFooterView.extendInsets;
    if (insets.bottom == 0.f) {
        insets.bottom = lx_refreshFooterView.bounds.size.height;
        lx_refreshFooterView.extendInsets = insets;
    }
    
    if (lx_refreshFooterView.isAutoPosition) {
        CGRect footerFrame = lx_refreshFooterView.frame;
        footerFrame.origin.x = (self.bounds.size.width - footerFrame.size.width) / 2.f;
        footerFrame.origin.y = self.contentSize.height;
        lx_refreshFooterView.frame = footerFrame;
        [lx_refreshFooterView updateStatusMetric];
    }
}

#pragma mark -
#pragma mark - swizzling methods

void swizzle(Class class, SEL target, SEL beSwizzled) {
    Method target_Method = class_getInstanceMethod(class, target);
    Method beSwizzled_Method = class_getInstanceMethod(class, beSwizzled);
    if (target_Method == NULL || beSwizzled_Method == NULL) {
        return;
    }
    method_exchangeImplementations(target_Method, beSwizzled_Method);
#if DEBUG
    NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    NSLog(@"swizzle class:%@ from:%@ to:%@ by LXRefresh",NSStringFromClass(class), NSStringFromSelector(target), NSStringFromSelector(beSwizzled));
#endif
}

+ (void)load {
    swizzle(self, @selector(setContentInset:), @selector(LX_setContentInset:));
    swizzle(self, @selector(setDelegate:), @selector(LX_setDelegate:));
    if (@available(iOS 11,*)) {
        swizzle(self, @selector(adjustedContentInsetDidChange), @selector(LX_adjustedContentInsetDidChange));
    }
}

- (void)LX_adjustedContentInsetDidChange NS_AVAILABLE_IOS(11.0) {
    [self LX_adjustedContentInsetDidChange];
    
    [self.lx_refreshHeaderView super_onContentInsetsChanged:self.adjustedContentInset];
    [self.lx_refreshFooterView super_onContentInsetsChanged:self.adjustedContentInset];
}

- (void)LX_setContentInset:(UIEdgeInsets)contentInset {
    [self LX_setContentInset:contentInset];
    if (@available(iOS 11, *)) {
    } else {
        [self.lx_refreshHeaderView super_onContentInsetsChanged:contentInset];
        [self.lx_refreshFooterView super_onContentInsetsChanged:contentInset];
    }
}

- (void)LX_setDelegate:(id<UIScrollViewDelegate>)delegate {
    if (delegate == nil) {
        self.lx_delegate = nil;
        return;
    }
    LXScrollViewDelegateProxy *proxy = [LXScrollViewDelegateProxy delegateProxyWithHost:delegate ScrollView:self];
    [self LX_setDelegate:proxy];
    self.lx_delegate = proxy;
}

@end
