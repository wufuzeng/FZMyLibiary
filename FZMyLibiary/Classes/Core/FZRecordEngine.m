//
//  FZRecordEngine.m
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/18.
//  Copyright © 2019 wufuzeng. All rights reserved.
//




#import "FZRecordEngine.h"
#import "FZRecordAdaptor.h"
#import "FZRecordEncoder.h"
#import "FZRecordConfig.h"
#import "FZFilter.h"
@interface FZRecordEngine ()
<
AVCaptureVideoDataOutputSampleBufferDelegate,//视频
AVCaptureAudioDataOutputSampleBufferDelegate,//音频
AVCaptureMetadataOutputObjectsDelegate//元数据
>

/** 流 */
@property (nonatomic, strong) AVCaptureSession *session;
/** openGL view */
@property (nonatomic,readwrite,strong) GLKView *glkView;
/** 视频频输入 */
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
/** 音频输入 */
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
/** 队列 */
@property (nonatomic, strong) dispatch_queue_t recordQueue;
/** 视频输出 */
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
/** 音频输出 */
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;
/** 元数据输出 */
@property (nonatomic, strong) AVCaptureMetadataOutput *metaDataOutput;

/** 开始录制时间 */
@property (nonatomic, assign) CMTime startTime;
/** 中断偏移CMTime */
@property (nonatomic, assign) CMTime offsetTime;
/** 上一次录入时间 */
@property (nonatomic, assign) CMTime lastTime;
//当前视频规模
@property (nonatomic,assign) CMVideoDimensions currentVideoDimensions;
/** 当前录制时间 */
@property (atomic, assign) CGFloat currentRecordTime;

/** 文件输出 */
//@property (nonatomic, strong) AVCaptureMovieFileOutput *fileOutput;
/** 文件输出连接 */
//@property (nonatomic, strong) AVCaptureConnection *fileOutputConnection;

/** CoreImage中上下文 */
@property (nonatomic,strong) CIContext *cicontext;
/** openGL ES中上下文 */
@property (nonatomic,strong) EAGLContext *eaglContext;
/** 滤镜 */
@property (nonatomic,strong) CIFilter *filter;
/** 面部元数据 */
@property (nonatomic,strong) AVMetadataFaceObject *faceObject;

/** 录制编码 */
@property (nonatomic,strong) FZRecordEncoder *recordEncoder;
/** 录制状态 */
@property (nonatomic,assign) FZRecordStatus recordStatus;

@end

@implementation FZRecordEngine

-(instancetype)init {
    if (self = [super init]) { 
        [self startUp];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shutDown) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startUp) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

-(void)dealloc{
    [self shutDown];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}


-(void)setupInit{
    [self session];
    [self previewlayer];
    [FZRecordConfig session:self.session addInput:self.videoInput];
    [FZRecordConfig session:self.session addInput:self.audioInput];
    [FZRecordConfig session:self.session addOutput:self.videoOutput];
    [FZRecordConfig session:self.session addOutput:self.audioOutput];
    [FZRecordConfig session:self.session addOutput:self.metaDataOutput];
}

/** 启动捕捉功能 */
- (void)startUp{
    [self setupInit];
    if (self.maxRecordTime == 0) {
        self.maxRecordTime = 10;
    }
    self.startTime = CMTimeMake(0, 0);
    self.recordStatus = FZRecordStatusInit;
    [self startRunning];
}

