//
//  LXRefreshBaseView+footer.h
//  CLXRefresh_Example
//
//  Created by kunpo on 2019/1/23.
//  Copyright © 2019 liangxiuchen. All rights reserved.
//

#import "LXRefreshBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LXRefreshBaseView (footer)

/**停止刷新且没有更多数据(再修改状态之前上拉不会再调用block)*/
- (void)endRefreshingWithNoMoreData;
/**重置没有更多的数据（消除没有更多数据的状态）*/
- (void)resetNoMoreData;

@end

NS_ASSUME_NONNULL_END
