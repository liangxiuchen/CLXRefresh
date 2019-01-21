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
    LXCommonRefreshView *refreshHeader = [[LXCommonRefreshView alloc] init];
    __weak __typeof(self) wself = self;
    refreshHeader.refreshHandler = ^(LXRefreshBaseView * _Nonnull header) {
        __strong __typeof(self) self = wself;
        if (self == nil) {
            return;
        }
        [self refresh];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [header endRefreshing];
            [self.tableView reloadData];
        });
    };
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
        [self loadMore];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [footer endRefreshing];
            [self.tableView reloadData];
        });
    };
    self.tableView.lx_refreshFooterView = refreshFooter;
}

- (void)refresh {
    self.rowCount = 10;
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
