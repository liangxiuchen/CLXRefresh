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
#import "LXCollectionViewController.h"
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
    __weak __typeof(self) wself = self;
    self.footer.refreshHandler = ^(LXRefreshBaseView * _Nonnull footer) {
        __strong __typeof(self) self = wself;
        if (self == nil) {
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.dataSource.count > 15) {
                [footer finalizeRefreshing];
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [header endRefreshing];
            [self.tableView reloadData];
        });
    };
    
    [self.header.tipLabel sizeToFit];
    self.tableView.lx_refreshHeaderView = self.header;
    self.tableView.lx_refreshHeaderView.isDebug = YES;
    
    self.tableView.lx_refreshFooterView = self.footer;
    self.tableView.lx_refreshFooterView.isDebug = YES;

    self.tableView.tableFooterView = [UIView new];
    LXCollectionViewController* vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LXCollectionView"];
    UISearchController * searchController = [[UISearchController alloc] initWithSearchResultsController: vc];
    self.navigationItem.searchController = searchController;
}

- (void)initDataSource {
    self.dataSource = [NSMutableArray array];
    for (NSInteger i = 0; i < 8; i++) {
        [self.dataSource addObject:[NSObject new]];
    }
}

- (void)loadMoreData {
    for (NSInteger i = 0; i < 13; i++) {
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
