//
//  FZRecordEncoder.m
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/18.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

/**
 音频属性： value不能直接使用"@()"封装，可能无法编码
 
 <1>AVNumberOfChannelsKey 通道数 1为单通道2为立体通道
 <2>AVSampleRateKey 采样率 一般用44100
 <3>AVLinearPCMBitDepthKey 比特率 一般设16  32
 <4>AVEncoderAudioQualityKey 质量
 <5>AVEncoderBitRateKey 比特采样率 一般是128000
 */


#import "FZRecordEncoder.h"

#import <Photos/Photos.h>

@interface FZRecordEncoder ()
/** 输出文件路径 */
@property (nonatomic,strong) NSString *path;
/** 写操作队列 */
@property (nonatomic,strong) dispatch_queue_t writeQueue;
/** 媒体写入对象 */
@property (nonatomic,strong,readonly) AVAssetWriter *writer;
/** 音频写入 */
@property (nonatomic,strong) AVAssetWriterInput *audioInput;
/** 视频写入 */
@property (nonatomic,strong) AVAssetWriterInput *videoInput;
/** 像素缓冲区输入适配器 */
@property (nonatomic,strong) AVAssetWriterInputPixelBufferAdaptor *inputPixelBufferAdaptor;
/** 写操作状态 */
@property (nonatomic,assign) FZWriteStatus writeStatus;

@end

@implementation FZRecordEncoder

#pragma mark -- Life Cycle Func ---------

- (instancetype)init{
    if (self = [super init]) {
        NSString *videoName = [FZRecordEncoder fileNameWithType:@"video" suffix:@"mp4"];
        NSString *videoPath = [[FZRecordEncoder VideoCachePath] stringByAppendingPathComponent:videoName];
        
//        NSFileManager* fileManager = [NSFileManager defaultManager];
//        if ([fileManager fileExistsAtPath:videoPath]) {
//            [fileManager removeItemAtPath:videoPath error:nil];
//        }
        self.path = videoPath;
    }
    return self;
}

-(void)dealloc{
    [self destroyWrite];
}

-(BOOL)creatWriter{
    [self destroyWrite];
    NSError *error;
    //先把路径下的文件给删除掉，保证录制的文件是最新的
    [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
    //初始化写入媒体类型为MP4类型
    _writer = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:self.path]
                                       fileType:AVFileTypeMPEG4
                                          error:&error];
    if (error) {
        return NO;
    }
    //使其更适合在网络上播放
    _writer.shouldOptimizeForNetworkUse = YES;
    if (self.videoDimensions.width == 0 ||
        self.videoDimensions.height == 0 ||
        self.channels == 0 ||
        self.samplerate == 0 ||
        self.inputPixelBufferAdaptor == nil) {
        return NO;
    }else{
        return YES;
    }
}



- (void)destroyWrite {
    if (_writer) {
        [_writer cancelWriting];//撤销输出文件
    }
    _writer = nil;
    _audioInput = nil;
    _videoInput = nil;
}

/** 准备写入 */
- (void)prepareWrite{ 
    if ([self.writer canAddInput:self.videoInput]) {
        [self.writer addInput:self.videoInput];
    }
    if ([self.writer canAddInput:self.audioInput]) {
        [self.writer addInput:self.audioInput];
    }
    @synchronized (self) {
        self.writeStatus = FZWriteStatusPrepare;
    }
}
/**
 完成视频录制
 */
