//
//  LXRefreshView+Internal.h
//  LXSIPRefresh
//
//  Created by liangxiu chen on 2019/1/4.
//  Copyright © 2019 liangxiu chen. All rights reserved.
//

#import "LXRefreshBaseView.h"
//framework internal header, do not expose to user
NS_ASSUME_NONNULL_BEGIN
@interface LXRefreshBaseView()<UIScrollViewDelegate>

@property (nonatomic, assign) LXRefreshViewStatus viewStatus;
@property (nonatomic, assign) LXRefreshLogicStatus logicStatus;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) NSInteger pendingRefreshes;
@property (nonatomic, assign) BOOL scrollViewIsTracking;
@property (nonatomic, readonly) BOOL isFullScreen;
@property (nonatomic, assign) BOOL isExtendContentInsetsForHeaderHover;
@property (nonatomic, assign) BOOL isExtendContentInsetsForFooterHover;
@property (nonatomic, readonly, class) void *headerKVOContext;
@property (nonatomic, readonly, class) void *footerKVOContext;
@property (nonatomic, weak, nullable) id<UIScrollViewDelegate> realDelegate;

- (void)super_onContentInsetsChanged:(UIEdgeInsets)insets;
- (void)updateStatusMetric;//is used for auto position

@end
NS_ASSUME_NONNULL_END
