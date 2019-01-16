//
//  LXViewController.m
//  CLXRefresh
//
//  Created by liangxiuchen on 01/16/2019.
//  Copyright (c) 2019 liangxiuchen. All rights reserved.
//

#import "LXViewController.h"
#import "LXRefreshPlainView.h"
#import "LXRefreshGifView.h"
@import CLXRefresh;

@interface LXViewController ()<UITableViewDelegate>

@property (strong, nonatomic) IBOutlet LXRefreshGifView *header;
@property (strong, nonatomic) IBOutlet LXRefreshPlainView *footer;

@end

@implementation LXViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
            [footer endRefreshing];
            [self.tableView reloadData];
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
    self.tableView.lx_refreshFooterView.isDebug = NO;
    
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 60.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.textLabel.text = @"1232";
    return cell;
}



@end
