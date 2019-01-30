//
//  KPCommonViewController.m
//  rfreshTest
//
//  Created by kunpo on 2019/1/21.
//  Copyright © 2019 kunpo. All rights reserved.
//

#import "LXCommonViewController.h"
#import <CLXRefresh/UIScrollView+LXRefresh.h>
#import "LXCommonRefreshView.h"

@interface LXCommonViewController () <UITableViewDataSource>

@property (nonatomic, assign) int rowCount;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation LXCommonViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configData];
    [self configTableView];
}

- (void)configData {
    self.rowCount = 10;
}

- (void)configTableView {
    [self configRefreshHeader];
    [self configRefreshFooter];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)configRefreshHeader {
//    LXCommonRefreshView *refreshHeader = [[LXCommonRefreshView alloc] initWithFrame:CGRectMake(0, 0, 320, 90)];
    LXCommonRefreshView *refreshHeader = [[LXCommonRefreshView alloc] init];
    __weak __typeof(self) wself = self;
    refreshHeader.refreshHandler = ^(LXRefreshBaseView * _Nonnull header) {
        __strong __typeof(self) self = wself;
        if (self == nil) {
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self refresh];
            [header endRefreshing];
            [self.tableView reloadData];
        });
    };
//    refreshHeader.pullToRefreshDescription = @"这里就是需要很多字来天聪的，不填充怎么能够让显示不出来呢，显示不出来了吧应该少时诵诗书所少时诵诗书";
    self.tableView.lx_refreshHeaderView = refreshHeader;
}

- (void)anotherConfigRefreshHeader {
    __weak __typeof(self) wself = self;
    LXCommonRefreshView *refreshHeader = [[LXCommonRefreshView alloc] initWithFrame:CGRectZero RefreshHandler:^(LXRefreshBaseView * _Nonnull header) {
        __strong __typeof(self) self = wself;
        if (self == nil) {
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self refresh];
            [header endRefreshing];
            [self.tableView reloadData];
        });
    }];
    self.tableView.lx_refreshHeaderView = refreshHeader;
}

- (void)configRefreshFooter {
    LXCommonRefreshView *refreshFooter = [[LXCommonRefreshView alloc] init];
    __weak __typeof(self) wself = self;
    refreshFooter.refreshHandler = ^ (LXRefreshBaseView * _Nonnull footer) {
        __strong __typeof(self) self = wself;
        if (self == nil) {
            return;
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.rowCount >= 20) {
                [footer endRefreshingWithNoMoreData];
            } else {
                [self loadMore];
                [footer endRefreshing];
                [self.tableView reloadData];
            }
        });
    };
    self.tableView.lx_refreshFooterView = refreshFooter;
}

- (void)refresh {
    self.rowCount = 10;
    [self.tableView.lx_refreshFooterView resetNoMoreData];
}

- (void)loadMore {
    self.rowCount += 5;
}

//MARK: UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = [NSString stringWithFormat:@"这是第%d行", (int)(indexPath.row)];
    return cell;
}

@end
