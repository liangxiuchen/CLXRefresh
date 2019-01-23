//
//  LXCommonRefreshHeader.h
//  rfreshTest
//
//  Created by kunpo on 2019/1/21.
//  Copyright © 2019 kunpo. All rights reserved.
//

#import "LXRefreshBaseView.h"
#import "LXRefreshBaseView+footer.h"

NS_ASSUME_NONNULL_BEGIN

@interface LXCommonRefreshView : LXRefreshBaseView <LXRefreshViewSubclassProtocol>

@property (nonatomic, copy) NSString *loadingDescription;
@property (nonatomic, copy) NSString *headerPullToRefreshDescription;
@property (nonatomic, copy) NSString *footerPullToRefreshDescription;
@property (nonatomic, copy) NSString *headerReleaseToRefreshDescription;
@property (nonatomic, copy) NSString *footerReleaseToRefreshDescription;
@property (nonatomic, copy) NSString *footerNomoreDataDescription;

@end

NS_ASSUME_NONNULL_END
