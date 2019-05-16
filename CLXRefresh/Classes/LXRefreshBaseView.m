//
//  LXRefreshView.m
//  LXSIPRefresh
//
//  Created by liangxiu chen on 2019/1/4.
//  Copyright © 2019 liangxiu chen. All rights reserved.
//

#import "LXRefreshBaseView.h"
#import "UIScrollView+LXRefresh.h"
#import "LXRefreshBaseView+Internal.h"

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
    _enable = YES;
    _pendingRefreshes = 0;
    _isAlwaysTriggerRefreshHandler = NO;
    _footerRefreshTriggeredWithoutPull = NO;
    _shouldDisableFooterWhenEmpty = YES;
    _extendInsets = (UIEdgeInsets){0};
    _viewStatus = LXRefreshStatusInit;
    _logicStatus = LXRefreshLogicStatusNormal;
    
    BOOL conformed = [self conformsToProtocol:@protocol(LXRefreshBaseProtocol)];
    NSAssert(conformed, @"LXRefreshView's subclass must be conform one of LXRefreshBaseProtocol, LXRefreshHeaderProtocl, LXRefreshFooterProtocol, LXRefreshviewProtocol");
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
    if (self.shouldDisableFooterWhenEmpty && self.isFooter) {
        if ([keyPath isEqualToString:@"contentSize"]) {
            NSValue *newValue = (NSValue *)change[NSKeyValueChangeNewKey];
            if (![newValue isKindOfClass:NSValue.class]) {
                return;
            }
            self.enable = !CGSizeEqualToSize(newValue.CGSizeValue, CGSizeZero);
        }
    }
    if (self.enable == NO) {
        return;
    }
    [self onPanGestureStateChanged:change keyPath:keyPath kvoContext:context];
    [self onContentOffsetChanged:change keyPath:keyPath kvoContext:context];
    [self onContentSizeChanged:change keyPath:keyPath context:context];
}

- (void)onPanGestureStateChanged:(NSDictionary<NSKeyValueChangeKey,id> * _Nullable)change keyPath:(NSString * _Nullable)keyPath kvoContext:(void *)context {
    if (context != LXRefreshHeaderViewKVOContext && context != LXRefreshFooterViewKVOContext) {
        return;
    }
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
        [self extendInsetsForHeaderHover];
        [self extendInsetsForFooterHover];
        self.velocityWhenFingerUp = [self.scrollView.panGestureRecognizer velocityInView:self.scrollView];
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
    [self detectPullingToRefreshing:newValue];
    [self detectBecomingToRefreshingOrIdle:newValue];
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
    if (!self.isFullScreen) {
        [self shrinkExtendedBottomInsetsWith:nil];
    }
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
            id<LXRefreshBaseProtocol> subclass = (id<LXRefreshBaseProtocol>)self;
            [subclass onViewStatusIdle:previous];
        }
    }
}

- (void)super_onPullingToRefreshing:(CGFloat)percent {
    if (self.viewStatus == LXRefreshStatusRefreshing && self.isFullScreen) {
        return;
    }
    if (self.viewStatus != LXRefreshStatusPullingToRefresh) {
        LXRFMethodDebug
    }
    if (self.isFooter && !self.isFullScreen) {
        if (percent == 1.f) {
            self.viewStatus = LXRefreshStatusRefreshing;
        } else {
            self.viewStatus = LXRefreshStatusPullingToRefresh;
        }
    } else {
        self.viewStatus = LXRefreshStatusPullingToRefresh;
    }
    if ([self respondsToSelector:@selector(onPullingToRefreshing:)]) {
        id<LXRefreshBaseProtocol> subclass = (id<LXRefreshBaseProtocol>)self;
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
        CGFloat delta = 0.f;
        if (self.isFullScreen) {
            delta = offset_y - self.statusMetric.refreshMetric;
        } else {
            delta = offset_y - self.statusMetric.startMetric;
        }
        if (delta < 0.f) {
            return;
        }
        percent = 1.f - delta / total;
        if (percent < 0.f) {
            return;
        }
    }
    self.viewStatus = LXRefreshStatusBecomingToRefreshing;
    if ([self respondsToSelector:@selector(onBecomingRefreshing:)]) {
        id<LXRefreshBaseProtocol> subclass = (id<LXRefreshBaseProtocol>)self;
        [subclass onBecomingRefreshing:percent];
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
        id<LXRefreshHeaderProtocol> subclass = (id<LXRefreshHeaderProtocol>)self;
        [subclass onBecomingToIdle:percent];
    }
}

