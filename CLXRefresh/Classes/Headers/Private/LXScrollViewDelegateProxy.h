//
//  LXScrollViewDelegateProxy.h
//  iZipow
//
//  Created by carroll chen on 2019/5/15.
//  Copyright © 2019 Zoom Video Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LXScrollViewDelegateProxy : NSProxy<UIScrollViewDelegate>

@property (nonatomic, weak, readonly) id host;
@property (nonatomic, weak, readonly) UIScrollView *scrollView;

+ (instancetype)delegateProxyWithHost:(id)host ScrollView:(UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END
