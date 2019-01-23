//
//  LXCommonRefreshHeader.h
//  rfreshTest
//
//  Created by kunpo on 2019/1/21.
//  Copyright © 2019 kunpo. All rights reserved.
//

#import "LXRefreshBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LXCommonRefreshView : LXRefreshBaseView <LXRefreshViewSubclassProtocol>

@property (nonatomic, copy) NSString *loadingDescription;
@property (nonatomic, copy) NSString *headerPullToRefreshDescription;
@property (nonatomic, copy) NSString *footerPullToRefreshDescription;
@property (nonatomic, copy) NSString *headerReleaseToRefreshDescription;
@property (nonatomic, copy) NSString *footerReleaseToRefreshDescription;
@property (nonatomic, copy) NSString *footerNomoreDataDescription;

/**停止刷新且没有更多数据*/
- (void)endRefreshingWithNoMoreData;
/**重置没有更多的数据（消除没有更多数据的状态）*/
- (void)resetNoMoreData;

@end

NS_ASSUME_NONNULL_END
