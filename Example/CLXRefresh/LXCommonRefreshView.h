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

@interface LXCommonRefreshView : LXRefreshBaseView <LXRefreshViewProtocol>

@property (nonatomic, strong, readonly) UILabel *title;

@property (nonatomic, copy) NSString *loadingDescription;
@property (nonatomic, copy) NSString *pullToRefreshDescription;
@property (nonatomic, copy) NSString *releaseToRefreshDescription;
@property (nonatomic, copy) NSString *nomoreDataDescription;

/**宽高分别不能小于20、50*/
- (instancetype)initWithFrame:(CGRect)frame;
/**宽高分别不能小于20、50*/
- (instancetype)initWithFrame:(CGRect)frame RefreshHandler:(LXRefreshHandler)handler;

@end

NS_ASSUME_NONNULL_END
