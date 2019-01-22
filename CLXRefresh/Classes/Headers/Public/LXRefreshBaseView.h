//
//  LXRefreshView.h
//  LXSIPRefresh
//
//  Created by liangxiu chen on 2019/1/4.
//  Copyright © 2019 liangxiu chen. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LXRefreshViewStatus) {
    LXRefreshStatusInit,
    LXRefreshStatusIdle,
    LXRefreshStatusBecomingToIdle,//is scrolling to idle
    LXRefreshStatusPullingToRefresh,
    LXRefreshStatusBecomingToRefreshing,//finger is upped & will trigger refresh
    LXRefreshStatusRefreshing //is refreshing, refreshHanlder called at this moment
};

typedef NS_ENUM(NSUInteger, LXRefreshLogicStatus) {
    LXRefreshLogicStatusNormal,
    LXRefreshLogicStatusRefreshing,
    LXRefreshLogicStatusRefreshFinished,
    LXRefreshLogicStatusNoMoreData
};

//this metric is used to detect when can refresh
typedef struct {
    CGFloat startMetric;//this metric in scrollView visible rect, means refresh view will appear
    CGFloat refreshMetric;//this metric in scrollView visible rect, means refresh view is full appear to refreshing
} LXRefreshViewMetric;

@class LXRefreshBaseView;
typedef void (^LXRefreshHandler)(LXRefreshBaseView *);

@interface LXRefreshBaseView : UIView

@property (nonatomic, readonly) LXRefreshViewStatus viewStatus;
@property (nonatomic, readonly) LXRefreshLogicStatus logicStatus;
@property (nonatomic, assign) BOOL isDebug;
@property (nonatomic, assign) BOOL isAlwaysTriggerRefreshHandler;
@property (nonatomic, assign) BOOL isAutoPosition;//default is YES you just specify view's bouds, horizontally center
@property (nonatomic, readonly) BOOL isRefreshing;//YES when business logic is refreshing or UI also in refreshing, otherwise NO
@property (nonatomic, readonly) BOOL isHeader;
@property (nonatomic, readonly) BOOL isFooter;
@property (nonatomic, readonly) BOOL isNoMoreData;
@property (nonatomic, assign) BOOL resetNoMoreDataAfterEndRefreshing;
@property (nonatomic, assign) UIEdgeInsets userAdditionalInsets;
@property (nonatomic, assign) UIEdgeInsets extendInsets;//default is view's height, extend space for header or footer hover
@property (nonatomic, assign) LXRefreshViewMetric statusMetric;//default value header is {CGRectGetMaxY(self.frame), self.frame.origin.y}, footer is {self.frame.origin.y, CGRectGetMaxY(self.frame)}.
@property (nonatomic, readonly) UIEdgeInsets systemInsets;

@property (nonatomic, nullable, copy) LXRefreshHandler refreshHandler;

- (instancetype)initWithFrame:(CGRect)frame RefreshHandler:(LXRefreshHandler)handler;
- (void)endRefreshing;
- (void)beginHeaderRefresh;
- (void)footerHasNoMoreData;

@end

#pragma mark -
#pragma mark - subclass protocol
@protocol LXRefreshViewSubclassProtocol<NSObject>

@optional
- (void)onViewStatusRefreshing:(LXRefreshViewStatus)oldStatus;

- (void)onViewStatusIdle:(LXRefreshViewStatus)oldStatus;

@optional
- (void)onContentOffsetChanged:(CGPoint)newValue oldOffset:(CGPoint)oldValue;

- (void)onIsTrackingChanged:(BOOL)newValue oldIsTracking:(BOOL)oldValue;

@optional
- (void)onContentInsetChanged:(UIEdgeInsets)insets;

@optional
//dragging to refreshing, finger is always on screen
- (void)onPullingToRefreshing:(CGFloat)percent;
//released to refreshing
- (void)onBecomingToRefreshing:(CGFloat)percent;
//released to idle
- (void)onBecomingToIdle:(CGFloat)percent;

@optional
- (void)onNoMoreData;

@end

NS_ASSUME_NONNULL_END