-(void)startRunning{
    NSArray *array = [[self.session.outputs objectAtIndex:0] connections];
    for (AVCaptureConnection *connection in array){
        /** 首次启动设置为竖屏 */
        connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    [self.session startRunning];
    /*
     * availableMetadataObjectTypes是需要实时检测的，
     * 需要session启动后才能进行有效检测，
     * 未启动之前是无法获取有效值的。
     */
    NSLog(@"availableMetadataObjectTypes : %@",[self.metaDataOutput availableMetadataObjectTypes]);
    self.metaDataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
}

/** 关闭捕捉功能 */
- (void)shutDown{
    self.startTime = CMTimeMake(0, 0);
    self.recordStatus = FZRecordStatusInit;
    if (self.session) {
        [self.session stopRunning];
    }
    self.session     = nil;
    self.recordQueue  = nil;
    self.videoOutput = nil;
    self.videoInput  = nil;
    self.audioOutput = nil;
    self.audioInput  = nil;
    self.recordEncoder = nil;
}

-(void)startRecord{
    @synchronized (self) {
        self.offsetTime = CMTimeMake(0, 0);
        if (self.recordStatus == FZRecordStatusInit ||
            self.recordStatus == FZRecordStatusFinished) {
            self.recordStatus = FZRecordStatusPrepare;
        }else if (self.recordStatus == FZRecordStatusPaused){
            [self resumeRecord];
        }
    }
}

-(void)pauseRecord{
    @synchronized (self) {
        if (self.recordStatus == FZRecordStatusRecording) {
            self.recordStatus = FZRecordStatusPaused;
        }
    }
}
-(void)resumeRecord{
    @synchronized (self) {
        if (self.recordStatus == FZRecordStatusPaused) {
            self.recordStatus = FZRecordStatusResuming;
        }
    }
}

-(void)stopRecord{
    @synchronized (self) {
        self.recordStatus = FZRecordStatusFinished;
        if (_recordEncoder) {
            [_recordEncoder stopWriteWithCompletionHandler:^(BOOL success, NSError * _Nullable error) {
                if ([self.delegate respondsToSelector:@selector(recorder:didCompleteWithSuccess:error:)]) {
                    [self.delegate recorder:self didCompleteWithSuccess:success error:error];
                }
            }];
        }
    }
}

#pragma mark -- SampleBuffer Info --

/** 记录录制首帧的开始时间 */
-(void)recordStartTimeOfFirstRecordedSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    CFRetain(sampleBuffer);
    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CFRelease(sampleBuffer);
    /** 录制起始时间 */
    if (self.startTime.value == 0) {
        self.startTime = pts;
    }
}
/** 记录最新一帧的结束时间 */
-(void)recordEndTimeOfLastRecordedSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    CFRetain(sampleBuffer);
    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CMTime dur = CMSampleBufferGetDuration(sampleBuffer);
    CFRelease(sampleBuffer);
    /** 采集结束时间 */
    if (dur.value > 0) {
        pts = CMTimeAdd(pts, dur);
    }
    self.lastTime = pts;
}

/** 记录录制中断时间偏移 */
-(void)recordInterruptTimeOffsetOfRecordedSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    CFRetain(sampleBuffer);
    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CFRelease(sampleBuffer);
    if (self.lastTime.flags & kCMTimeFlags_Valid) {
        //self.lastTime.flags != 0; self.lastTime被更新过
        if (self.offsetTime.flags & kCMTimeFlags_Valid) {
            //self.offsetTime.flags != 0; self.offsetTime被更新过
            pts = CMTimeSubtract(pts, self.offsetTime);
        }else{
            //self.offsetTime.flags == 0
        }
        /** 本次恢复距离上次中断偏移 */
        CMTime offset = CMTimeSubtract(pts, self.lastTime);
        if (self.offsetTime.value == 0) {
            /** 首次恢复 */
            self.offsetTime = offset;
        }else{
            /** 多次恢复 */
            self.offsetTime = CMTimeAdd(self.offsetTime, offset);
        }
    }else{
        //self.lastTime.flags > 0;
    }
    //_lastTime.flags = 0;//使失效
}

/** 更新录制帧时间 */
-(void)updateCurrentTimeOfRecordedCMTime:(CMTime)time{
    self.currentRecordTime = CMTimeGetSeconds(time);
    /** 更新进度 */
    if ([self.delegate respondsToSelector:@selector(recorder:recordProgress:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate recorder:self recordProgress:self.currentRecordTime/self.maxRecordTime];
        });
    }
    /** 达到最大时间 */
    if (self.currentRecordTime >= self.maxRecordTime  ) {
        self.recordStatus = FZRecordStatusFinished;
        if (_recordEncoder) {
            [_recordEncoder stopWriteWithCompletionHandler:^(BOOL success, NSError * _Nullable error) {
                if ([self.delegate respondsToSelector:@selector(recorder:didCompleteWithSuccess:error:)]) {
                    [self.delegate recorder:self didCompleteWithSuccess:success error:error];
                }
            }];
        }
    }
}