- (void)stopWriteWithCompletionHandler:(nullable void(^)(BOOL success, NSError *__nullable error))handler {
    self.writeStatus = FZWriteStatusCompleted;
    dispatch_async(self.writeQueue, ^{
        if(self.writer.status == AVAssetWriterStatusWriting){
            [self.writer finishWritingWithCompletionHandler:^{
                NSURL* url = [NSURL fileURLWithPath:self.path];
                /** 获取视频 */
                __unused AVAsset* asset = [[AVURLAsset alloc] initWithURL:url options:nil];
                /** 写入相册 */
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (handler) {
                            handler(success,error);
                        }
                    });
                }];
            }];
        }
    });
}
/** 追加缓存数据 */
- (void)appendBuffer:(CMSampleBufferRef)sampleBuffer ciImage:(CIImage * _Nullable)ciImage type:(NSString *)mediaType{
    if (CMSampleBufferDataIsReady(sampleBuffer) == false) return;
    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
 
    if (self.writer.status == AVAssetWriterStatusCompleted) {
        self.writeStatus = FZWriteStatusCompleted;
        return;
    } else if (self.writer.status == AVAssetWriterStatusFailed) {
        self.writeStatus = FZWriteStatusFailed;
        NSLog(@"writer error %@", self.writer.error.localizedDescription);
        return;
    }
    switch (self.writeStatus) {
        case FZWriteStatusInit:break;
        case FZWriteStatusPrepare:{
            if (self.writer.status == AVAssetWriterStatusUnknown && mediaType == AVMediaTypeVideo) {
                /** 已视频数据起动写操作 */
                [self.writer startWriting];
                [self.writer startSessionAtSourceTime:pts];
                self.writeStatus = FZWriteStatusWriting;
            }
        } break;
        case FZWriteStatusWriting:{
            CFRetain(sampleBuffer);
            dispatch_async(self.writeQueue, ^{
                @autoreleasepool {
                    if (self.writer.status == AVAssetWriterStatusWriting) {
                        if (mediaType == AVMediaTypeVideo) {
                            if (self.videoInput.readyForMoreMediaData) {
                                if (ciImage) {
                                    CVPixelBufferRef newPixelBuffer = NULL;
                                    if (self.inputPixelBufferAdaptor.assetWriterInput.isReadyForMoreMediaData) {
                                        CVPixelBufferPoolCreatePixelBuffer(NULL, self.inputPixelBufferAdaptor.pixelBufferPool, &newPixelBuffer);
                                        [[CIContext contextWithOptions:nil] render:ciImage toCVPixelBuffer:newPixelBuffer bounds:ciImage.extent colorSpace:nil];
                                    }
                                    if (newPixelBuffer) {
                                        if (self.writer.status == AVAssetWriterStatusWriting) {
                                            BOOL success = [self.inputPixelBufferAdaptor appendPixelBuffer:newPixelBuffer withPresentationTime:pts];
                                            if (!success) {
                                                NSLog(@"append pixel buffer failed");
                                            }
                                        }
                                        CVPixelBufferRelease(newPixelBuffer);
                                    }else{
                                        NSLog(@"newPixelBuffer is nil");
                                    }
                                }else{
                                    BOOL success = [self.videoInput appendSampleBuffer:sampleBuffer];
                                    if (success == NO) {
                                        NSLog(@"视频频写入失败");
                                        self.writeStatus = FZWriteStatusFailed;
                                    }
                                }
                            }
                        } else if (mediaType == AVMediaTypeAudio) {
                            if (self.audioInput.readyForMoreMediaData) {
                                BOOL success = [self.audioInput appendSampleBuffer:sampleBuffer];
                                if (success == NO) {
                                    NSLog(@"音频写入失败");
                                    self.writeStatus = FZWriteStatusFailed;
                                }
                            }
                        }
                    }
                };
                CFRelease(sampleBuffer);
            });
        }break;
        case FZWriteStatusCompleted:break;
        case FZWriteStatusFailed:break;
        default:break;
    }
}


#pragma mark -- Set Func ---------

- (void)setPixelType:(FZCanvasScale) canvasScale {
    _canvasScale = canvasScale;
    switch (canvasScale) {
            case FZCanvasScale1X1:
            self.outputSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
            break;
            case FZCanvasScale4X3:
            self.outputSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width*4/3.0);
            break;
            case FZCanvasScale9X16:
            self.outputSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height*9/16.0);
            break;
        case FZCanvasScale16X9:
            self.outputSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height*19/9.0);
            break;
        default:
            self.outputSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
            break;
    } 
}

//获得视频存放地址
+ (NSString *)VideoCachePath {
    NSString *videoCache = [NSTemporaryDirectory() stringByAppendingPathComponent:@"RecordTemp"] ;
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:videoCache isDirectory:&isDir];
    if (!(isDir == YES && existed == YES) ) {
        [fileManager createDirectoryAtPath:videoCache withIntermediateDirectories:YES attributes:nil error:nil];
    };
    return videoCache;
}
//文件名
+ (NSString *)fileNameWithType:(NSString *)type suffix:(NSString *)suffix {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HHmmss"];
    NSDate * NowDate = [NSDate dateWithTimeIntervalSince1970:now];
    NSString * timeStr = [formatter stringFromDate:NowDate];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.%@",type,timeStr,suffix];
    return fileName;
}

#pragma mark -- Lazy Func ----