- (void)super_onViewStatusRefreshing {
    LXRefreshViewStatus previous = self.viewStatus;
    self.viewStatus = LXRefreshStatusRefreshing;
    if (self.isAlwaysTriggerRefreshHandler) {
        self.pendingRefreshes += 1;
        self.logicStatus = LXRefreshLogicStatusRefreshing;
        LXRFMethodDebug
        if ([self respondsToSelector:@selector(onViewStatusRefreshing:)]) {
            id<LXRefreshBaseProtocol> subclass = (id<LXRefreshBaseProtocol>)self;
            [subclass onViewStatusRefreshing:previous];
        }
        self.refreshHandler ? self.refreshHandler(self) : (void)0;
    }  else if (self.pendingRefreshes > 0) {
        self.logicStatus = LXRefreshLogicStatusRefreshing;
    } else {
        if (self.logicStatus == LXRefreshLogicStatusNormal) {
            LXRFMethodDebug
            self.logicStatus = LXRefreshLogicStatusRefreshing;
            if ([self respondsToSelector:@selector(onViewStatusRefreshing:)]) {
                id<LXRefreshBaseProtocol> subclass = (id<LXRefreshBaseProtocol>)self;
                [subclass onViewStatusRefreshing:previous];
            }
            self.refreshHandler ? self.refreshHandler(self) : (void)0;
        } else if (self.logicStatus == LXRefreshLogicStatusRefreshing) {
            LXRFMethodDebug
            if ([self respondsToSelector:@selector(onViewStatusRefreshing:)]) {
                id<LXRefreshBaseProtocol> subclass = (id<LXRefreshBaseProtocol>)self;
                [subclass onViewStatusRefreshing:previous];
            }
        } else if (self.logicStatus == LXRefreshLogicStatusRefreshFinished) {
            [self endRefreshing];
        }
    }
}

- (void)super_onContentOffsetChanged:(CGPoint)newValue oldOffset:(CGPoint)oldValue {
    if ([self respondsToSelector:@selector(onContentOffsetChanged:oldOffset:)]) {
        id<LXRefreshBaseProtocol> subclass = (id<LXRefreshBaseProtocol>)self;
        [subclass onContentOffsetChanged:newValue oldOffset:oldValue];
    }
}

- (void)super_onIsTrackingChanged:(BOOL)newValue oldIsTracking:(BOOL)oldValue {
    if ([self respondsToSelector:@selector(onIsTrackingChanged:oldIsTracking:)]) {
        id<LXRefreshBaseProtocol> subclass = (id<LXRefreshBaseProtocol>)self;
        [subclass onIsTrackingChanged:newValue oldIsTracking:oldValue];
    }
}

- (void)super_onContentInsetsChanged:(UIEdgeInsets)insets {
    [self onContentInsetsChanged];
    if ([self respondsToSelector:@selector(onContentInsetChanged:)]) {
        id<LXRefreshBaseProtocol> subclass = (id<LXRefreshBaseProtocol>)self;
        [subclass onContentInsetChanged:insets];
    }
}

#pragma mark -
#pragma mark - getter && setter methods

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    self.hidden = !enable;
}

- (BOOL)isHeader {
    return self.scrollView.lx_refreshHeaderView == self;
}