#pragma mark -- AVCaptureMetadataOutputObjectsDelegate --
/** 元数据捕捉 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray <__kindof AVMetadataObject *>*)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    for (AVMetadataObject *obj in metadataObjects) {
        if (obj.type == AVMetadataObjectTypeFace) {
            @synchronized (self) {
                self.faceObject = (AVMetadataFaceObject *)obj;
            }
            break;
        }
    }
}
#pragma mark -- AVCaptureVideoDataOutputSampleBufferDelegate -----
#pragma mark -- AVCaptureAudioDataOutputSampleBufferDelegate -----
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    if ([captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]]) {
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        if (orientation == UIDeviceOrientationPortrait) {
            [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }else if (orientation == UIDeviceOrientationLandscapeLeft) {
            [connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        }else if (orientation == UIDeviceOrientationLandscapeRight) {
            [connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        }else{
            [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
    }  
    @autoreleasepool {
        @synchronized (self) {
            if (captureOutput == self.videoOutput || connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo]) {
                [self videoCaptureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
            }
            if (captureOutput == self.audioOutput || connection == [self.audioOutput connectionWithMediaType:AVMediaTypeAudio]) {
                [self audioCaptureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
            }
        }
    }
}
/** 获得原始帧 */
- (void)videoCaptureOutput:(AVCaptureOutput *)captureOutput
     didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
            fromConnection:(AVCaptureConnection *)connection{
 
    if (self.videoInput.device.position == AVCaptureDevicePositionFront) {
        /** 镜像 */
        [connection setVideoMirrored:YES];
    }
    
    CMVideoFormatDescriptionRef fmt = CMSampleBufferGetFormatDescription(sampleBuffer);
    self.recordEncoder.videoDimensions = CMVideoFormatDescriptionGetDimensions(fmt);

    CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *outputImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    /** 添加滤镜 */
    [self.filter setValue:outputImage forKey:kCIInputImageKey];
    outputImage = self.filter.outputImage;
    if (self.faceObject){
        /** 人脸滤镜 */
        outputImage = [FZFilter faceImage:outputImage faceObject:self.faceObject];
    }
    __block CGImageRef imageRef = [self.cicontext createCGImage:outputImage fromRect:outputImage.extent];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.previewlayer.contents = (__bridge id)imageRef;
        CGImageRelease(imageRef);
    });
    
    switch (self.recordStatus) {
        case FZRecordStatusInit:break;
        case FZRecordStatusPrepare:break;
        case FZRecordStatusPaused:break;
        case FZRecordStatusResuming:{
            self.recordStatus = FZRecordStatusRecording;
            /** 记录录制中断偏移量 */
            [self recordInterruptTimeOffsetOfRecordedSampleBuffer:sampleBuffer];
        }//break;
        case FZRecordStatusRecording:{
            CFRetain(sampleBuffer);
            /** 调整buffer PTS */
            sampleBuffer = [self adjustPresentationTimeStamp:sampleBuffer by:self.offsetTime];
            /** 进行数据编码 */
            [self.recordEncoder appendBuffer:sampleBuffer ciImage:outputImage type:AVMediaTypeVideo];
            
            /** 记录录制首帧的开始时间 */
            [self recordStartTimeOfFirstRecordedSampleBuffer:sampleBuffer];
            /** 记录最新录制帧的结束时间 */
            [self recordEndTimeOfLastRecordedSampleBuffer:sampleBuffer];
            
            /** 更新录制帧时间 */
            [self updateCurrentTimeOfRecordedCMTime:CMTimeSubtract(self.lastTime, self.startTime)];
            CFRelease(sampleBuffer);
        }break;
        case FZRecordStatusFinished:break;
        default: return;
    }
}
/** 音频输出 */
- (void)audioCaptureOutput:(AVCaptureOutput *)captureOutput
     didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
            fromConnection:(AVCaptureConnection *)connection{
    
    switch (self.recordStatus) {
        case FZRecordStatusInit: break;
        case FZRecordStatusPrepare:{
            /** 提取音频格式 */
            [self extractAudioFormatFromSampleBuffer:sampleBuffer];
            if ([self.recordEncoder creatWriter]) {
                [self.recordEncoder prepareWrite];
                self.recordStatus = FZRecordStatusRecording;
            }
        } break;
        case FZRecordStatusPaused: break;
        case FZRecordStatusResuming:{
            self.recordStatus = FZRecordStatusRecording;
            /** 记录录制中断偏移量 */
            [self recordInterruptTimeOffsetOfRecordedSampleBuffer:sampleBuffer];
        } //break;
        case FZRecordStatusRecording:{
            CFRetain(sampleBuffer);
            /** 调整buffer PTS */
            sampleBuffer = [self adjustPresentationTimeStamp:sampleBuffer by:self.offsetTime];
            /** 进行数据编码 */ 
            [self.recordEncoder appendBuffer:sampleBuffer ciImage:nil type:AVMediaTypeAudio];
            /** 记录最新录制帧的结束时间 */
            [self recordEndTimeOfLastRecordedSampleBuffer:sampleBuffer];
            CFRelease(sampleBuffer);
        }break;
        case FZRecordStatusFinished:return;
        default: return;
    }
}


