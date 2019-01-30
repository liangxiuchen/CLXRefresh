//
//  LXRefreshPlainView.h
//  CLXRefresh_Example
//
//  Created by liangxiu chen on 2019/1/16.
//  Copyright © 2019 liangxiuchen. All rights reserved.
//

#import "LXRefreshBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LXRefreshPlainView : LXRefreshBaseView<LXRefreshViewProtocol>

@property (readonly, nonatomic, weak) UILabel *tipLabel;
@property (readonly, nonatomic, weak) UIActivityIndicatorView *indicator;

@end

NS_ASSUME_NONNULL_END
