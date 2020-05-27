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

- (void)onIdle {
    if (self.isHeader) {
        self.tipLabel.text = @"pull down to refresh";
    }
    if (self.isFooter) {
        self.tipLabel.text = @"pull up to refresh";
    }
    [self.indicator stopAnimating];
}

- (void)onRefreshing {
    self.tipLabel.text = @"refreshing";
    [self.indicator startAnimating];
}

- (void)onPullingWithPercent:(NSUInteger)percent {
    if (percent == 100) {
        self.tipLabel.text = @"relase to refresh";
    } else {
        if (self.isHeader) {
            self.tipLabel.text = @"pull down to refresh";
        } else if (self.isFooter) {
            self.tipLabel.text = @"pull up to refresh";
        }
    }
}

- (void)onFinalized {
    self.tipLabel.text = @"this is the limited line";
    self.indicator.hidden = YES;
    [self.tipLabel sizeToFit];
    CGRect bounds = self.bounds;
    bounds.size.width = self.tipLabel.bounds.size.width;
    self.bounds = bounds;
}


@end