/** 提取音频格式 */
- (void)extractAudioFormatFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CFRetain(sampleBuffer);
    CMFormatDescriptionRef fmt = CMSampleBufferGetFormatDescription(sampleBuffer);
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt);
    CFRelease(sampleBuffer);
    //音频采样率 采样率输入的模拟音频信号每一秒的采样数是影响音频质量和音频文件大小非常重要的一个因素采样率越小文件越小质量越低如@(44100) 44.1kHz
    self.recordEncoder.samplerate = asbd->mSampleRate;
    //音频通道 //通道数1为单通道2为立体通道
    self.recordEncoder.channels = asbd->mChannelsPerFrame;
}
/** 调整媒体数据的时间 */
- (CMSampleBufferRef)adjustPresentationTimeStamp:(CMSampleBufferRef)sampleBuffer by:(CMTime)offset {
    if (self.offsetTime.value == 0)return sampleBuffer;
    
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil, &count);
    CMSampleTimingInfo *pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sampleBuffer, count, pInfo, &sout);
    free(pInfo);
    CFRelease(sampleBuffer);/** 讲究,不知该怎么说才好 */
    return sout;
}

#pragma mark -- Config Device Func -----

/** 设置设备聚焦点 */
-(void)configFocusMode:(AVCaptureFocusMode)focusMode
 exposureMode:(AVCaptureExposureMode)exposureMode
      atPoint:(CGPoint)point{
    [FZRecordConfig config:self.videoInput.device focusMode:focusMode exposureMode:exposureMode atPoint:point];
}
/** 切换摄像头 */
- (void)turnCamera{
    self.videoInput = [FZRecordConfig turnCamera:self.session previewlayer:self.previewlayer videoInput:self.videoInput];
}
/** 切换闪光灯状态 */
-(void)setTorchMode:(AVCaptureTorchMode)torchMode{
    if (_torchMode == torchMode) {
        return;
    }else if (torchMode > AVCaptureTorchModeAuto) {
        _torchMode = AVCaptureTorchModeOff;
    }else{
        _torchMode = torchMode;
    } 
    [FZRecordConfig config:self.videoInput.device torchMode:_torchMode];
}

#pragma mark -- Lazy Func ----

- (dispatch_queue_t)recordQueue{
    if (!_recordQueue) {
        _recordQueue = dispatch_queue_create("wufuzeng.video.record", DISPATCH_QUEUE_SERIAL);
    }
    return _recordQueue;
}

- (AVCaptureSession *)session {
    // 录制5秒钟视频 高画质10M,压缩成中画质 0.5M
    // 录制5秒钟视频 中画质0.5M,压缩成中画质 0.5M
    // 录制5秒钟视频 低画质0.1M,压缩成中画质 0.1M
    // 只有高分辨率的视频才是全屏的，如果想要自定义长宽比，就需要先录制高分辨率，再剪裁，如果录制低分辨率，剪裁的区域不好控制
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        [_session beginConfiguration];
        if ([_session canSetSessionPreset:AVCaptureSessionPresetiFrame1280x720]) {
            //设置分辨率  AVCaptureSessionPreset1280x720
            _session.sessionPreset = AVCaptureSessionPresetiFrame1280x720;
        }
        [_session commitConfiguration];
    }
    return _session;
}

- (CALayer *)previewlayer{
    if (!_previewlayer) {
        //_previewlayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        //_previewlayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewlayer = [[CALayer alloc]init];
        _previewlayer.contentsGravity = AVLayerVideoGravityResizeAspectFill;
        _previewlayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        
        
    }
    return _previewlayer;
}

