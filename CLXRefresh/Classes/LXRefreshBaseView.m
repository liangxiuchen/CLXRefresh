//
//  LXRefreshView.m
//  LXSIPRefresh
//
//  Created by liangxiu chen on 2019/1/4.
//  Copyright © 2019 liangxiu chen. All rights reserved.
//

#import "LXRefreshBaseView.h"
#import "UIScrollView+LXRefresh.h"
#import "LXRefreshView+Internal.h"

#define LXRFMethodDebug do {\
    if (self.isDebug) {\
        if (self.isHeader) {\
            NSLog(@"LXRefreshHeader--%@", NSStringFromSelector(_cmd));\
        } else if (self.isFooter) {\
            NSLog(@"LXRefreshFooter--%@", NSStringFromSelector(_cmd));\
        }\
    }\
} while(0);

#define kShrinkAnimationDuration 0.2f

static void *LXRefreshHeaderViewKVOContext = &LXRefreshHeaderViewKVOContext,
            *LXRefreshFooterViewKVOContext = &LXRefreshFooterViewKVOContext;

@implementation LXRefreshBaseView

- (void *)kvoContext {
    if (self.isFooter) {
        return LXRefreshFooterViewKVOContext;
    } else {
        return LXRefreshHeaderViewKVOContext;
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview && ![newSuperview isKindOfClass:[UIScrollView class]]) return;
    
    if (newSuperview) {
        [self addObservers];
    } else {
        [self removeObservers];
    }
}

- (void)removeObservers {
    //when scrollView dealloc the weak property self.scrollView = nil, so here use superview
    [self.superview removeObserver:self forKeyPath:@"contentOffset"];
    [self.superview removeObserver:self forKeyPath:@"contentSize"];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)addObservers {
    [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld context:[self kvoContext]];
    [self.scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial context:[self kvoContext]];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onDeviceOrientationDidChanged) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if ([self commonInit] == NO) {
        return nil;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if ([self commonInit] == NO) {
        return nil;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self autoPosition];
}

- (void)onDeviceOrientationDidChanged {
    [self autoPosition];
}

