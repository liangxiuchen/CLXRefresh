//
//  LXRefreshGifView.h
//  CLXRefresh_Example
//
//  Created by liangxiu chen on 2019/1/16.
//  Copyright © 2019 liangxiuchen. All rights reserved.
//
#import "LXRefreshBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LXRefreshGifView : LXRefreshBaseView<LXRefreshViewProtocol>

@property (readonly, nonatomic, weak) UILabel *tipLabel;
@property (readonly, nonatomic, weak) UIImageView *refreshGIF;

@end

NS_ASSUME_NONNULL_END
