//
//  LXRefreshGifView.m
//  CLXRefresh_Example
//
//  Created by liangxiu chen 2019/1/16.
//  Copyright © 2019 liangxiuchen. All rights reserved.
//

#import "LXRefreshGifView.h"

@interface LXRefreshGifView()

@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet UIImageView *refreshGIF;
@property (strong, nonatomic) NSMutableArray<UIImage *> *progressImages;
@property (strong, nonatomic) NSMutableArray<UIImage *> *refreshingImages;

@end

@implementation LXRefreshGifView

- (void)awakeFromNib {
    [super awakeFromNib];
    //load Gif
    self.progressImages = [NSMutableArray arrayWithCapacity:60];
    for (NSUInteger i = 1; i<=60; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"dropdown_anim__000%zd", i]];
        [self.progressImages addObject:image];
    }
    self.refreshingImages = [NSMutableArray arrayWithCapacity:3];
    for (NSUInteger i = 1; i<=3; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"dropdown_loading_0%zd", i]];
        [self.refreshingImages addObject:image];
    }
    
}

- (void)onViewStatusIdle:(LXRefreshViewStatus)oldStatus {
    [self.refreshGIF stopAnimating];
}

- (void)onPullingToRefreshing:(CGFloat)percent {
    NSLog(@"------------%f", percent);
    [self.refreshGIF stopAnimating];
    NSInteger index = ceilf(59 * percent);
    if (index < self.progressImages.count) {
        self.refreshGIF.image = self.progressImages[index];
    }
}

- (void)onBecomingToRefreshing:(CGFloat)percent {
    if (percent == 0.f) {
        self.refreshGIF.animationImages = self.refreshingImages;
        self.refreshGIF.animationDuration = 0.5f;
        [self.refreshGIF startAnimating];
    }
}

@end
