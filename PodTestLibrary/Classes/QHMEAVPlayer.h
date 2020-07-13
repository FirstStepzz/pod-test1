//
//  QHMEAVPlayer.h
//  QHQuickEdit
//
//  Created by wangjian on 2018/5/3.
//  Copyright © 2018年 QHQuickEdit. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PHAsset;

typedef NS_ENUM(NSInteger, QHMEAVPlayerPlaystate){
    QHMEAVPlayerPlaystateReady,  // 播放完成或者还没开始播放的准备状态
    QHMEAVPlayerPlaystatePlaying, // 正在播放
    QHMEAVPlayerPlaystatePause // 暂停状态
};

@interface QHMEAVPlayer : UIView

// 视频总长度
@property (nonatomic, assign) NSTimeInterval totalTime;
// 当前时间
@property (nonatomic, assign) NSTimeInterval currentTime;

@property (nonatomic, copy) void(^playResignActiveBlock)(void);
@property (nonatomic, copy) void(^playBecomeActiveBlock)(void);
@property (nonatomic, copy) void(^playStopBlock)(void);
@property (nonatomic, copy) void(^playProgressBlock)(NSTimeInterval currentTime);

/**
 播放
 */
- (void)play;

/**
 播放指定区间
 rate:播放速度
 */
- (void)playBetweenBeginTime:(NSTimeInterval)beginTime
                     endTime:(NSTimeInterval)endTime
                        rate:(CGFloat)rate;

/**
 暂停
 */
- (void)pause;

 /**
  初始化播放器更新当前视频item
  */
- (void)setupPlayerContentWith:(AVPlayerItem *)item;

@end
