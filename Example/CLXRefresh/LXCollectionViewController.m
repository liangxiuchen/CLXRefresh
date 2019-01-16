//
//  LXCollectionViewController.m
//  CLXRefresh_Example
//
//  Created by carroll chen on 2019/1/16.
//  Copyright © 2019 liangxiuchen. All rights reserved.
//

#import "LXCollectionViewController.h"
#import "LXRefreshPlainView.h"
#import "LXRefreshGifView.h"
#import <CLXRefresh/UIScrollView+LXRefresh.h>
@interface LXCollectionViewController ()

@property (strong, nonatomic) IBOutlet LXRefreshGifView *header;
@property (strong, nonatomic) IBOutlet LXRefreshPlainView *footer;
@property (strong, nonatomic) NSMutableArray *dataSource;

@end

@implementation LXCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initDataSource];
    if (@available (iOS 11, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
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
            [self loadMoreData];
            [footer endRefreshing];
            [self.collectionView reloadData];
        });
    };
    self.header.refreshHandler = ^(LXRefreshBaseView * _Nonnull header) {
        __strong __typeof(self) self = wself;
        if (self == nil) {
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [header endRefreshing];
            [self.collectionView reloadData];
        });
    };
    
    [self.header.tipLabel sizeToFit];
    CGFloat extendTop = self.header.bounds.size.height - self.header.tipLabel.bounds.size.height;
    self.header.extendInsets = (UIEdgeInsets){extendTop,0.f,0.f,0.f};
    
    self.collectionView.lx_refreshHeaderView = self.header;
    self.collectionView.lx_refreshHeaderView.isDebug = YES;
    
    self.collectionView.lx_refreshFooterView = self.footer;
    self.collectionView.lx_refreshFooterView.isDebug = NO;
}


- (void)initDataSource {
    self.dataSource = [NSMutableArray array];
    for (NSInteger i = 0; i < 65; i++) {
        [self.dataSource addObject:[NSObject new]];
    }
}

- (void)loadMoreData {
    for (NSInteger i = 0; i < 10; i++) {
        [self.dataSource addObject:[NSObject new]];
    }
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    return cell;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
