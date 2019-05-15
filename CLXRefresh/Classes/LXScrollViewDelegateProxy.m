//
//  LXScrollViewDelegateProxy.m
//  iZipow
//
//  Created by carroll chen on 2019/5/15.
//  Copyright © 2019 Zoom Video Communications, Inc. All rights reserved.
//

#import "LXScrollViewDelegateProxy.h"
#import "LXRefreshBaseView.h"
#import "LXRefreshBaseView+Internal.h"
#import "UIScrollView+LXRefresh.h"
#import <objc/runtime.h>

@implementation LXScrollViewDelegateProxy
- (void)dealloc {
    NSLog(@"");
}

- (instancetype)initWithHost:(id)host ScrollView:(UIScrollView *)scrollView {
    if (self) {
        _host = host;
        _scrollView = scrollView;
    }
    return self;
}

+ (instancetype)delegateProxyWithHost:(id)host ScrollView:(nonnull UIScrollView *)scrollView {
    return [[self alloc] initWithHost:host ScrollView:scrollView];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return _host;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (class_getInstanceMethod(self.class, aSelector)) {
        return YES;
    }
    return [_host respondsToSelector:aSelector];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return [_host conformsToProtocol:aProtocol];
}

/// Strangely, this method doesn't get forwarded by ObjC.
- (BOOL)isKindOfClass:(Class)aClass
{
    return [_host isKindOfClass:aClass];
}

- (NSString *)description
{
#if DEBUG
    return NSStringFromClass(self.class);
#else
    return [_host description];
#endif
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [_host methodSignatureForSelector:sel];
}
- (void)forwardInvocation:(NSInvocation *)invocation
{
    invocation.target = _host;
}

#pragma mark -
#pragma mark - Aspect methods
- (void)dispatchSelector:(SEL)sel execute:(void(^)(id<UIScrollViewDelegate> delegate))handler {
    if ([_host respondsToSelector:sel]) {
        handler ? handler(_host) : (void)0;
    }
}

// called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    //hook code
    if (decelerate == NO) {
        if (self.scrollView.lx_refreshHeaderView) {
            [self.scrollView.lx_refreshHeaderView didEndScrolling];
        }
        if (self.scrollView.lx_refreshFooterView) {
            [self.scrollView.lx_refreshFooterView didEndScrolling];
        }
    }
    [self dispatchSelector:@selector(scrollViewDidEndDragging:willDecelerate:) execute:^(id<UIScrollViewDelegate> delegate) {
        [delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }];
}

// called when scroll view grinds to a halt
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.scrollView.lx_refreshHeaderView) {
        [self.scrollView.lx_refreshHeaderView didEndScrolling];
    }
    if (self.scrollView.lx_refreshFooterView) {
        [self.scrollView.lx_refreshFooterView didEndScrolling];
    }
    
    [self dispatchSelector:@selector(scrollViewDidEndDecelerating:) execute:^(id<UIScrollViewDelegate> delegate) {
        [delegate scrollViewDidEndDecelerating:scrollView];
    }];
}

// return a yes if you want to scroll to the top. if not defined, assumes YES
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    BOOL should = NO;
    if ([_host respondsToSelector:_cmd]) {
        should = [_host scrollViewShouldScrollToTop:scrollView];
        if (self.scrollView.lx_refreshHeaderView && should) {
            //scroll to top
            LXRefreshBaseView *header = self.scrollView.lx_refreshHeaderView;
            CGPoint contentOffset = self.scrollView.contentOffset;
            contentOffset.y = header.statusMetric.startMetric;
            [self.scrollView setContentOffset:contentOffset animated:YES];
            should = NO;
        }
    }
    return should;
}

@end