//视频写入
-(AVAssetWriterInput *)videoInput{
    if (_videoInput == nil) {
        //录制视频的一些配置，分辨率，编码方式等等
        
        //写入视频大小
        NSInteger numPixels = self.outputSize.width * self.outputSize.height;
        //每像素比特
        CGFloat bitsPerPixel = 24.0; //24位真彩色
        NSInteger bitsPerSecond = numPixels * bitsPerPixel;
        
        // 码率和帧率设置
        NSDictionary *compressionKeys = @{
                                          AVVideoAverageBitRateKey:@(bitsPerSecond), //比特率
                                          AVVideoExpectedSourceFrameRateKey:@(30),  //帧速率
                                          AVVideoMaxKeyFrameIntervalKey:@(30),      //帧间隔
                                          AVVideoProfileLevelKey:AVVideoProfileLevelH264BaselineAutoLevel //画质，默认选择 AVVideoProfileLevelH264BaselineAutoLevel
                                          };
        //视频属性
        AVVideoCodecType type;
        if (@available(iOS 11.0, *)){
            type = AVVideoCodecTypeH264;
        }else{
            type = AVVideoCodecH264;
        }
        NSDictionary* settings = @{
                                   AVVideoCodecKey:type, //编码格式，一般选h264,硬件编码
                                   AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill, //填充模式，AVVideoScalingModeResizeAspectFill拉伸填充
                                   AVVideoWidthKey:@(self.outputSize.height),//视频宽度，以手机水平，home 在右边的方向
                                   AVVideoHeightKey:@(self.outputSize.width),//视频高度，以手机水平，home 在右边的方向
                                   AVVideoCompressionPropertiesKey:compressionKeys //视频硬编码-压缩率关键参数设置压缩率
                                   };
        //初始化视频写入类
        _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                         outputSettings:settings];
        //表明输入是否应该调整其处理为实时数据源的数据
        _videoInput.expectsMediaDataInRealTime = YES;
        _videoInput.transform = CGAffineTransformIdentity;
        //_videoInput.transform = CGAffineTransformMakeRotation(M_PI/2.0);
        
    }
    return _videoInput;
}
/** 像素缓冲区写入 */
-(AVAssetWriterInputPixelBufferAdaptor *)inputPixelBufferAdaptor{
    if (_inputPixelBufferAdaptor == nil) {
        NSDictionary *pixelBufferAttributes = @{
                                                (NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA),
                                                (NSString *)kCVPixelBufferWidthKey:@(self.videoDimensions.width),
                                                (NSString *)kCVPixelBufferHeightKey:@(self.videoDimensions.height),
                                                (NSString *)kCVPixelFormatOpenGLESCompatibility:(NSNumber *)kCFBooleanTrue
                                                };
        _inputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoInput sourcePixelBufferAttributes:pixelBufferAttributes];
    }
    return _inputPixelBufferAdaptor;
    
}
//音频写入
-(AVAssetWriterInput *)audioInput{
    if (_audioInput == nil) {
        /* 注：
         <1>AVNumberOfChannelsKey 通道数  1为单通道 2为立体通道
         <2>AVSampleRateKey 采样率 取值为 8000/44100/96000 影响音频采集的质量
         <3>d 比特率(音频码率) 取值为 8 16 24 32
         <4>AVEncoderAudioQualityKey 质量  (需要iphone8以上手机)
         <5>AVEncoderBitRateKey 比特采样率 一般是128000
         */
        
        /*另注：aac的音频采样率不支持96000，当我设置成8000时，assetWriter也是报错*/
        /*采样率输入的模拟音频信号每一秒的采样数是影响音频质量和音频文件大小非常重要的一个因素采样率越小文件越小质量越低如@(441000) 44.1kHz */
        
        //音频的一些配置包括音频各种这里为AAC,音频通道、采样率和音频的比特率
        NSDictionary *settings = @{
                                   AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                                   AVNumberOfChannelsKey:@(self.channels),//通道数1为单通道2为立体通道
                                   AVSampleRateKey:@(self.samplerate),//采样率
                                   //AVEncoderBitRatePerChannelKey:@(28000),//编码时每个通道的比特率
                                   AVEncoderBitRateKey:@(128000),//比特采样率(音频的比特率)
                                   };
        
        
        /**
         2019-01-20 09:52:42.327179+0800 FZOCProject[4204:262193] *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '*** -[AVAssetWriterInput initWithMediaType:outputSettings:sourceFormatHint:] Cannot specify both AVEncoderBitRateKey and AVEncoderBitRatePerChannelKey'
         
         */
        /**
         2019-01-20 09:56:58.089363+0800 FZOCProject[4226:263590] *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '*** -[AVAssetWriterInput initWithMediaType:outputSettings:sourceFormatHint:] Invalid value 1.00 for AVSampleRateKey; sample rate must be between 8.0 and 192.0 kHz inclusive'
         */
        //初始化音频写入类
        _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                         outputSettings:settings];
        //表明输入是否应该调整其处理为实时数据源的数据
        _audioInput.expectsMediaDataInRealTime = YES;
        //将音频输入源加入
        if ([_writer canAddInput:_audioInput]) {
            [_writer addInput:_audioInput];
        }
    }
    return _audioInput;
}

-(dispatch_queue_t )writeQueue{
    if (_writeQueue == nil) {
       _writeQueue = dispatch_queue_create("wufuzeng.video.write", DISPATCH_QUEUE_SERIAL);
    }
    return _writeQueue;
}

@end
