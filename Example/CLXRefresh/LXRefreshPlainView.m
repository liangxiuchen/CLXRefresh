//
//  LXRefreshPlainView.m
//  CLXRefresh_Example
//
//  Created by liangxiu chen on 2019/1/16.
//  Copyright © 2019 liangxiuchen. All rights reserved.
//

#import "LXRefreshPlainView.h"

@interface LXRefreshPlainView()

@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

@end

@implementation LXRefreshPlainView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.indicator.hidesWhenStopped = NO;
}

- (void)onViewStatusRefreshing:(LXRefreshViewStatus)oldStatus {
    self.tipLabel.text = @"refreshing";
    [self.indicator startAnimating];
}

- (void)onViewStatusIdle:(LXRefreshViewStatus)oldStatus {
    self.alpha = 0.f;
    self.indicator.hidden = NO;
    if (self.isHeader) {
        self.tipLabel.text = @"pull down to refresh";
    }
    if (self.isFooter) {
        self.tipLabel.text = @"pull up to refresh";
    }
    [self.indicator stopAnimating];
}

- (void)onPullingToRefreshing:(CGFloat)percent {
    if (self.isRefreshing) {
        self.alpha = 1.f;
    } else {
        self.alpha = percent;
    }
    if (percent >= 1.f) {
        self.tipLabel.text = @"relase to refresh";
    } else {
        if (self.isHeader) {
            self.tipLabel.text = @"pull down to refresh";
        }
        if (self.isFooter) {
            self.tipLabel.text = @"pull up to refresh";
        }
    }
}


@end