- (BOOL)commonInit {
    _isDebug = NO;
    _statusMetric = (LXRefreshViewMetric){0};
    _isAutoPosition = YES;
    _viewStatus = LXRefreshViewStatusInit;
    _logicStatus = LXRefreshLogicStatusNormal;
    BOOL conformed = [self conformsToProtocol:@protocol(LXRefreshSubclassProtocol)];
    NSAssert(conformed, @"LXRefreshView's subclass must be conform one of LXRefreshBaseProtocol, LXRefreshHeaderProtocl, LXRefreshFooterProtocol, LXRefreshviewProtocol");
    if (conformed == NO) {
        return NO;
    }
    return YES;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIsRefreshing {
    return [NSSet setWithObjects:@"viewStatus", @"logicStatus", nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context != LXRefreshHeaderViewKVOContext && context != LXRefreshFooterViewKVOContext) {
        return;
    }
    [self onContentOffsetChanged:change keyPath:keyPath kvoContext:context];
    [self onContentSizeChanged:change keyPath:keyPath context:context];
}

- (void)onContentOffsetChanged:(NSDictionary<NSKeyValueChangeKey,id> * _Nullable)change keyPath:(NSString * _Nullable)keyPath kvoContext:(void *)context {
    if (![keyPath isEqualToString:@"contentOffset"]) {
        return;
    }
    if (self.logicStatus == LXRefreshLogicStatusFinal) {
        return;
    }
    if (self.scrollView.isTracking) {
        CGPoint velocity = [self.scrollView.panGestureRecognizer velocityInView:self.scrollView];
        if (velocity.y > 0) {
            [self updateStatusForHeaderPullDown];
            [self updateStatusForFooterPullDown];
        }
        if (velocity.y < 0) {
            [self updateStatusForHeaderPullUp];
            [self updateStatusForFooterPullUp];
        }
    } else {
        if (self.viewStatus == LXRefreshViewStatusInit) {
            return;
        }
        if (self.isHeader) {
            [self updateToRefreshingForHeader];
        }
        if (self.isFooter) {
            [self updateToRefreshingForFooter];
        }
    }
}

- (void)onContentSizeChanged:(NSDictionary<NSKeyValueChangeKey,id> * _Nullable)change keyPath:(NSString * _Nullable)keyPath context:(void * _Nullable)context  {
    if (![keyPath isEqualToString:@"contentSize"]) {
        return;
    }
    NSValue *newValue = (NSValue *)change[NSKeyValueChangeNewKey];
    if (![newValue isKindOfClass:NSValue.class]) {
        return;
    }
    __unused CGSize contentSize = newValue.CGSizeValue;
    if (self.viewStatus != LXRefreshViewStatusInit) {
        [self autoPositionFooter];
        [self updateFooterStatusMetric];
    }
}
#pragma mark -
#pragma mark - status changed methods
- (void)updateStatusForHeaderPullDown {
    if (!self.isHeader) {
        return;
    }
    CGFloat offset_y = self.scrollView.contentOffset.y;
    if (self.isSmoothRefresh) {
        if (self.viewStatus == LXRefreshViewStatusInit) {
            [self extendInsetsForHeaderHover];
            [self super_onIdle];
        }
        if (offset_y <= self.statusMetric.startMetric) {
            if (self.viewStatus == LXRefreshViewStatusIdle) {
                [self super_onPullToRefreshWithPercent:0];
            }
            if (self.viewStatus == LXRefreshViewStatusPulling) {
                [self super_onReleaseToRefresh];
            }
        }
    } else {
        if (self.viewStatus == LXRefreshViewStatusInit) {
            [self super_onIdle];
        }
        if (self.viewStatus == LXRefreshViewStatusIdle) {
            if (offset_y <= self.statusMetric.startMetric) {
                [self super_onPullToRefreshWithPercent:0];
            }
        }
        if (self.viewStatus == LXRefreshViewStatusPulling) {
            if (offset_y <= self.statusMetric.refreshMetric) {
                [self super_onPullToRefreshWithPercent:100];
                [self super_onReleaseToRefresh];
            } else {
                CGFloat delta = self.statusMetric.startMetric - offset_y > 0 ? self.statusMetric.startMetric - offset_y : 0;
                NSInteger percent = delta / ABS(self.statusMetric.refreshMetric - self.statusMetric.startMetric) * 100;
                [self super_onPullToRefreshWithPercent:percent];
            }
        }
    }
}

- (void)updateStatusForHeaderPullUp {
    if (!self.isHeader) {
        return;
    }
    CGFloat offset_y = self.scrollView.contentOffset.y;
    if (self.viewStatus == LXRefreshViewStatusPulling) {
        if (offset_y > self.statusMetric.startMetric) {
            [self super_onPullToRefreshWithPercent:0];
            [self super_onIdle];
        } else {
            CGFloat delta = self.statusMetric.startMetric - offset_y > 0 ? self.statusMetric.startMetric - offset_y : 0;
            NSInteger percent = delta / ABS(self.statusMetric.refreshMetric - self.statusMetric.startMetric) * 100;
            [self super_onPullToRefreshWithPercent:percent];
        }
    }
    if (self.viewStatus == LXRefreshViewStatusReleaseToRefreshing) {
        if (offset_y > self.statusMetric.refreshMetric) {
            CGFloat delta = self.statusMetric.startMetric - offset_y > 0 ? self.statusMetric.startMetric - offset_y : 0;
            NSInteger percent = delta / ABS(self.statusMetric.refreshMetric - self.statusMetric.startMetric) * 100;
            [self super_onPullToRefreshWithPercent:percent];
        }
    }
}

- (void)updateStatusForFooterPullUp {
    if (!self.isFooter) {
        return;
    }
    CGFloat offset_y = self.scrollView.contentOffset.y;
    if (self.isSmoothRefresh) {
        if (self.viewStatus == LXRefreshViewStatusInit) {
            [self extendInsetsForFooterHover];
            [self super_onIdle];
        }
        if (offset_y >= self.statusMetric.startMetric) {
            if (self.viewStatus == LXRefreshViewStatusIdle) {
                [self super_onPullToRefreshWithPercent:0];
            }
            if (self.viewStatus == LXRefreshViewStatusPulling) {
                [self super_onReleaseToRefresh];
            }
        }
    } else {
        if (self.viewStatus == LXRefreshViewStatusInit) {
            [self super_onIdle];
        }
        if (self.viewStatus == LXRefreshViewStatusIdle) {
            if (offset_y >= self.statusMetric.startMetric) {
                [self super_onPullToRefreshWithPercent:0];
            }
        }
        if (self.viewStatus == LXRefreshViewStatusPulling) {
            if (offset_y >= self.statusMetric.refreshMetric) {
                [self super_onPullToRefreshWithPercent:100];
                [self super_onReleaseToRefresh];
            } else {
                CGFloat delta = offset_y - self.statusMetric.startMetric  > 0 ? offset_y - self.statusMetric.startMetric : 0;
                NSInteger percent = delta / ABS(self.statusMetric.refreshMetric - self.statusMetric.startMetric) * 100;
                [self super_onPullToRefreshWithPercent:percent];
            }
        }
    }
}

- (void)updateStatusForFooterPullDown {
    if (!self.isFooter) {
        return;
    }
    CGFloat offset_y = self.scrollView.contentOffset.y;
    if (self.viewStatus == LXRefreshViewStatusPulling) {
        if (offset_y < self.statusMetric.startMetric) {
            [self super_onPullToRefreshWithPercent:0];
            [self super_onIdle];
        } else {
            CGFloat delta = offset_y - self.statusMetric.startMetric  > 0 ? offset_y - self.statusMetric.startMetric : 0;
            NSInteger percent = delta / ABS(self.statusMetric.refreshMetric - self.statusMetric.startMetric) * 100;
            [self super_onPullToRefreshWithPercent:percent];
        }
    }
    if (self.viewStatus == LXRefreshViewStatusReleaseToRefreshing) {
        if (offset_y < self.statusMetric.refreshMetric) {
            CGFloat delta = offset_y - self.statusMetric.startMetric  > 0 ? offset_y - self.statusMetric.startMetric : 0;
            NSInteger percent = delta / ABS(self.statusMetric.refreshMetric - self.statusMetric.startMetric) * 100;
            [self super_onPullToRefreshWithPercent:percent];
        }
    }
}

- (void)updateToRefreshingForHeader {
    if (!self.isHeader) {
        return;
    }
    if (self.isSmoothRefresh) {
        if (self.viewStatus == LXRefreshViewStatusReleaseToRefreshing) {
            [self super_onRefreshing];
        } else {
            CGFloat offset_y = self.scrollView.contentOffset.y;
            if (offset_y <= self.statusMetric.startMetric) {
                if (self.viewStatus == LXRefreshViewStatusIdle) {
                    [self super_onPullToRefreshWithPercent:0];
                }
                if (self.viewStatus == LXRefreshViewStatusPulling) {
                    [self super_onReleaseToRefresh];
                }
            }
        }
    } else {
        if (self.viewStatus == LXRefreshViewStatusReleaseToRefreshing) {
            [self super_onRefreshing];
            [self extendInsetsForHeaderHover];//insets changed will trigger contenoffset observer
        }
    }
}

- (void)updateToRefreshingForFooter {
    if (!self.isFooter) {
        return;
    }
    if (self.isSmoothRefresh) {
        if (self.viewStatus == LXRefreshViewStatusReleaseToRefreshing) {
            [self super_onRefreshing];
        } else {
            CGFloat offset_y = self.scrollView.contentOffset.y;
            if (offset_y >= self.statusMetric.startMetric) {
                if (self.viewStatus == LXRefreshViewStatusIdle) {
                    [self super_onPullToRefreshWithPercent:0];
                }
                if (self.viewStatus == LXRefreshViewStatusPulling) {
                    [self super_onReleaseToRefresh];
                }
            }
        }
    } else {
        if (self.viewStatus == LXRefreshViewStatusReleaseToRefreshing) {
            [self super_onRefreshing];
            [self extendInsetsForHeaderHover];//insets changed will trigger contenoffset observer
        }
    }
}

#pragma mark -
#pragma mark - subclass protocol event responsed methods
- (void)super_onIdle {
    if (self.viewStatus == LXRefreshViewStatusIdle) {
        return;
    }
    LXRFMethodDebug
    self.viewStatus = LXRefreshViewStatusIdle;
    if ([self respondsToSelector:@selector(onIdle)]) {
        id<LXRefreshSubclassProtocol> subclass = (id<LXRefreshSubclassProtocol>)self;
        [subclass onIdle];
    }
}

- (void)super_onPullToRefreshWithPercent:(NSUInteger)percent {
    if (self.viewStatus != LXRefreshViewStatusPulling) {
        LXRFMethodDebug
        self.viewStatus = LXRefreshViewStatusPulling;
    }
    if ([self respondsToSelector:@selector(onPullingWithPercent:)]) {
        id<LXRefreshSubclassProtocol> subclass = (id<LXRefreshSubclassProtocol>)self;
        [subclass onPullingWithPercent:percent];
    }
}

- (void)super_onReleaseToRefresh {
    if (self.viewStatus == LXRefreshViewStatusReleaseToRefreshing) {
        return;
    }
    LXRFMethodDebug
    self.viewStatus = LXRefreshViewStatusReleaseToRefreshing;
    if ([self respondsToSelector:@selector(onReleaseToRefreshing)]) {
        id<LXRefreshSubclassProtocol> subclass = (id<LXRefreshSubclassProtocol>)self;
        [subclass onReleaseToRefreshing];
    }
}

- (void)super_onRefreshing {
    if (self.viewStatus == LXRefreshViewStatusRefreshing) {
        return;
    }
    LXRFMethodDebug
    self.viewStatus = LXRefreshViewStatusRefreshing;
    if (self.logicStatus == LXRefreshLogicStatusRefreshing) {
        return;
    } else if (self.logicStatus == LXRefreshLogicStatusNormal) {
        self.logicStatus = LXRefreshLogicStatusRefreshing;
        if ([self respondsToSelector:@selector(onRefreshing)]) {
            id<LXRefreshSubclassProtocol> subclass = (id<LXRefreshSubclassProtocol>)self;
            [subclass onRefreshing];
        }
        self.refreshHandler ? self.refreshHandler(self) : (void)0;
    }
}

- (void)super_onFinalized {
    if (self.logicStatus == LXRefreshLogicStatusFinal) {
        return;
    }
    LXRFMethodDebug
    self.logicStatus = LXRefreshLogicStatusFinal;
    if ([self respondsToSelector:@selector(onFinalized)]) {
        id<LXRefreshSubclassProtocol> subclass = (id<LXRefreshSubclassProtocol>)self;
        [subclass onFinalized];
    }
}

#pragma mark -
#pragma mark - getter && setter methods
- (BOOL)isHeader {
    return self.scrollView.lx_refreshHeaderView == self;
}

- (BOOL)isFooter {
    return self.scrollView.lx_refreshFooterView == self;
}

- (BOOL)isRefreshing {
    return _viewStatus == LXRefreshViewStatusRefreshing || _logicStatus == LXRefreshLogicStatusRefreshing;
}

- (BOOL)isFinalized {
    return self.logicStatus == LXRefreshLogicStatusFinal;
}

#pragma mark -
#pragma mark - utility methods
- (void)autoPosition {
    [self autoPositionHeader];
    [self autoPositionFooter];
    [self updateStatusMetric];
}

- (void)autoPositionHeader {
    if (!self.isAutoPosition) {
        return;
    }
    if (!self.isHeader) {
        return;
    }
    CGRect frame = self.bounds;
    frame.origin.y =  -frame.size.height;
    frame.origin.x = (self.scrollView.bounds.size.width - frame.size.width) / 2.f;
    if (CGRectEqualToRect(frame, self.frame) == NO) {
        LXRFMethodDebug
        self.frame = frame;
    }
}

- (void)autoPositionFooter {
    if (!self.isAutoPosition) {
        return;
    }
    if (!self.isFooter) {
        return;
    }
    self.hidden = CGSizeEqualToSize(self.scrollView.contentSize, CGSizeZero);
    CGRect frame = self.bounds;
    CGFloat base = self.scrollView.contentSize.height;
    frame.origin.y = base;
    frame.origin.x = (self.scrollView.bounds.size.width - frame.size.width) / 2.f;
    if (CGRectEqualToRect(frame, self.frame) == NO) {
        LXRFMethodDebug
        self.frame = frame;
    }
}

- (void)updateStatusMetric {
    [self updateHeaderStatusMetric];
    [self updateFooterStatusMetric];
}

- (void)updateHeaderStatusMetric {
    if (!self.isAutoPosition || !self.isHeader || self.scrollView.isTracking) {
        return;
    }
    CGFloat insets_top = self.scrollView.contentInset.top;
    if (@available(iOS 11.0, *)) {
        insets_top = self.scrollView.adjustedContentInset.top;
    }
    _statusMetric.startMetric = CGRectGetMaxY(self.frame) - insets_top;
    _statusMetric.refreshMetric = _statusMetric.startMetric - self.bounds.size.height;
}

- (void)updateFooterStatusMetric {
    if (!self.isAutoPosition || !self.isFooter || self.scrollView.isTracking) {
        return;
    }
    if (self.frame.origin.y < self.scrollView.bounds.size.height) {
        _statusMetric.startMetric = self.scrollView.contentOffset.y;
    } else {
        _statusMetric.startMetric = self.frame.origin.y - self.scrollView.bounds.size.height;
    }
    _statusMetric.refreshMetric = _statusMetric.startMetric + self.bounds.size.height;
}

- (void)endRefreshing {
    self.logicStatus = LXRefreshLogicStatusNormal;
    [self endUIRefreshing];
}

- (void)finalizeRefreshing {
    [self super_onFinalized];
}

- (void)endUIRefreshing {
    if (self.isHeader) {
        if (self.isExtendedContentInsetsForHeaderHover) {
            LXRFMethodDebug
        }
        [self shrinkExtendedTopInsetsWith:^(BOOL finished) {
            [self super_onIdle];
        }];
    } else if (self.isFooter) {
        if (self.isExtendedContentInsetsForFooterHover) {
            LXRFMethodDebug
        }
        [self shrinkExtendedBottomInsetsWith:^(BOOL finished) {
            [self super_onIdle];
        }];
    }
}

- (void)extendInsetsForHeaderHover {
    if (!self.isHeader || self.isExtendedContentInsetsForHeaderHover) {
        return;
    }
    if (self.isExtendedContentInsetsForHeaderHover == NO) {
        LXRFMethodDebug
        self.isExtendedContentInsetsForHeaderHover = YES; //ensure called before self.scrollView.contentInset = insets;
        UIEdgeInsets insets = self.scrollView.contentInset;
        insets.top += ABS(self.statusMetric.refreshMetric - self.statusMetric.startMetric);
        CGPoint offset = self.scrollView.contentOffset;
        self.scrollView.contentInset = insets;
        self.scrollView.contentOffset = offset;
    }
}

- (void)shrinkExtendedTopInsetsWith:(void(^)(BOOL finished))completion {
    if (!self.isSmoothRefresh && self.isExtendedContentInsetsForHeaderHover) {
        dispatch_async(dispatch_get_main_queue(), ^{
            LXRFMethodDebug
            self.isExtendedContentInsetsForHeaderHover = NO;
            UIEdgeInsets insets = self.scrollView.contentInset;
            insets.top -= ABS(self.statusMetric.refreshMetric - self.statusMetric.startMetric);
            [UIView animateWithDuration:CATransaction.animationDuration animations:^{
                self.scrollView.contentInset = insets;
            } completion:completion];
        });
    } else {
        completion ? completion(NO) : (void)0;
    }
}

- (void)extendInsetsForFooterHover {
    if (!self.isFooter || self.isExtendedContentInsetsForFooterHover) {
        return;
    }
    if (self.isExtendedContentInsetsForFooterHover == NO) {
        LXRFMethodDebug
        self.isExtendedContentInsetsForFooterHover = YES;//ensure call before self.scrollView.contentInset = insets;
        UIEdgeInsets insets = self.scrollView.contentInset;
        insets.bottom += ABS(self.statusMetric.refreshMetric - self.statusMetric.startMetric);
        CGPoint offset = self.scrollView.contentOffset;
        self.scrollView.contentInset = insets;
        self.scrollView.contentOffset = offset;
    }
}

- (void)shrinkExtendedBottomInsetsWith:(void(^)(BOOL finished))completion {
    if (!self.isSmoothRefresh && self.isExtendedContentInsetsForFooterHover) {
        dispatch_async(dispatch_get_main_queue(), ^{
            LXRFMethodDebug
            self.isExtendedContentInsetsForFooterHover = NO;
            UIEdgeInsets insets = self.scrollView.contentInset;
            insets.bottom -= ABS(self.statusMetric.refreshMetric - self.statusMetric.startMetric);
            [UIView animateWithDuration:CATransaction.animationDuration animations:^{
                self.scrollView.contentInset = insets;
            } completion:completion];
        });
    } else {
        completion ? completion(YES) : (void)0;
    }
}

@end



#undef LXRFMethodDebug
#undef kShrinkAnimationDuration