- (BOOL)isFooter {
    return self.scrollView.lx_refreshFooterView == self;
}

- (BOOL)isRefreshing {
    return _viewStatus == LXRefreshStatusRefreshing || _logicStatus == LXRefreshLogicStatusRefreshing;
}

- (BOOL)isIdle {
    return _viewStatus == LXRefreshStatusIdle;
}

- (BOOL)isFullScreen {
    return self.scrollView.contentSize.height >= (self.scrollView.bounds.size.height - self.systemInsets.top - self.userAdditionalInsets.top);
}

- (void)setUserAdditionalInsets:(UIEdgeInsets)userAdditionalInsets {
    _userAdditionalInsets = userAdditionalInsets;
//    if (self.isAutoPosition) {
        [self updateStatusMetric];
//    }
}

- (UIEdgeInsets)systemInsets {
    UIEdgeInsets insets = {0};
    CGFloat extendedTop = self.isExtendedContentInsetsForHeaderHover ? self.extendInsets.top : 0.f;
    CGFloat extendedBottom = self.isExtendedContentInsetsForFooterHover ? self.extendInsets.bottom : 0.f;
    if (@available(iOS 11, *)) {
        insets.top = self.scrollView.adjustedContentInset.top - self.userAdditionalInsets.top - extendedTop;
        insets.bottom = self.scrollView.adjustedContentInset.bottom - self.userAdditionalInsets.bottom - extendedBottom;
        insets.left = self.scrollView.adjustedContentInset.left - self.userAdditionalInsets.left;
        insets.right = self.scrollView.adjustedContentInset.right - self.userAdditionalInsets.right;
    } else {
        insets.top = self.scrollView.contentInset.top - self.userAdditionalInsets.top - extendedTop;
        insets.bottom = self.scrollView.contentInset.bottom - self.userAdditionalInsets.bottom - extendedBottom;
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
    if (self.isHeader) {
        if (self.isAutoPosition) {
            CGRect frame = self.frame;
            frame.origin.y =  -frame.size.height;
            if (CGRectEqualToRect(frame, self.frame) == NO) {
                LXRFMethodDebug
                self.frame = frame;
            }
        }
        [self updateStatusMetric];
    }
}

- (void)relayoutFooter {
    if (self.isFooter) {
        if (self.isAutoPosition) {
            self.hidden = CGSizeEqualToSize(self.scrollView.contentSize, CGSizeZero);
            CGRect frame = self.frame;
            CGFloat base = self.scrollView.contentSize.height;
            frame.origin.y = base;
            if (CGRectEqualToRect(frame, self.frame) == NO) {
                LXRFMethodDebug
                self.frame = frame;
            }
        }
        [self updateStatusMetric];
    }
}


- (void)updateStatusMetric {
    if (self.isHeader) {
        _statusMetric.startMetric = CGRectGetMaxY(self.frame) - (self.systemInsets.top);
        _statusMetric.refreshMetric = _statusMetric.startMetric - self.extendInsets.top;
    }
    if (self.isFooter) {
        if (self.isFullScreen) {
            _statusMetric.startMetric = self.frame.origin.y + self.systemInsets.bottom;
        } else {
            _statusMetric.startMetric = self.frame.origin.y + (self.systemInsets.bottom) - (self.systemInsets.top);
        }
        _statusMetric.refreshMetric = _statusMetric.startMetric + self.extendInsets.bottom;
    }
}

- (void)beginRefreshing {
    dispatch_block_t task = ^{
        if (self.isExtendedContentInsetsForHeaderHover == NO) {
            LXRFMethodDebug
            self.isExtendedContentInsetsForHeaderHover = YES; //ensure called before self.scrollView.contentInset = insets;
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
        if (self.pendingRefreshes > 0) {
            self.pendingRefreshes -= 1;
            self.pendingRefreshes = self.pendingRefreshes < 0 ? 0 : self.pendingRefreshes;
            if (self.pendingRefreshes == 0) {
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
        LXRFMethodDebug
        task();
    } else {
        LXRFMethodDebug
        dispatch_async(dispatch_get_main_queue(), task);
    }
}

- (void)endUIRefreshing {
    if (self.isHeader) {
        //is a header refresh view
        if (self.scrollViewIsTracking && self.scrollView.isDragging) {
            return;
        }
        if (self.isExtendedContentInsetsForHeaderHover) {
            LXRFMethodDebug
        }
        [self shrinkExtendedTopInsetsWith:^(BOOL finished) {
            [self super_onViewStatusIdle];
        }];
    } else if (self.isFooter) {
        if (self.isExtendedContentInsetsForFooterHover) {
            LXRFMethodDebug
        }
        [self shrinkExtendedBottomInsetsWith:^(BOOL finished) {
            [self super_onViewStatusIdle];
        }];
    }
}

- (void)extendInsetsForHeaderHover {
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
    if (self.isExtendedContentInsetsForHeaderHover == NO) {
        LXRFMethodDebug
        self.isExtendedContentInsetsForHeaderHover = YES; //ensure called before self.scrollView.contentInset = insets;
        UIEdgeInsets insets = self.scrollView.contentInset;
        insets.top += self.extendInsets.top;
        CGPoint contentOffset = self.scrollView.contentOffset;
        self.scrollView.contentInset = insets;
        self.scrollView.contentOffset = contentOffset;
    }
}

- (void)shrinkExtendedTopInsetsWith:(void(^)(BOOL finished))completion {
    if (self.isHeader == NO) {
        return;
    }
    //escape a runloop time in order to waiting for contentSize set firstly
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isExtendedContentInsetsForHeaderHover) {
            LXRFMethodDebug
            self.isExtendedContentInsetsForHeaderHover = NO;
            UIEdgeInsets insets = self.scrollView.contentInset;
            insets.top -= self.extendInsets.top;
            //animation
            CGPoint originalOffset = self.scrollView.contentOffset;
            self.scrollView.contentInset = insets;
            CGPoint toOffset = self.scrollView.contentOffset;
            self.scrollView.contentOffset = originalOffset;
            [UIView animateWithDuration:CATransaction.animationDuration animations:^{
                self.scrollView.contentOffset = toOffset;
            } completion:completion];
        }
    });
}

- (void)extendInsetsForFooterHover {
    if (!self.isFooter) {
        return;
    }
    BOOL shouldExtend = NO;
    if (self.isFullScreen) {
        shouldExtend = (self.scrollView.contentOffset.y + self.scrollView.bounds.size.height) >= self.statusMetric.refreshMetric;
        if (self.footerRefreshTriggeredWithoutPull) {
            shouldExtend = YES;
        }
    }
    if (!shouldExtend) {
        return;
    }
    if (self.isExtendedContentInsetsForFooterHover == NO) {
        LXRFMethodDebug
        self.isExtendedContentInsetsForFooterHover = YES;//ensure call before self.scrollView.contentInset = insets;
        UIEdgeInsets insets = self.scrollView.contentInset;
        insets.bottom += self.extendInsets.bottom;
        CGPoint contentOffset = self.scrollView.contentOffset;
        self.scrollView.contentInset = insets;
        self.scrollView.contentOffset = contentOffset;
    }
}

- (void)shrinkExtendedBottomInsetsWith:(void(^)(BOOL finished))completion {
    if (self.isFooter == NO || !self.isFullScreen) {
        completion ? completion(YES) : (void)0;
        return;
    }
    if (self.isExtendedContentInsetsForFooterHover) {
        LXRFMethodDebug
        self.isExtendedContentInsetsForFooterHover = NO;
        UIEdgeInsets insets = self.scrollView.contentInset;
        insets.bottom -= self.extendInsets.bottom ;
        CGPoint originalOffset = self.scrollView.contentOffset;
        self.scrollView.contentInset = insets;
        CGPoint targetOffset = self.scrollView.contentOffset;
        self.scrollView.contentOffset = originalOffset;
        [UIView animateWithDuration:CATransaction.animationDuration animations:^{
            self.scrollView.contentOffset = targetOffset;
        } completion:completion];
    }
}

- (void)detectPullingToRefreshing:(NSValue *)newValue {
    CGFloat offset_y = newValue.CGPointValue.y;
    if (self.isHeader && self.scrollView.isDragging) {
        CGFloat total = self.statusMetric.startMetric - self.statusMetric.refreshMetric;
        if (offset_y <= self.statusMetric.refreshMetric) {
            [self super_onPullingToRefreshing:1.f];
        } else if (offset_y < self.statusMetric.startMetric) {
            CGFloat pullDelta = self.statusMetric.startMetric - offset_y;
            [self super_onPullingToRefreshing:(pullDelta / total)];
        }
    }
    
    if (self.isFooter && self.scrollView.isDragging) {
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
    static CGFloat total;
    if (self.scrollViewIsTracking == NO     &&
        self.velocityWhenFingerUp.y >= 0.f  &&
        self.isHeader) {
        CGFloat offset_y = newValue.CGPointValue.y;
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
    if (self.velocityWhenFingerUp.y <= 0.f  &&
        self.scrollViewIsTracking == NO     &&
        self.isFooter) {
        CGFloat offset_y = newValue.CGPointValue.y;
        if (self.isFullScreen) {
            offset_y += self.scrollView.bounds.size.height;
        } else {
            offset_y += self.scrollView.contentSize.height;
        }
        if (self.viewStatus == LXRefreshStatusPullingToRefresh) {
            if (offset_y >= self.statusMetric.refreshMetric) {
                if (self.isFullScreen) {
                    total = offset_y - self.statusMetric.refreshMetric;
                } else {
                    total = offset_y - self.statusMetric.startMetric;
                }
                [self super_onViewStatusBecomingToRefreshing:total OffsetY:offset_y];
            } else if (offset_y > self.statusMetric.startMetric) {
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
}

- (void)scrollTo:(CGFloat)position_y animated:(BOOL)animated {
    CGPoint contentOffset = self.scrollView.contentOffset;
    contentOffset.y = position_y;
    [self.scrollView setContentOffset:contentOffset animated:animated];
}

- (void)didEndScrolling {
    LXRFMethodDebug
    if (self.enable == NO) {
        return;
    }
    if (self.isHeader) {
        CGFloat contentOffset = self.scrollView.contentOffset.y;
        if (contentOffset == self.statusMetric.refreshMetric) {
            [self super_onViewStatusRefreshing];
        } else if (contentOffset < self.statusMetric.startMetric && contentOffset > self.statusMetric.refreshMetric) {
            [self endUIRefreshing];
        } else if (contentOffset == self.statusMetric.startMetric) {
            [self super_onViewStatusIdle];
        }
    } else if (self.isFooter) {
        if (self.isFullScreen) {
            CGFloat contentOffset = self.scrollView.contentOffset.y + self.scrollView.bounds.size.height;
            if (contentOffset == self.statusMetric.refreshMetric) {
                [self super_onViewStatusRefreshing];
            } else if (contentOffset > self.statusMetric.startMetric && contentOffset < self.statusMetric.refreshMetric) {
                [self endUIRefreshing];
            } else if (contentOffset == self.statusMetric.startMetric) {
                [self super_onViewStatusIdle];
            }
        } else if (self.viewStatus == LXRefreshStatusRefreshing) {
            [self super_onViewStatusRefreshing];
        } else  {
            [self endUIRefreshing];
        }
    }
}

@end
#undef LXRFMethodDebug
#undef kShrinkAnimationDuration
