//
//  FZViewController2.m
//  FZMyLibiary_Example
//
//  Created by 吴福增 on 2019/8/16.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

#import "FZViewController2.h"
#import <AVFoundation/AVFoundation.h>
#import "LFGPUImageEmptyFilter.h"
#import "FSKGPUImageBeautyFilter.h"

@interface FZViewController2 ()
<
UICollectionViewDelegate,
UICollectionViewDataSource
>
//视频URL
@property (strong, nonatomic) NSURL *kj_videoUrl;

/** 播放源 */
@property (strong, nonatomic) AVPlayerItem *playerItem;
/** 视频原声播放器 */
@property (strong, nonatomic) AVPlayer *kj_player;
/** 待添加背景音乐播放器 */
@property (strong, nonatomic) AVPlayer *kj_musicPlayer;
/** 视频图像效果播放器，不支持声音 */
@property (strong, nonatomic) GPUImageMovie *kj_showMovie;
/** 视频效果呈现 */
@property (strong, nonatomic) GPUImageView *kj_filterView;
/** 视频效果滤镜 */
@property (strong, nonatomic) GPUImageOutput<GPUImageInput> *kj_filter;
/** 选中的背景音乐 */
@property (strong, nonatomic) NSDictionary *kj_selectedMusic;
/** 选中的滤镜数据 */
@property (strong, nonatomic) NSDictionary *kj_selectedFilter;

/** 滤镜数组 */
@property (strong, nonatomic) NSMutableArray *kj_filterArray;
/** 音乐数组 */
@property (strong, nonatomic) NSMutableArray *kj_musicArray;

/** 本地json数据 */
@property (strong, nonatomic) NSDictionary *kj_filterJson;

@end

@implementation FZViewController2
{
    GPUImageMovie *kj_movieComposition;
    GPUImageMovieWriter *kj_movieWriter;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
}

-(void)play{
    [self.kj_player replaceCurrentItemWithPlayerItem:self.playerItem];
    [self.kj_showMovie addTarget:self.kj_filter];
    [self.kj_filter addTarget:self.kj_filterView];
}
    


/** 本地视频合成滤镜 */
- (void)filterCompositionForFilter:(GPUImageOutput<GPUImageInput> *)filter
                      withVideoUrl:(NSURL *)videoUrl
                           outPath:(NSString *)outPath{
    if (videoUrl) {
        
        kj_movieComposition = [[GPUImageMovie alloc] initWithURL:videoUrl];
        kj_movieComposition.runBenchmark = YES;
        kj_movieComposition.playAtActualSpeed = NO;
        
        GPUImageOutput<GPUImageInput> *tmpFilter = filter;
        [kj_movieComposition addTarget:tmpFilter];
        
        //合成后的视频路径
        unlink([outPath UTF8String]);
        NSURL *tmpUrl = [NSURL fileURLWithPath:outPath];
        CGSize videoSize = self.kj_player.currentItem.presentationSize;
        NSUInteger a = [self kj_degressFromVideoFileWithURL:videoUrl];
        if (a == 90 || a == 270) {
            videoSize = CGSizeMake(videoSize.height, videoSize.width);
        }
        CGAffineTransform rotate = CGAffineTransformMakeRotation(a / 180.0 * M_PI );
        kj_movieWriter  = [[GPUImageMovieWriter alloc] initWithMovieURL:tmpUrl size:videoSize];
        kj_movieWriter.transform = rotate;
        kj_movieWriter.shouldPassthroughAudio = YES;
        kj_movieComposition.audioEncodingTarget = kj_movieWriter;
        /** 添加滤镜 */
        [tmpFilter addTarget:kj_movieWriter];
        
        [kj_movieComposition enableSynchronizedEncodingUsingMovieWriter:kj_movieWriter];
        /** 开始录制 */
        [kj_movieWriter startRecording];
        /** 开始处理 */
        [kj_movieComposition startProcessing];
        __weak __typeof(self) weakSelf = self;
        __weak GPUImageMovieWriter *weakmovieWriter = kj_movieWriter;
        [kj_movieWriter setCompletionBlock:^{
            NSLog(@"滤镜添加成功");
            [tmpFilter removeTarget:weakmovieWriter];
            [weakmovieWriter finishRecording];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.kj_selectedMusic) {
                    //替换视频配音
                } else {
                    //保存到相册
                }
            });
        }];
        [kj_movieWriter setFailureBlock:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"滤镜添加失败：%@", error);
                if ([[NSFileManager defaultManager] fileExistsAtPath:outPath]) {
                    NSError *delError = nil;
                    [[NSFileManager defaultManager] removeItemAtPath:outPath error:&delError];
                    if (delError) {
                        NSLog(@"删除沙盒路径失败：%@", delError);
                    }
                }
            });
        }];
    }
}



