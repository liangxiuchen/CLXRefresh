//
//  UIScrollView+LXInternal.h
//  iZipow
//
//  Created by carroll chen on 2019/5/15.
//  Copyright © 2019 Zoom Video Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LXScrollViewDelegateProxy.h"

NS_ASSUME_NONNULL_BEGIN
@interface UIScrollView (LXInternal)

@property (nonatomic, retain, nullable) LXScrollViewDelegateProxy *lx_delegate;

@end

NS_ASSUME_NONNULL_END
