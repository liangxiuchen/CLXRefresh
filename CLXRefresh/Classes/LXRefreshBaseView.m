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
        NSLog(@"LXRefresh--%@", NSStringFromSelector(_cmd));\
    }\
} while(0);

#define kShrinkAnimationDuration 0.2f

static void *LXRefreshHeaderViewKVOContext = &LXRefreshHeaderViewKVOContext,
            *LXRefreshFooterViewKVOContext = &LXRefreshFooterViewKVOContext;

@implementation LXRefreshBaseView

+ (void *)headerKVOContext {
    return LXRefreshHeaderViewKVOContext;
}

+ (void *)footerKVOContext {
    return LXRefreshFooterViewKVOContext;
}

- (void)dealloc {
    [self releaseScrollView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)releaseScrollView {
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [self.scrollView removeObserver:self forKeyPath:@"contentSize"];
    [self.scrollView.panGestureRecognizer removeObserver:self forKeyPath:@"state"];
}

- (instancetype)initWithFrame:(CGRect)frame RefreshHandler:(LXRefreshHandler)handler {
    self = [self initWithFrame:frame];
    if (self) {
        _refreshHandler = [handler copy];
    }
    return self;
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

- (BOOL)commonInit {
    _isDebug = NO;
    _isAutoPosition = YES;
    _pendingRefreshes = 0;
    _isAlwaysTriggerRefreshHandler = NO;
    _extendInsets = (UIEdgeInsets){0};
    _viewStatus = LXRefreshStatusInit;
    _logicStatus = LXRefreshLogicStatusNormal;
    BOOL conformed = [self conformsToProtocol:@protocol(LXRefreshViewSubclassProtocol)];
    NSAssert(conformed, @"LXRefreshView's subclass must be conform LXRefreshViewSubclassProtocol");
    if (conformed == NO) {
        return NO;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceOrientationdidChanged) name:UIDeviceOrientationDidChangeNotification object:nil];
    return YES;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIsRefreshing {
    return [NSSet setWithObjects:@"viewStatus", @"logicStatus", nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context != LXRefreshHeaderViewKVOContext && context != LXRefreshFooterViewKVOContext) {
        return;
    }
    [self onPanGestureStateChanged:change keyPath:keyPath kvoContext:context];
    [self onContentOffsetChanged:change keyPath:keyPath kvoContext:context];
    [self onContentSizeChanged:change keyPath:keyPath context:context];
}

- (void)onPanGestureStateChanged:(NSDictionary<NSKeyValueChangeKey,id> * _Nullable)change keyPath:(NSString * _Nullable)keyPath kvoContext:(void *)context {
    if (![keyPath isEqualToString:@"state"]) {
        return;
    }
    NSNumber *newValue = (NSNumber *)change[NSKeyValueChangeNewKey];
    NSNumber *oldValue = (NSNumber *)change[NSKeyValueChangeOldKey];
    if (![newValue isKindOfClass:NSNumber.class]) {
        newValue = nil;
    }
    if (![oldValue isKindOfClass:NSNumber.class]) {
        oldValue = nil;
    }
    
    UIGestureRecognizerState newState = (UIGestureRecognizerState)(newValue != nil ? newValue.integerValue : UIGestureRecognizerStatePossible);
    UIGestureRecognizerState oldState = (UIGestureRecognizerState) (oldValue != nil ? (UIGestureRecognizerState)oldValue.integerValue : UIGestureRecognizerStatePossible);
    BOOL isTracking_new = (newState == UIGestureRecognizerStateBegan || newState == UIGestureRecognizerStateChanged);
    BOOL isTracking_old = (oldState == UIGestureRecognizerStateBegan || oldState == UIGestureRecognizerStateChanged);
    
    self.scrollViewIsTracking = isTracking_new;
    BOOL isFingerUp = isTracking_old == YES && isTracking_new == NO;
    if (isFingerUp) {
        [self extendInsetsForHeaderHoverWithCompletion];
        [self extendInsetsForFooterHoverWithCompletion];
    }
    [self super_onIsTrackingChanged:isTracking_new oldIsTracking:isTracking_old];
}

- (void)onContentOffsetChanged:(NSDictionary<NSKeyValueChangeKey,id> * _Nullable)change keyPath:(NSString * _Nullable)keyPath kvoContext:(void *)context {
    if (![keyPath isEqualToString:@"contentOffset"]) {
        return;
    }
    
    NSValue *newValue = (NSValue *)change[NSKeyValueChangeNewKey];
    NSValue *oldValue = (NSValue *)change[NSKeyValueChangeOldKey];
    if (![newValue isKindOfClass:NSValue.class]) {
        newValue = nil;
    }
    if (![oldValue isKindOfClass:NSValue.class]) {
        oldValue = nil;
    }
    if (self.viewStatus == LXRefreshStatusInit) {
        [self super_onViewStatusIdle];
    }
    [self detectBecomingToRefreshingOrIdle:newValue];
    [self detectPullingToRefreshing:newValue];
    [self super_onContentOffsetChanged:(newValue ? newValue.CGPointValue : CGPointZero)
                             oldOffset:(oldValue ? oldValue.CGPointValue : CGPointZero)];
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
    [self relayoutFooter];
}

- (void)onContentInsetsChanged {
    [self relayoutHeader];
    [self relayoutFooter];
}

- (void)onDeviceOrientationdidChanged {
    LXRFMethodDebug
    //escape a runloop for bounds sync to device rotate
    dispatch_async(dispatch_get_main_queue(), ^{
        [self keepHorizontallyCenter];
    });
}

#pragma mark -
#pragma mark - subclass protocol event responsed methods

- (void)super_onViewStatusIdle {
    if (self.viewStatus != LXRefreshStatusIdle) {
        LXRFMethodDebug
        LXRefreshViewStatus previous = self.viewStatus;
        self.viewStatus = LXRefreshStatusIdle;
        if (self.logicStatus == LXRefreshLogicStatusRefreshFinished) {
            self.logicStatus = LXRefreshLogicStatusNormal;
        }
        if ([self respondsToSelector:@selector(onViewStatusIdle:)]) {
            id<LXRefreshViewSubclassProtocol> subclass = (id<LXRefreshViewSubclassProtocol>)self;
            [subclass onViewStatusIdle:previous];
        }
    }
}

- (void)super_onPullingToRefreshing:(CGFloat)percent {
    if (self.viewStatus != LXRefreshStatusPullingToRefresh) {
        LXRFMethodDebug
    }
    self.viewStatus = LXRefreshStatusPullingToRefresh;
    if ([self respondsToSelector:@selector(onPullingToRefreshing:)]) {
        id<LXRefreshViewSubclassProtocol> subclass = (id<LXRefreshViewSubclassProtocol>)self;
        [subclass onPullingToRefreshing:percent];
    }
}

- (void)super_onViewStatusBecomingToRefreshing:(CGFloat)total OffsetY:(CGFloat)offset_y {
    if (self.viewStatus == LXRefreshStatusIdle) {
        return;
    }
    CGFloat percent = 0.f;
    if (total <= 0.f) {
        return;
    }
    if (self.isHeader) {
        CGFloat delta = self.statusMetric.refreshMetric - offset_y;
        if (delta < 0.f) {
            return;
        }
        percent = 1.f - delta / total;
        if (percent < 0.f) {
            return;
        }
    }
    if (self.isFooter) {
        CGFloat delta = offset_y - self.statusMetric.refreshMetric;
        if (delta < 0.f) {
            return;
        }
        percent = 1.f - delta / total;
        if (percent < 0.f) {
            return;
        }
    }
    self.viewStatus = LXRefreshStatusBecomingToRefreshing;
    if ([self respondsToSelector:@selector(onBecomingToRefreshing:)]) {
        id<LXRefreshViewSubclassProtocol> subclass = (id<LXRefreshViewSubclassProtocol>)self;
        [subclass onBecomingToRefreshing:percent];
    }
}

- (void)super_onViewStatusBecomingToIdle:(CGFloat)total {
    if (self.viewStatus == LXRefreshStatusIdle) {
        return;
    }
    CGFloat percent = 0.f;
    self.viewStatus = LXRefreshStatusBecomingToIdle;
    if (total <= 0.f) {
        return;
    }
    if (self.isHeader) {
        CGFloat delta = self.statusMetric.startMetric - self.scrollView.contentOffset.y;
        if (delta < 0.f) {
            return;
        }
        percent = 1.f - delta / total;
        if (percent < 0.f) {
            return;
        }
    }
    if (self.isFooter) {
        CGFloat delta = (self.scrollView.contentOffset.y + self.scrollView.bounds.size.height) - self.statusMetric.startMetric;
        if (delta < 0.f) {
            return;
        }
        percent = 1.f - delta / total;
        if (percent < 0.f) {
            return;
        }
    }
    if ([self respondsToSelector:@selector(onBecomingToIdle:)]) {
        id<LXRefreshViewSubclassProtocol> subclass = (id<LXRefreshViewSubclassProtocol>)self;
        [subclass onBecomingToIdle:percent];
    }
}

- (void)super_onViewStatusRefreshing {
    if (self.viewStatus != LXRefreshStatusRefreshing) {
        LXRFMethodDebug
        LXRefreshViewStatus previous = self.viewStatus;
        self.viewStatus = LXRefreshStatusRefreshing;
        if (self.isAlwaysTriggerRefreshHandler) {
            self.pendingRefreshes += 1;
            self.logicStatus = LXRefreshLogicStatusRefreshing;
            self.refreshHandler(self);
        }  else if (self.pendingRefreshes > 0) {
            self.logicStatus = LXRefreshLogicStatusRefreshing;
        } else {
            if (self.logicStatus == LXRefreshLogicStatusNormal) {
                self.logicStatus = LXRefreshLogicStatusRefreshing;
                self.refreshHandler(self);
            } else if (self.logicStatus == LXRefreshLogicStatusRefreshFinished) {
                [self endRefreshing];
            }
        }
        if ([self respondsToSelector:@selector(onViewStatusRefreshing:)]) {
            id<LXRefreshViewSubclassProtocol> subclass = (id<LXRefreshViewSubclassProtocol>)self;
            [subclass onViewStatusRefreshing:previous];
        }
    }
}

- (void)super_onContentOffsetChanged:(CGPoint)newValue oldOffset:(CGPoint)oldValue {
    if ([self respondsToSelector:@selector(onContentOffsetChanged:oldOffset:)]) {
        id<LXRefreshViewSubclassProtocol> subclass = (id<LXRefreshViewSubclassProtocol>)self;
        [subclass onContentOffsetChanged:newValue oldOffset:oldValue];
    }
}

- (void)super_onIsTrackingChanged:(BOOL)newValue oldIsTracking:(BOOL)oldValue {
    if ([self respondsToSelector:@selector(onIsTrackingChanged:oldIsTracking:)]) {
        id<LXRefreshViewSubclassProtocol> subclass = (id<LXRefreshViewSubclassProtocol>)self;
        [subclass onIsTrackingChanged:newValue oldIsTracking:oldValue];
    }
}

- (void)super_onContentInsetsChanged:(UIEdgeInsets)insets {
    [self onContentInsetsChanged];
    if ([self respondsToSelector:@selector(onContentInsetChanged:)]) {
        id<LXRefreshViewSubclassProtocol> subclass = (id<LXRefreshViewSubclassProtocol>)self;
        [subclass onContentInsetChanged:insets];
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
    return _viewStatus == LXRefreshStatusRefreshing && _logicStatus == LXRefreshLogicStatusRefreshing;
}

- (void)setIsAutoPosition:(BOOL)isAutoPosition {
    if (CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        _isAutoPosition = NO;
    } else {
        _isAutoPosition = isAutoPosition;
    }
}

- (BOOL)isFullScreen {
    return self.scrollView.contentSize.height >= (self.scrollView.bounds.size.height - self.systemInsets.top - self.userAdditionalInsets.top);
}

- (void)setUserAdditionalInsets:(UIEdgeInsets)userAdditionalInsets {
    _userAdditionalInsets = userAdditionalInsets;
    if (self.isAutoPosition) {
        [self updateStatusMetric];
    }
}

- (UIEdgeInsets)systemInsets {
    UIEdgeInsets insets = {0};
    CGFloat extendedTop = self.isExtendContentInsetsForHeaderHover ? self.extendInsets.top : 0.f;
    CGFloat extendedBottom = self.isExtendContentInsetsForFooterHover ? self.extendInsets.bottom : 0.f;
    if (@available(iOS 11, *)) {
        insets.top = self.scrollView.adjustedContentInset.top - self.userAdditionalInsets.top - extendedTop;
        insets.bottom = self.scrollView.adjustedContentInset.bottom - self.userAdditionalInsets.bottom - extendedBottom - self.paddingToFullScreen;
        insets.left = self.scrollView.adjustedContentInset.left - self.userAdditionalInsets.left;
        insets.right = self.scrollView.adjustedContentInset.right - self.userAdditionalInsets.right;
    } else {
        insets.top = self.scrollView.contentInset.top - self.userAdditionalInsets.top - extendedTop;
        insets.bottom = self.scrollView.contentInset.bottom - self.userAdditionalInsets.bottom - extendedBottom - self.paddingToFullScreen;;
        insets.left = self.scrollView.contentInset.left - self.userAdditionalInsets.left;
        insets.right = self.scrollView.contentInset.right - self.userAdditionalInsets.right;
    }
    return insets;
}

#pragma mark -
#pragma mark - utility methods

- (void)keepHorizontallyCenter {
    if (self.isAutoPosition) {
        CGRect frame = self.frame;
        frame.origin.x = (self.scrollView.bounds.size.width - frame.size.width) / 2.f;
        self.frame = frame;
    }
}

- (void)relayoutHeader {
    if (self.isHeader && self.isAutoPosition) {
        LXRFMethodDebug
        CGRect frame = self.frame;
        frame.origin.y =  -frame.size.height;
        if (CGRectEqualToRect(frame, self.frame) == NO) {
            self.frame = frame;
        }
        [self updateStatusMetric];
        return;
    }
}

- (void)relayoutFooter {
    if (self.isFooter && self.isAutoPosition) {
        LXRFMethodDebug
        self.hidden = CGSizeEqualToSize(self.scrollView.contentSize, CGSizeZero);
        CGRect frame = self.frame;
        CGFloat base = self.scrollView.contentSize.height;
        frame.origin.y = base;
        if (CGRectEqualToRect(frame, self.frame) == NO) {
            self.frame = frame;
        }
        [self updateStatusMetric];
        return;
    }
}


- (void)updateStatusMetric {
    if (self.isHeader) {
        _statusMetric.startMetric = -(self.systemInsets.top + self.userAdditionalInsets.top);
        _statusMetric.refreshMetric = _statusMetric.startMetric - self.extendInsets.top;
    }
    if (self.isFooter) {
        if (self.isFullScreen) {
            _statusMetric.startMetric = self.frame.origin.y + (self.systemInsets.bottom + self.userAdditionalInsets.bottom);
        } else {
            _statusMetric.startMetric = self.frame.origin.y + (self.systemInsets.bottom + self.userAdditionalInsets.bottom) - (self.systemInsets.top + self.userAdditionalInsets.top);
        }
        _statusMetric.refreshMetric = _statusMetric.startMetric + self.extendInsets.bottom;
    }
}

- (void)beginHeaderRefresh {
    dispatch_block_t task = ^{
        if (self.isExtendContentInsetsForHeaderHover == NO) {
            LXRFMethodDebug
            self.isExtendContentInsetsForHeaderHover = YES; //ensure called before self.scrollView.contentInset = insets;
            UIEdgeInsets insets = self.scrollView.contentInset;
            insets.top += self.extendInsets.top;
            self.scrollView.contentInset = insets;
            CGPoint offset = self.scrollView.contentOffset;
            offset.y = self.statusMetric.startMetric;
            [UIView animateWithDuration:0.2 animations:^{
                self.scrollView.contentOffset = offset;
            } completion:^(BOOL finished) {
                [self super_onViewStatusRefreshing];
            }];
        }
    };
    if (!self.isHeader) {
        return;
    }
    if (NSThread.isMainThread) {
        task();
    } else {
        dispatch_async(dispatch_get_main_queue(), task);
    }
}

- (void)endRefreshing {
    dispatch_block_t task = ^{
        LXRFMethodDebug
        if (self.isAlwaysTriggerRefreshHandler) {
            self.pendingRefreshes -= 1;
            self.pendingRefreshes = self.pendingRefreshes < 0 ? 0 : self.pendingRefreshes;
            if (self.pendingRefreshes <= 0) {
                self.logicStatus = LXRefreshLogicStatusRefreshFinished;
                [self endUIRefreshing];
            } else {
                self.logicStatus = LXRefreshLogicStatusRefreshing;
            }
        } else if (self.pendingRefreshes > 0) {
            self.pendingRefreshes -= 1;
            self.pendingRefreshes = self.pendingRefreshes < 0 ? 0 : self.pendingRefreshes;
            if (self.pendingRefreshes <= 0) {
                self.logicStatus = LXRefreshLogicStatusRefreshFinished;
                [self endUIRefreshing];
            } else {
                self.logicStatus = LXRefreshLogicStatusRefreshing;
            }
        } else {
            self.logicStatus = LXRefreshLogicStatusRefreshFinished;
            [self endUIRefreshing];
        }
    };
    if (NSThread.isMainThread) {
        task();
    } else {
        dispatch_async(dispatch_get_main_queue(), task);
    }
}

- (void)endUIRefreshing {
    if (self.isHeader) {
        //is a header refresh view
        if (self.scrollView.contentOffset.y >= self.statusMetric.startMetric ) {
            [self shrinkExtendedTopInsetsWithCompletion:^(BOOL finished) {
                [self super_onViewStatusIdle];
            }];
        } else if (self.scrollViewIsTracking) {
            return;
        } else {
            [self shrinkExtendedTopInsetsWithCompletion:^(BOOL finished) {
                [self super_onViewStatusIdle];
            }];
        }
        
    } else if (self.isFooter) {
        if ((self.scrollView.contentOffset.y + self.scrollView.bounds.size.height) <= self.statusMetric.startMetric) {
            [self shrinkExtendedBottomInsetsWithCompletion:^(BOOL finished) {
                [self super_onViewStatusIdle];
            }];
        } else if (self.scrollViewIsTracking) {
            return;
        } else {
            [self shrinkExtendedBottomInsetsWithCompletion:^(BOOL finished) {
                [self super_onViewStatusIdle];
            }];
        }
    }
}

- (void)extendInsetsForHeaderHoverWithCompletion {
    if (!self.isHeader) {
        return;
    }
    if (self.scrollViewIsTracking) {
        return;
    }
    BOOL shouldExtend = self.scrollView.contentOffset.y <= self.statusMetric.refreshMetric;
    if (!shouldExtend) {
        return;
    }
    if (self.isExtendContentInsetsForHeaderHover == NO) {
        LXRFMethodDebug
        self.isExtendContentInsetsForHeaderHover = YES; //ensure called before self.scrollView.contentInset = insets;
        UIEdgeInsets insets = self.scrollView.contentInset;
        insets.top += self.extendInsets.top;
        CGPoint contentOffset = self.scrollView.contentOffset;
        self.scrollView.contentInset = insets;
        self.scrollView.contentOffset = contentOffset;
    }
}

- (void)shrinkExtendedTopInsetsWithCompletion:(void(^)(BOOL finished))handler {
    if (self.isHeader == NO) {
        return;
    }
    if (self.isExtendContentInsetsForHeaderHover) {
        LXRFMethodDebug
        self.isExtendContentInsetsForHeaderHover = NO;
        UIEdgeInsets insets = self.scrollView.contentInset;
        insets.top -= self.extendInsets.top;
        //animation
        [UIView animateWithDuration:kShrinkAnimationDuration animations:^{
            self.scrollView.contentInset = insets;
            self.scrollView.contentOffset = self.scrollView.contentOffset;
        } completion:handler];
    } else {
        handler ? handler(YES) : (void)0;
    }
}

- (void)extendInsetsForFooterHoverWithCompletion {
    if (!self.isFooter) {
        return;
    }
    if (self.scrollViewIsTracking) {
        return;
    }
    BOOL shouldExtend = NO;
    if (self.isFullScreen) {
        shouldExtend = (self.scrollView.contentOffset.y + self.scrollView.bounds.size.height) >= self.statusMetric.refreshMetric;
    } else {
        shouldExtend = (self.scrollView.contentOffset.y + self.scrollView.contentSize.height) >= self.statusMetric.refreshMetric;
    }
    if (!shouldExtend) {
        return;
    }
    if (self.isExtendContentInsetsForFooterHover == NO) {
        LXRFMethodDebug
        self.isExtendContentInsetsForFooterHover = YES;//ensure call before self.scrollView.contentInset = insets;
        UIEdgeInsets insets = self.scrollView.contentInset;
        if (self.isFullScreen) {
            insets.bottom += self.extendInsets.bottom;
        } else {
            self.paddingToFullScreen = (self.scrollView.bounds.size.height - self.systemInsets.top - self.userAdditionalInsets.top) - self.scrollView.contentSize.height;
            insets.bottom += self.extendInsets.bottom + self.paddingToFullScreen;
        }
        CGPoint contentOffset = self.scrollView.contentOffset;
        self.scrollView.contentInset = insets;
        self.scrollView.contentOffset = contentOffset;
    }
}

- (void)shrinkExtendedBottomInsetsWithCompletion:(void(^)(BOOL finished))handler {
    if (self.isFooter == NO) {
        return;
    }
    if (self.isExtendContentInsetsForFooterHover) {
        LXRFMethodDebug
        self.isExtendContentInsetsForFooterHover = NO;
        UIEdgeInsets insets = self.scrollView.contentInset;
        CGFloat padding = self.paddingToFullScreen;
        self.paddingToFullScreen = 0.f;
        insets.bottom -= self.extendInsets.bottom + padding;
        //animation
        [UIView animateWithDuration:kShrinkAnimationDuration animations:^{
            self.scrollView.contentInset = insets;
            self.scrollView.contentOffset = self.scrollView.contentOffset;
        } completion:handler];
    } else {
        handler ? handler(YES) : (void)0;
    }
}

- (void)detectPullingToRefreshing:(NSValue *)newValue {
    LXRFMethodDebug
    CGFloat offset_y = newValue.CGPointValue.y;
    if (self.isHeader && self.scrollViewIsTracking) {
        CGFloat total = self.statusMetric.startMetric - self.statusMetric.refreshMetric;
        if (offset_y <= self.statusMetric.refreshMetric) {
            [self super_onPullingToRefreshing:1.f];
        } else if (offset_y < self.statusMetric.startMetric) {
            CGFloat pullDelta = self.statusMetric.startMetric - offset_y;
            [self super_onPullingToRefreshing:(pullDelta / total)];
        }
    }
    
    if (self.isFooter && self.scrollViewIsTracking) {
        if (self.isFullScreen) {
            offset_y += self.scrollView.bounds.size.height;
        } else {
            offset_y += self.scrollView.contentSize.height;
        }
        CGFloat total = self.statusMetric.refreshMetric - self.statusMetric.startMetric;
        if (offset_y >= self.statusMetric.refreshMetric) {
            [self super_onPullingToRefreshing:1.f];
        } else if (offset_y > self.statusMetric.startMetric) {
            CGFloat pullDelta = offset_y - self.statusMetric.startMetric;
            [self super_onPullingToRefreshing:(pullDelta / total)];
        }
    }
}

- (void)detectBecomingToRefreshingOrIdle:(NSValue *)newValue {
    LXRFMethodDebug
    if (self.scrollViewIsTracking == NO && self.scrollView.isDecelerating) {
        CGFloat offset_y = newValue.CGPointValue.y;
        static CGFloat total;
        if (self.isHeader) {
            if (self.viewStatus == LXRefreshStatusPullingToRefresh) {
                if (offset_y <= self.statusMetric.refreshMetric) {
                    total = self.statusMetric.refreshMetric - offset_y;
                    [self super_onViewStatusBecomingToRefreshing:total OffsetY:offset_y];
                } else if (offset_y <= self.statusMetric.startMetric) {
                    total = self.statusMetric.startMetric - offset_y;
                    [self super_onViewStatusBecomingToIdle:total];
                }
            }
            if (self.viewStatus == LXRefreshStatusBecomingToRefreshing) {
                [self super_onViewStatusBecomingToRefreshing:total OffsetY:offset_y];
            }
            if (self.viewStatus == LXRefreshStatusBecomingToIdle) {
                [self super_onViewStatusBecomingToIdle:total];
            }
        }
        if (self.isFooter) {
            if (self.isFullScreen) {
                offset_y += self.scrollView.bounds.size.height;
            } else {
                offset_y += self.scrollView.contentSize.height;
            }
            if (self.viewStatus == LXRefreshStatusPullingToRefresh) {
                if (offset_y >= self.statusMetric.refreshMetric) {
                    total = offset_y - self.statusMetric.refreshMetric;
                    [self super_onViewStatusBecomingToRefreshing:total OffsetY:offset_y];
                } else if (offset_y >= self.statusMetric.startMetric) {
                    total = offset_y - self.statusMetric.startMetric;
                    [self super_onViewStatusBecomingToIdle:total];
                }
            }
            if (self.viewStatus == LXRefreshStatusBecomingToRefreshing) {
                [self super_onViewStatusBecomingToRefreshing:total OffsetY:offset_y];
            }
            if (self.viewStatus == LXRefreshStatusBecomingToIdle) {
                [self super_onViewStatusBecomingToIdle:total];
            }
        }
    }
}

- (void)scrollTo:(CGFloat)position_y animated:(BOOL)animated {
    CGPoint contentOffset = self.scrollView.contentOffset;
    contentOffset.y = position_y;
    [self.scrollView setContentOffset:contentOffset animated:animated];
}

- (void)didEndScrolling {
    LXRFMethodDebug
    if (self.isHeader && self.viewStatus != LXRefreshStatusIdle) {
        CGFloat contentOffset = self.scrollView.contentOffset.y;
        if (contentOffset == self.statusMetric.refreshMetric) {
            [self super_onViewStatusRefreshing];
        } else {
            [self endUIRefreshing];
        }
    } else if (self.isFooter && self.viewStatus != LXRefreshStatusIdle) {
        CGFloat contentOffset = 0.f;
        if (self.isFullScreen) {
            contentOffset = self.scrollView.contentOffset.y + self.scrollView.bounds.size.height;
        } else {
            contentOffset = self.scrollView.contentOffset.y + self.scrollView.contentSize.height;
        }
        if (contentOffset == self.statusMetric.refreshMetric) {
            [self super_onViewStatusRefreshing];
        } else {
            [self endUIRefreshing];
        }
    }
}

#pragma mark -
#pragma mark - UIScrollViewDelegate methods

- (void)dispatchSelector:(SEL)sel execute:(void(^)(id<UIScrollViewDelegate> delegate))handler {
    if (self.isHeader) {
        if (self.scrollView.lx_refreshFooterView) {
            //header-->footer-->realDetegate
            id<UIScrollViewDelegate> footer = self.scrollView.lx_refreshFooterView;
            if ([footer respondsToSelector:sel]) {
                handler ? handler(footer) : (void)0;
            }
        } else {
            //header-->realDelegate
            id<UIScrollViewDelegate> delegate = self.scrollView.lx_refreshHeaderView.realDelegate;
            if ([delegate respondsToSelector:sel]) {
                handler ? handler(delegate) : (void)0;
            }
        }
        
    } else if (self.isFooter) {
        id<UIScrollViewDelegate> delegate = nil;
        if (self.scrollView.lx_refreshHeaderView) {
            delegate = self.scrollView.lx_refreshHeaderView.realDelegate;
        } else {
            delegate = self.scrollView.lx_refreshFooterView.realDelegate;
        }
        if ([delegate respondsToSelector:sel]) {
            handler ? handler(delegate) : (void)0;
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self dispatchSelector:@selector(scrollViewDidScroll:) execute:^(id<UIScrollViewDelegate> delegate) {
        [delegate scrollViewDidScroll:scrollView];
    }];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView NS_AVAILABLE_IOS(3_2){
    [self dispatchSelector:@selector(scrollViewDidZoom:) execute:^(id<UIScrollViewDelegate> delegate) {
        [delegate scrollViewDidZoom:scrollView];
    }];
}

// called on start of dragging (may require some time and or distance to move)
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self dispatchSelector:@selector(scrollViewWillBeginDragging:) execute:^(id<UIScrollViewDelegate> delegate) {
        [delegate scrollViewWillBeginDragging:scrollView];
    }];
}
// called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset NS_AVAILABLE_IOS(5_0) {
    [self dispatchSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:) execute:^(id<UIScrollViewDelegate> delegate) {
        [delegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }];
}
// called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self dispatchSelector:@selector(scrollViewDidEndDragging:willDecelerate:) execute:^(id<UIScrollViewDelegate> delegate) {
        [delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }];
    //hook code
    LXRFMethodDebug
    if (decelerate == NO) {
        [self didEndScrolling];
    }
    
}
// called on finger up as we are moving
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [self dispatchSelector:@selector(scrollViewWillBeginDecelerating:) execute:^(id<UIScrollViewDelegate> delegate) {
        [delegate scrollViewWillBeginDecelerating:scrollView];
    }];
}

