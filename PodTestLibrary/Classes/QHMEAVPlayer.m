//
//  QHMEAVPlayer.m
//  QHQuickEdit
//
//  Created by wangjian on 2018/5/3.
//  Copyright © 2018年 QHQuickEdit. All rights reserved.
//

#import "QHMEAVPlayer.h"

@interface QHMEAVPlayer ()

/** 播放器 */
@property (nonatomic, strong) AVPlayer *player;
/** 视频资源 */
@property (nonatomic, strong) AVPlayerItem *currentItem;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) id            playerTimeObserver;

@property (nonatomic, assign) NSTimeInterval endTime;

@end

@implementation QHMEAVPlayer

- (instancetype)init
{
    if (self = [super init]) {
        self.endTime = MAXFLOAT;
    }
    return self;
}

#pragma mark - 属性和方法
- (NSTimeInterval)totalTime
{
    return CMTimeGetSeconds(self.player.currentItem.asset.duration) *  NSEC_PER_USEC;
}

- (NSTimeInterval)currentTime{
    return CMTimeGetSeconds(self.player.currentTime) * NSEC_PER_USEC;
}

- (void)play
{
    if (self.player.timeControlStatus == AVPlayerTimeControlStatusPaused) {
        [self.player play];
    }
}

- (void)pause
{
    if (self.player.timeControlStatus == AVPlayerTimeControlStatusPlaying ||self.player.timeControlStatus == AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate) {
        [self.player pause];
    }
}

- (void)playBetweenBeginTime:(NSTimeInterval)beginTime
                     endTime:(NSTimeInterval)endTime
                        rate:(CGFloat)rate{
    self.endTime = endTime;
    [self.player seekToTime:CMTimeMakeWithSeconds(beginTime / NSEC_PER_USEC, self.player.currentItem.asset.duration.timescale) toleranceBefore:CMTimeMake(1, 1000) toleranceAfter:CMTimeMake(1, 1000)];
    [self.player playImmediatelyAtRate:rate];
}

- (void)addTimeObserver{
    @weakify(self);
    self.playerTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1000) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        @strongify(self);
        float currentTime = CMTimeGetSeconds(time) * NSEC_PER_USEC;
        DDLogDebug(@"select photo currentTime = %f, duration == %f", currentTime, self.endTime);
        if (currentTime >= (self.endTime - 0.01)) {
            [self pause];
            [self.player seekToTime:CMTimeMake(0, 1)];
            SAFE_BLOCK(self.playStopBlock);
            currentTime = self.endTime;
            self.endTime = self.totalTime;
        }
        SAFE_BLOCK(self.playProgressBlock, currentTime);
    }];
}

- (void)setupPlayerContentWith:(AVPlayerItem *)item
{
    self.currentItem = item;
    if (self.player) {
        // 先暂停当前的并移除旧的通知
        [self pause];
        [self removeNotification];
        
        // 替换当前显示的
        [self.player replaceCurrentItemWithPlayerItem:item];
    }else{
        // 第一次创建
        self.player = [AVPlayer playerWithPlayerItem:self.currentItem];
        [self addTimeObserver];
    }
    // 添加通知
    self.endTime = self.totalTime;
    [self addNotificatonForPlayer];
    
    /**
     创建播放器 layer 层
     AVPlayerLayer的videoGravity属性设置
     AVLayerVideoGravityResize,       // 非均匀模式。两个维度完全填充至整个视图区域
     AVLayerVideoGravityResizeAspect,  // 等比例填充，直到一个维度到达区域边界
     AVLayerVideoGravityResizeAspectFill, // 等比例填充，直到填充满整个视图区域，其中一个维度的部分区域会被裁剪
     */
    if (!self.playerLayer) {
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.frame = self.bounds;
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self.layer addSublayer:self.playerLayer];
    }
}

#pragma mark - 通知的回调
/** 视频异常中断 */
- (void)videoPlayError:(NSNotification *)notic
{
   
}

- (void)videoPlayResignActive:(NSNotification *)notic
{
    [self pause];
    SAFE_BLOCK(self.playResignActiveBlock);
}

- (void)videoPlayBecomeActive:(NSNotification *)notic
{
    SAFE_BLOCK(self.playBecomeActiveBlock);
}

#pragma mark - 添加通知
- (void)addNotificatonForPlayer
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(videoPlayError:) name:AVPlayerItemPlaybackStalledNotification object:nil];
    [center addObserver:self selector:@selector(videoPlayResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [center addObserver:self selector:@selector(videoPlayBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - 移除通知
/** 移除 通知 */
- (void)removeNotification
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
    [center removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [self.player replaceCurrentItemWithPlayerItem:nil];
}

#pragma mark -
- (void)removePlayerTimeObserver{
    if (!self.playerTimeObserver) {
        return;
    }
    [_player removeTimeObserver:_playerTimeObserver];
    _playerTimeObserver = nil;
}

- (void)dealloc
{
    [self removeNotification];
    [self removePlayerTimeObserver];
    DDLogDebug(@"QHMEAVPlayer dealloc");
}

@end
