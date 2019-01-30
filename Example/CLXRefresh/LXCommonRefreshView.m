//
//  LXCommonRefreshHeader.m
//  rfreshTest
//
//  Created by kunpo on 2019/1/21.
//  Copyright © 2019 kunpo. All rights reserved.
//

#import "LXCommonRefreshView.h"

@interface LXCommonRefreshView()

@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@property (nonatomic, copy) NSString *headerPullToRefreshDescription;
@property (nonatomic, copy) NSString *footerPullToRefreshDescription;
@property (nonatomic, copy) NSString *headerReleaseToRefreshDescription;
@property (nonatomic, copy) NSString *footerReleaseToRefreshDescription;
@property (nonatomic, copy) NSString *footerNomoreDataDescription;

@end

@implementation LXCommonRefreshView

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _title = [[UILabel alloc] init];
        [self config];
        [self configDescription];
    }
    return self;
}

- (void)config {
    CGFloat width = UIScreen.mainScreen.bounds.size.width;
    self.frame = CGRectMake(0, 0, width, 50.0);
    self.title.frame = CGRectMake(0, 25.0, width, 25.0);
    self.title.textAlignment = NSTextAlignmentCenter;
    self.title.textColor = [UIColor lightGrayColor];
    [self addSubview:self.title];
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    CGRect frame = CGRectMake((width - 20.0) / 2.0, 5.0, 20.0, 20.0);
    self.indicator.frame = frame;
    self.indicator.hidesWhenStopped = YES;
    [self addSubview:self.indicator];
}

- (void)configDescription {
    self.loadingDescription = @"正在获取数据...";
    self.headerPullToRefreshDescription = @"下拉刷新数据";
    self.footerPullToRefreshDescription = @"上拉加载更多";
    self.headerReleaseToRefreshDescription = @"松开刷新数据";
    self.footerReleaseToRefreshDescription = @"松开加载更多";
    self.footerNomoreDataDescription = @"没有更多数据";
}

- (instancetype)initWithFrame:(CGRect)frame RefreshHandler:(LXRefreshHandler)handler {
    self = [self init];
    if (self) {
        self.refreshHandler = handler;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self init];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _title = [[UILabel alloc] init];
        [self config];
        [self configDescription];
    }
    return self;
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
    if (self.isNoMoreData) {
        self.alpha = 1.f;
        return;
    } else if (self.isRefreshing) {
        self.alpha = 1.f;
    } else {
        self.alpha = percent;
    }
    
    NSString *pullToRefreshDescription = nil;
    NSString *releaseToRefreshDescription = nil;
    if (self.pullToRefreshDescription) {
        pullToRefreshDescription = self.pullToRefreshDescription;
    } else {
        if (self.isFooter) {
            pullToRefreshDescription = self.footerPullToRefreshDescription;
        } else {
            pullToRefreshDescription = self.headerPullToRefreshDescription;
        }
    }
    if (self.releaseToRefreshDescription) {
        releaseToRefreshDescription = self.releaseToRefreshDescription;
    } else {
        if (self.isFooter) {
            releaseToRefreshDescription = self.footerReleaseToRefreshDescription;
        } else {
            releaseToRefreshDescription = self.headerReleaseToRefreshDescription;
        }
    }
    if (percent >= 1.f) {
        self.title.text = releaseToRefreshDescription;
    } else {
        self.title.text = pullToRefreshDescription;
    }
}

- (void)onNoMoreData {
    self.title.text = self.nomoreDataDescription != nil ? self.nomoreDataDescription :  self.footerNomoreDataDescription;
    self.indicator.hidden = YES;
}

@end