// called when scroll view grinds to a halt
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self dispatchSelector:@selector(scrollViewDidEndDecelerating:) execute:^(id<UIScrollViewDelegate> delegate) {
        [delegate scrollViewDidEndDecelerating:scrollView];
    }];
    LXRFMethodDebug
    [self didEndScrolling];
}

// called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self dispatchSelector:@selector(scrollViewDidEndScrollingAnimation:) execute:^(id<UIScrollViewDelegate> delegate) {
        [delegate scrollViewDidEndScrollingAnimation:scrollView];
    }];
}

// return a view that will be scaled. if delegate returns nil, nothing happens
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (self.isHeader) {
        if (self.scrollView.lx_refreshFooterView) {
            id<UIScrollViewDelegate> footer = self.scrollView.lx_refreshFooterView;
            if ([footer respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
                return [footer viewForZoomingInScrollView:scrollView];
            }
        } else {
            id<UIScrollViewDelegate> delegate = self.scrollView.lx_refreshHeaderView.realDelegate;
            if ([delegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
                return [delegate viewForZoomingInScrollView:scrollView];
            }
        }
    } else if (self.isFooter) {
        id<UIScrollViewDelegate> delegate = nil;
        if (self.scrollView.lx_refreshHeaderView) {
            delegate = self.scrollView.lx_refreshHeaderView.realDelegate;
        } else {
            delegate = self.scrollView.lx_refreshFooterView.realDelegate;
        }
        if ([delegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
            return [delegate viewForZoomingInScrollView:scrollView];
        }
    }
    return nil;
}

// called before the scroll view begins zooming its content
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view NS_AVAILABLE_IOS(3_2) {
    [self dispatchSelector:@selector(scrollViewWillBeginZooming:withView:) execute:^(id<UIScrollViewDelegate> delegate) {
        [delegate scrollViewWillBeginZooming:scrollView withView:view];
    }];
}

// scale between minimum and maximum. called after any 'bounce' animations
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale {
    [self dispatchSelector:@selector(scrollViewDidEndZooming:withView:atScale:) execute:^(id<UIScrollViewDelegate> delegate) {
        [delegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
    }];
}


// return a yes if you want to scroll to the top. if not defined, assumes YES
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    BOOL should = YES;
    if (self.isHeader) {
        if (self.scrollView.lx_refreshFooterView) {
            id<UIScrollViewDelegate> footer = self.scrollView.lx_refreshFooterView;
            if ([footer respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
                return [footer scrollViewShouldScrollToTop:scrollView];
            }
        } else {
            id<UIScrollViewDelegate> delegate = self.scrollView.lx_refreshHeaderView.realDelegate;
            if ([delegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
                should = [delegate scrollViewShouldScrollToTop:scrollView];
                if (should) {
                    [self scrollTo:self.statusMetric.startMetric animated:YES];
                    should = NO;
                }
                return should;
            } else if (should){
                [self scrollTo:self.statusMetric.startMetric animated:YES];
                should = NO;
            }
        }
        
    } else if (self.isFooter) {
        id<UIScrollViewDelegate> delegate = nil;
        if (self.scrollView.lx_refreshHeaderView) {
            delegate = self.scrollView.lx_refreshHeaderView.realDelegate;
        } else {
            delegate = self.scrollView.lx_refreshFooterView.realDelegate;
        }
        if ([delegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
            [delegate scrollViewShouldScrollToTop:scrollView];
        }
    }
    return should;
}

// called when scrolling animation finished. may be called immediately if already at top
- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView; {
    [self dispatchSelector:@selector(scrollViewDidScrollToTop:) execute:^(id<UIScrollViewDelegate> delegate) {
        [delegate scrollViewDidScrollToTop:scrollView];
    }];
}

/* Also see -[UIScrollView adjustedContentInsetDidChange] */
- (void)scrollViewDidChangeAdjustedContentInset:(UIScrollView *)scrollView API_AVAILABLE(ios(11.0), tvos(11.0)) {
    [self dispatchSelector:@selector(scrollViewDidChangeAdjustedContentInset:) execute:^(id<UIScrollViewDelegate> delegate) {
        [delegate scrollViewDidChangeAdjustedContentInset:scrollView];
    }];
}

@end

#undef LXRFMethodDebug
#undef kShrinkAnimationDuration
