//
//  UIScrollView+LXInternal.m
//  iZipow
//
//  Created by carroll chen on 2019/5/15.
//  Copyright © 2019 Zoom Video Communications, Inc. All rights reserved.
//

#import "UIScrollView+LXInternal.h"
#import "LXScrollViewDelegateProxy.h"
#import <objc/runtime.h>
static const void *const proxyKey = &proxyKey;
@implementation UIScrollView (LXInternal)

- (LXScrollViewDelegateProxy *)lx_delegate {
    return objc_getAssociatedObject(self, proxyKey);
}

- (void)setLx_delegate:(LXScrollViewDelegateProxy *)lx_delegate {
    objc_setAssociatedObject(self, proxyKey, lx_delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
