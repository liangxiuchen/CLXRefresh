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
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, assign) CGFloat extendedDeltaForHeaderHover;
@property (nonatomic, assign) CGFloat extendedDeltaForFooterHover;
@property (nonatomic, strong, nullable) UIPanGestureRecognizer *panGesture;

- (void)updateStatusMetric;//is used for auto position
@end
NS_ASSUME_NONNULL_END
