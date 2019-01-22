//
//  LXViewController.m
//  CLXRefresh
//
//  Created by liangxiuchen on 01/16/2019.
//  Copyright (c) 2019 liangxiuchen. All rights reserved.
//

#import "LXTableViewController.h"
#import "LXRefreshPlainView.h"
#import "LXRefreshGifView.h"
#import <CLXRefresh/UIScrollView+LXRefresh.h>

@interface LXTableViewController ()<UITableViewDelegate>

@property (strong, nonatomic) IBOutlet LXRefreshGifView *header;
@property (strong, nonatomic) IBOutlet LXRefreshPlainView *footer;
@property (strong, nonatomic) NSMutableArray *dataSource;

@end

@implementation LXTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initDataSource];
    if (@available (iOS 11, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    } else {
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    __weak __typeof(self) wself = self;
    self.footer.refreshHandler = ^(LXRefreshBaseView * _Nonnull footer) {
        __strong __typeof(self) self = wself;
        if (self == nil) {
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.dataSource.count > 10) {
                [footer footerHasNoMoreData];
                [footer endRefreshing];
            } else {
               [self loadMoreData];
                [footer endRefreshing];
                [self.tableView reloadData];
            }
        });
    };
    self.header.refreshHandler = ^(LXRefreshBaseView * _Nonnull header) {
        __strong __typeof(self) self = wself;
        if (self == nil) {
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [header endRefreshing];
            [self.tableView reloadData];
        });
    };
    
    [self.header.tipLabel sizeToFit];
    CGFloat extendTop = self.header.bounds.size.height - self.header.tipLabel.bounds.size.height;
    self.header.extendInsets = (UIEdgeInsets){extendTop,0.f,0.f,0.f};
    
    self.tableView.lx_refreshHeaderView = self.header;
    self.tableView.lx_refreshHeaderView.isDebug = YES;
    
    self.tableView.lx_refreshFooterView = self.footer;
    self.tableView.lx_refreshFooterView.isDebug = YES;
    self.tableView.lx_refreshFooterView.resetNoMoreDataAfterEndRefreshing = NO;

    self.tableView.tableFooterView = [UIView new];
}

- (void)initDataSource {
    self.dataSource = [NSMutableArray array];
    for (NSInteger i = 0; i < 8; i++) {
        [self.dataSource addObject:[NSObject new]];
    }
}

- (void)loadMoreData {
    for (NSInteger i = 0; i < 3; i++) {
        [self.dataSource addObject:[NSObject new]];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.textLabel.text = @"1232";
    return cell;
}

@end