/**
 视频的旋转角度
 
 @param url 视频
 @return 角度
 */
- (NSUInteger)kj_degressFromVideoFileWithURL:(NSURL *)url {
    NSUInteger degress = 0;
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
    }
    return degress;
}

#pragma mark -- Lazy Func --

-(AVPlayerItem *)playerItem{
    if (_playerItem == nil) {
        _playerItem = [AVPlayerItem playerItemWithURL:self.kj_videoUrl];
    }
    return _playerItem;
}

-(AVPlayer *)kj_player{
    if (_kj_player == nil) {
        _kj_player = [[AVPlayer alloc] init];
    }
    return _kj_player;
}
-(AVPlayerLayer *)playerLayer{
    if (_playerLayer == nil) {
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.kj_player];
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _playerLayer.frame = CGRectMake(0,
                                        0,
                                        [UIScreen mainScreen].bounds.size.width,
                                        [UIScreen mainScreen].bounds.size.width);
        [self.view.layer insertSublayer:_playerLayer atIndex:0];
    }
    return _playerLayer;
}


-(GPUImageView *)kj_filterView{
    if (_kj_filterView == nil) {
        _kj_filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0,
                                                                        0,
                                                                        [UIScreen mainScreen].bounds.size.width,
                                                                        [UIScreen mainScreen].bounds.size.width)];
        [self.view addSubview:_kj_filterView];
        CGAffineTransform rotate = CGAffineTransformMakeRotation([self kj_degressFromVideoFileWithURL:self.kj_videoUrl] / 180.0 * M_PI );
        _kj_filterView.transform = rotate;
        [self.kj_filter addTarget:_kj_filterView];
        [self.view bringSubviewToFront:_kj_filterView];
        
    }
    return _kj_filterView;
}

-(GPUImageMovie *)kj_showMovie{
    if (_kj_showMovie == nil) {
        _kj_showMovie = [[GPUImageMovie alloc] initWithPlayerItem:self.playerItem];
        /**
         * 这使当前视频处于基准测试的模式，记录并输出瞬时和平均帧时间到控制台
         * 每隔一段时间打印： Current frame time : 51.256001 ms，
         * 直到播放或加滤镜等操作完毕
         */
        _kj_showMovie.runBenchmark = YES; //启用了基准测试模式
        /**
         * 控制GPUImageView预览视频时的速度是否要保持真实的速度。
         * 如果设为NO，则会将视频的所有帧无间隔渲染，导致速度非常快。
         * 设为YES，则会根据视频本身时长计算出每帧的时间间隔，
         * 然后每渲染一帧，就sleep一个时间间隔，从而达到正常的播放速度。
         */
        _kj_showMovie.playAtActualSpeed = YES;//滤镜渲染方式
        //是否循环播放
        _kj_showMovie.shouldRepeat = YES;//是否循环播放
        
        
    }
    return _kj_showMovie;
}

-(GPUImageOutput<GPUImageInput> *)kj_filter{
    if (_kj_filter == nil) {
        //正常滤镜
        LFGPUImageEmptyFilter *filter = [[LFGPUImageEmptyFilter alloc] init];
        _kj_filter = filter;
    }
    return _kj_filter;
}


@end