-(AVCaptureDeviceInput *)videoInput{
    if (_videoInput == nil) {
        AVCaptureDevice *device = [FZRecordConfig cameraDeviceWithPosition:AVCaptureDevicePositionBack];
        
        [FZRecordConfig device:device changeProperty:^(AVCaptureDevice *captureDevice) {
            //视频 HDR (高动态范围图像)
            /**
             error:
             reason: '*** -[AVCaptureDevice setVideoHDREnabled:] May not be called while automaticallyAdjustsVideoHDREnabled is YES'
             */
            //captureDevice.videoHDREnabled = YES;
            //设置最大，最小帧速率
            //captureDevice.activeVideoMaxFrameDuration = CMTimeMake(1, 120);
            //captureDevice.activeVideoMinFrameDuration = CMTimeMake(1, 60);
        }];
        
        NSError *error = nil;
        _videoInput =  [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    }
    return _videoInput;
}
-(AVCaptureDeviceInput *)audioInput{
    if (_audioInput == nil) {
        AVCaptureDevice *device = [FZRecordConfig microphone];
        NSError *error = nil;
        _audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    }
    return _audioInput;
}

-(AVCaptureVideoDataOutput *)videoOutput{
    if (_videoOutput == nil) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        _videoOutput.alwaysDiscardsLateVideoFrames = YES; //立即丢弃旧帧，节省内存，默认YES
        _videoOutput.videoSettings = @{
                                       (NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                       //(NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                                       };
       [_videoOutput setSampleBufferDelegate:self queue:self.recordQueue];
    }
    return _videoOutput;
}

-(AVCaptureAudioDataOutput *)audioOutput{
    if (_audioOutput == nil) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.recordQueue];
    }
    return _audioOutput;
}

-(AVCaptureMetadataOutput *)metaDataOutput{
    if (_metaDataOutput == nil) {
        _metaDataOutput = [[AVCaptureMetadataOutput alloc] init];
        [_metaDataOutput setMetadataObjectsDelegate:self queue:self.recordQueue];
    }
    return _metaDataOutput;
}

//-(AVCaptureMovieFileOutput *)fileOutput{
//    if (_fileOutput == nil) {
//        _fileOutput = [[AVCaptureMovieFileOutput alloc]init];
//    }
//    return _fileOutput;
//}

//-(AVCaptureConnection *)fileOutputConnection{
//    if (_fileOutputConnection == nil) {
//        _fileOutputConnection = [self.fileOutput connectionWithMediaType:AVMediaTypeVideo];
//
//        /**
//         * 设置防抖
//         * 视频防抖 是在 iOS 6 和 iPhone 4S 发布时引入的功能。
//         * 到了 iPhone 6，增加了更强劲和流畅的防抖模式，被称为影院级的视频防抖动。
//         * 相关的 API 也有所改动 (目前为止并没有在文档中反映出来，不过可以查看头文件）。
//         * 防抖并不是在捕获设备上配置的，而是在 AVCaptureConnection 上设置。
//         * 由于不是所有的设备格式都支持全部的防抖模式，所以在实际应用中应事先确认具体的防抖模式是 否支持：
//         */
//        if ([_fileOutputConnection isVideoStabilizationSupported ]) {
//            _fileOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
//        }
//        //预览图层和视频方向保持一致
//        _fileOutputConnection.videoOrientation = [self.previewlayer connection].videoOrientation;
//
//    }
//    return _fileOutputConnection;
//}

-(FZRecordEncoder *)recordEncoder{
    if (_recordEncoder == nil) {
        _recordEncoder = [[FZRecordEncoder alloc]init];
        _recordEncoder.canvasScale = FZCanvasScale9X16;
    }
    return _recordEncoder;
}

-(CIContext *)cicontext{
    if (_cicontext == nil) {
        /**
         //1、2、3种方式，自己选一种
         //1、创建基于CPU的图像上下文
         NSNumber *number=[NSNumber numberWithBool:YES];
         NSDictionary *option=[NSDictionary dictionaryWithObject:number forKey:kCIContextUseSoftwareRenderer];
         context=[CIContext contextWithOptions:option];
         */
        /*
        //2、创建基于GPU的图像上下文
        context=[CIContext contextWithOptions:nil];
         */
        /**
         //3、或者创建OpenGL优化过的图像上下文
         EAGLContext *eaglContext=[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
         context=[CIContext contextWithEAGLContext:eaglContext];
         */
        _cicontext = [CIContext contextWithOptions:nil];
    }
    return _cicontext;
}
-(EAGLContext *)eaglContext{
    if (_eaglContext == nil) {
        // kEAGLRenderingAPIOpenGLES2 openGL 版本 2.0
        _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    return _eaglContext;
}

-(GLKView *)glkView{
    if (!_glkView) {
        _glkView = [[GLKView alloc] initWithFrame:
                    CGRectMake(0, 0,
                               [UIScreen mainScreen].bounds.size.width*2,
                               [UIScreen mainScreen].bounds.size.height*2)
                                          context:self.eaglContext];
        
        _glkView.drawableColorFormat = GLKViewDrawableColorFormatRGB565;
        _glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    }
    return _glkView;
}

-(CIFilter *)filter{
    if (_filter == nil) {
        _filter = [FZFilter CoreImageFilter:FZCoreImageFilterTypeNoir];
    }
    return _filter;
}

@end
