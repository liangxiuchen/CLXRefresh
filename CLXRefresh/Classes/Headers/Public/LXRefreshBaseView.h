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
    LXRefreshViewStatusInit,
    LXRefreshViewStatusIdle,
    LXRefreshViewStatusPulling,
    LXRefreshViewStatusReleaseToRefreshing,//finger is upped & will trigger refresh
    LXRefreshViewStatusRefreshing //is refreshing, refreshHanlder called at this moment
};

typedef NS_ENUM(NSUInteger, LXRefreshLogicStatus) {
    LXRefreshLogicStatusNormal, //one of async event is processed
    LXRefreshLogicStatusRefreshing,//async event is processing
    LXRefreshLogicStatusFinal //no async event to process
};

//this metric is used by component to detect when can refresh and add inset_top to ABS(refreshMetric - startMetric).
typedef struct {
    CGFloat startMetric;//this metric in scrollView visible rect, means refresh view will appear
    CGFloat refreshMetric;//this metric in scrollView visible rect, means refresh view is full appear to refreshing
} LXRefreshViewMetric;

@class LXRefreshBaseView;
typedef void (^LXRefreshHandler)(LXRefreshBaseView *);

@interface LXRefreshBaseView : UIView

@property (nonatomic, readonly) LXRefreshViewStatus viewStatus;
@property (nonatomic, readonly) LXRefreshLogicStatus logicStatus;
@property (nonatomic, readonly) BOOL isRefreshing;//YES when business logic is refreshing or UI also in refreshing
@property (nonatomic, readonly) BOOL isFinalized;
@property (nonatomic, readonly) BOOL isHeader;
@property (nonatomic, readonly) BOOL isFooter;
@property (nonatomic, assign) BOOL isDebug;
@property (nonatomic, assign, getter= isSmoothRefresh) BOOL smoothRefresh;//like wechat load history style
@property (nonatomic, assign) BOOL isAutoPosition;//default is YES you just specify view's bouds, horizontally center
@property (nonatomic, assign) LXRefreshViewMetric statusMetric;//if not auto position, you should provide it
@property (nonatomic, nullable, copy) LXRefreshHandler refreshHandler;

- (void)refresh;//pls ensure the method called after scrollView layout finished.
- (void)endRefreshing;
- (void)finalizeRefreshing;//no data to refresh,should end by this method

@end

#pragma mark -
#pragma mark - subclass protocol
@protocol LXRefreshSubclassProtocol <NSObject>

@optional
- (void)onIdle;

- (void)onPullingWithPercent:(NSUInteger)percent;//the value is 50 means 50%

- (void)onReleaseToRefreshing;

- (void)onRefreshing;

- (void)onFinalized;

@end

NS_ASSUME_NONNULL_END
