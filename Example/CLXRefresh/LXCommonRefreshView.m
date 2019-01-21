//
//  LXCommonRefreshHeader.m
//  rfreshTest
//
//  Created by kunpo on 2019/1/21.
//  Copyright © 2019 kunpo. All rights reserved.
//

#import "LXCommonRefreshView.h"

@interface LXCommonRefreshView()

@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@end

@implementation LXCommonRefreshView

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self config];
        self.loadingDescription = @"正在获取数据...";
        self.headerPullToRefreshDescription = @"下拉刷新数据";
        self.footerPullToRefreshDescription = @"上拉加载更多";
        self.headerReleaseToRefreshDescription = @"松开刷新数据";
        self.footerReleaseToRefreshDescription = @"松开加载更多";
        self.footerNomoreDataDescription = @"没有更多数据";
    }
    return self;
}

- (void)config {
    CGFloat width = UIScreen.mainScreen.bounds.size.width;
    self.frame = CGRectMake(0, 0, width, 50.0);
    self.title = [[UILabel alloc] initWithFrame:CGRectMake(0, 25.0, width, 25.0)];
    self.title.textAlignment = NSTextAlignmentCenter;
    self.title.textColor = [UIColor lightGrayColor];
    [self addSubview:self.title];
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    CGRect frame = CGRectMake((width - 20.0) / 2.0, 5.0, 20.0, 20.0);
    self.indicator.frame = frame;
    self.indicator.hidesWhenStopped = YES;
    [self addSubview:self.indicator];
}

//MARK: LXRefreshViewSubclassProtocol

- (void)onViewStatusRefreshing:(LXRefreshViewStatus)oldStatus {
    self.title.text = self.loadingDescription;
    [self.indicator startAnimating];
}

- (void)onViewStatusIdle:(LXRefreshViewStatus)oldStatus {
    self.alpha = 0.0;
    [self.indicator stopAnimating];
}

- (void)onPullingToRefreshing:(CGFloat)percent {
    if (self.isRefreshing) {
        self.alpha = 1.f;
    } else {
        self.alpha = percent;
    }
    
    NSString *pullToRefreshDescription = self.headerPullToRefreshDescription;
    NSString *releaseToRefreshDescription = self.headerReleaseToRefreshDescription;
    if (self.isFooter) {
        pullToRefreshDescription = self.footerPullToRefreshDescription;
        releaseToRefreshDescription = self.footerReleaseToRefreshDescription;
    }
    if (percent >= 1.f) {
        self.title.text = releaseToRefreshDescription;
    } else {
        self.title.text = pullToRefreshDescription;
    }
}

@end
