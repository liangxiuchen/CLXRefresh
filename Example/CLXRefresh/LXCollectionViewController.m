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
@property (strong, nonatomic) NSMutableArray<NSMutableArray *> *dataSource;

@end

@implementation LXCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    ((UICollectionViewFlowLayout *)self.collectionViewLayout).sectionHeadersPinToVisibleBounds = YES;
    [self initDataSource];
    if (@available (iOS 11, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    } else {
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    __weak __typeof(self) wself = self;
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
    
    self.footer.refreshHandler = ^(LXRefreshBaseView * _Nonnull footer) {
        __strong __typeof(self) self = wself;
        if (self == nil) {
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self loadMoreData];
            [self.collectionView reloadData];
            [footer endRefreshing];
        });
    };
    
    [self.header.tipLabel sizeToFit];
    
    self.collectionView.lx_refreshHeaderView = self.header;
    self.collectionView.lx_refreshHeaderView.isDebug = YES;
    
    self.collectionView.lx_refreshFooterView = self.footer;
    self.collectionView.lx_refreshFooterView.isDebug = NO;
}

- (void)initDataSource {
    self.dataSource = [NSMutableArray array];
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = 0; i < 65; i++) {
        [array addObject:[NSObject new]];
    }
    [self.dataSource addObject:array];
}

- (void)loadMoreData {
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = 0; i < 65; i++) {
        [array addObject:[NSObject new]];
    }
    [self.dataSource addObject:array];
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
    return self.dataSource.count;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource[section].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    NSArray *colors = @[UIColor.redColor, UIColor.greenColor, UIColor.grayColor, UIColor.blueColor];
    NSUInteger count = (indexPath.row + indexPath.section) % colors.count;
    cell.backgroundColor = colors[count];
    // Configure the cell
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(self.collectionView.bounds.size.width, 30.0f);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass(UICollectionReusableView.class) forIndexPath:indexPath];
    view.backgroundColor = UIColor.redColor;
    return view;
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
