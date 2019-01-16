//
//  UIScrollView+ZMRefresh.h
//  ZMSIPRefresh
//
//  Created by liangxiu chen on 2019/1/4.
//  Copyright © 2019 liangxiu chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LXRefreshBaseView.h"
NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (CLXRefresh)

@property (nonatomic, assign) LXRefreshBaseView *lx_refreshHeaderView;
@property (nonatomic, assign) LXRefreshBaseView *lx_refreshFooterView;

@end

NS_ASSUME_NONNULL_END
