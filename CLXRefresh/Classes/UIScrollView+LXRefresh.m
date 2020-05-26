//
//  UIScrollView+LXRefresh.m
//  LXSIPRefresh
//
//  Created by liangxiu chen on 2019/1/4.
//  Copyright © 2019 liangxiu chen. All rights reserved.
//

#import "UIScrollView+LXRefresh.h"
#import "LXRefreshView+Internal.h"
#import <objc/runtime.h>

static const void *const footerKey = &footerKey, *const headerKey = &headerKey;
@implementation UIScrollView (LXRefresh)

#pragma mark -
#pragma mark - getter & setter

- (LXRefreshBaseView *)lx_refreshHeaderView {
    return objc_getAssociatedObject(self, headerKey);
}

- (void)setLx_refreshHeaderView:(LXRefreshBaseView *)lx_refreshHeaderView {
    if (self.lx_refreshHeaderView == lx_refreshHeaderView) {
        return;
    }
    [self removePreviousRefreshHeaderView];
    objc_setAssociatedObject(self, headerKey, lx_refreshHeaderView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    lx_refreshHeaderView.scrollView = self;
    [self addRefreshHeaderView:lx_refreshHeaderView];
}

- (LXRefreshBaseView *)lx_refreshFooterView {
    return objc_getAssociatedObject(self, footerKey);
}

- (void)setLx_refreshFooterView:(LXRefreshBaseView *)lx_refreshFooterView {
    if (self.lx_refreshFooterView == lx_refreshFooterView) {
        return;
    }
    [self removePreviousRefreshFooterView];
    objc_setAssociatedObject(self, footerKey, lx_refreshFooterView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    lx_refreshFooterView.scrollView = self;
    [self addRefreshFooterView:lx_refreshFooterView];
}

#pragma mark -
#pragma mark - utility

- (void)addKVO:(LXRefreshBaseView * _Nonnull)observer withContext:(void *)context {
    //will be removed at ZMRefreshView's dealloc method
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
}

- (void)addRefreshFooterView:(LXRefreshBaseView * _Nonnull)lx_refreshFooterView {
    [self addSubview:lx_refreshFooterView];
}

@end

