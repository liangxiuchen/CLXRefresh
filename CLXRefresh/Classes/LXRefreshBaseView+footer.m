//
//  LXRefreshBaseView+footer.m
//  CLXRefresh_Example
//
//  Created by kunpo on 2019/1/23.
//  Copyright © 2019 liangxiuchen. All rights reserved.
//

#import "LXRefreshBaseView+footer.h"

@implementation LXRefreshBaseView (footer)

- (void)endRefreshingWithNoMoreData {
    self.resetNoMoreDataAfterEndRefreshing = NO;
    [self footerHasNoMoreData];
    [self endRefreshing];
}
- (void)resetNoMoreData {
    self.resetNoMoreDataAfterEndRefreshing = YES;
    [self endRefreshing];
}

@end
