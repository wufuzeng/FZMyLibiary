//
//  FZViewController.m
//  FZMyLibiary
//
//  Created by wufuzeng on 11/28/2018.
//  Copyright (c) 2018 wufuzeng. All rights reserved.
//

#import "FZViewController.h"

#import "FZMyLibiary.h"
#import "LFGPUImageEmptyFilter.h"
#import "FSKGPUImageBeautyFilter.h"

@interface FZViewController ()
{
    GPUImageMovieWriter *_movieWriter;
}


@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic,strong) UIImageView *showView;
@property (nonatomic,strong) UIImage *image;

/** 图片相机 */
@property (nonatomic,strong) GPUImageStillCamera *imageCamera;
/** 视频相机 */
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
/** 滤镜视图(捕获内容经过滤处理的预览视图) */
@property (nonatomic,strong) GPUImageView *filterView;
/** BeautifyFace美颜滤镜（默认开启美颜） */
@property (nonatomic,strong) FSKGPUImageBeautyFilter *beautifyFilter;
//裁剪1:1
@property (nonatomic,strong) GPUImageCropFilter *cropFilter;
//滤镜组
@property (nonatomic,strong) GPUImageFilterGroup *filterGroup;

//视频路径
@property (strong, nonatomic) NSMutableArray<NSDictionary *> *videoArray;

@end

@implementation FZViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupViews];
    
}

-(void)setupViews{
    [self imageView];
    [self showView];
    [self filterView];
    [self imageCamera];
    [self beautifyFilter];
    [self cropFilter];
    [self filterGroup];
    [self openBeautify];
    [self startCameraCapture];
}

//开启捕捉
- (void)startCameraCapture {
    if (self.imageCamera) {
        [self.imageCamera startCameraCapture];
    }
}

//停止捕捉
- (void)stopCameraCapture {
    if (self.imageCamera) {
        [self.imageCamera stopCameraCapture];
    }
}

//拍照
-(void)takePicture{
    __weak __typeof(self) weakSelf = self;
    [self.imageCamera capturePhotoAsJPEGProcessedUpToFilter:self.imageCamera.targets.firstObject withCompletionHandler:^(NSData *processedJPEG, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:processedJPEG];
            weakSelf.showView.image = image;
            weakSelf.image = image;
            NSLog(@"拍照成功");
        } else {
             NSLog(@"拍摄失败");
        }
    }];
}

//开始拍摄
-(void)startRecording{
    
    //开始拍摄
    NSURL *videoURL = [NSURL fileURLWithPath:@""];
    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:videoURL size:CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width)];
    _movieWriter.encodingLiveVideo = YES;
    _movieWriter.shouldPassthroughAudio = YES;
    _movieWriter.assetWriter.movieFragmentInterval = kCMTimeInvalid;
    
    [self.cropFilter addTarget:_movieWriter];
    
    self.videoCamera.audioEncodingTarget = _movieWriter;
    
    [_movieWriter startRecording];
}

//停止拍摄
-(void)stopRecording{
    //拍摄结束
    [_movieWriter finishRecording];
    [self.cropFilter removeTarget:_movieWriter];
    self.videoCamera.audioEncodingTarget = nil;
}


//开启美颜
- (void)openBeautify {
    [self.beautifyFilter removeAllTargets];
    [self.cropFilter removeAllTargets];
    [self.filterGroup removeAllTargets];
    [self.imageCamera removeAllTargets];
    
    //加上美颜滤镜
    [self.cropFilter addTarget:self.beautifyFilter];
    //第一个滤镜
    self.filterGroup.initialFilters = @[self.cropFilter];
    //最后一个滤镜
    self.filterGroup.terminalFilter = self.beautifyFilter;
    
    [self.filterGroup addTarget:self.filterView];
    [self.imageCamera addTarget:self.filterGroup];
    
}

//关闭美颜
- (void)closeBeautify {
    
    [self.beautifyFilter removeAllTargets];
    [self.cropFilter removeAllTargets];
    [self.filterGroup removeAllTargets];
    [self.imageCamera removeAllTargets];
    
    self.filterGroup.initialFilters = @[self.cropFilter];
    self.filterGroup.terminalFilter = self.cropFilter;
    
    [self.filterGroup addTarget:self.filterView];
    [self.imageCamera addTarget:self.filterGroup];
    
}





#pragma mark -- Lazy Func ----

-(UIImageView *)imageView{
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width)];
        [self.view addSubview:_imageView];
    }
    return _imageView;
}
-(UIImageView *)showView{
    if (_showView == nil) {
        _showView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        _showView.backgroundColor = [UIColor clearColor];
        _showView.contentMode = UIViewContentModeScaleAspectFill;
        _showView.clipsToBounds = YES;
        [self.imageView addSubview:_showView];
        
    }
    return _showView;
}




-(GPUImageStillCamera *)imageCamera{
    if (_imageCamera == nil) {
        _imageCamera =
        [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh
                                            cameraPosition:AVCaptureDevicePositionBack];
        /** 输出图片方向 */
        _imageCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        /** 前置摄像头水平镜像 */
        _imageCamera.horizontallyMirrorFrontFacingCamera = YES;
    }
    return _imageCamera;
}

/** 视频相机 */
-(GPUImageVideoCamera *)videoCamera{
    if (_videoCamera == nil) {
        _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
        
        [self.videoCamera addAudioInputsAndOutputs];
        [self.videoCamera addTarget:self.cropFilter];
        
        [self.cropFilter addTarget:self.beautifyFilter];
        [self.beautifyFilter addTarget:self.filterView];
        
        [self.videoCamera startCameraCapture];
    }
    return _videoCamera;
}


-(GPUImageView *)filterView{
    if (_filterView == nil) {
        _filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width)];
        _filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        //self.filterView.center = self.view.center;
        [self.imageView addSubview:_filterView];
    }
    return _filterView;
}

/** BeautifyFace美颜滤镜（默认开启美颜） */
-(FSKGPUImageBeautyFilter *)beautifyFilter{
    if (_beautifyFilter == nil) {
        _beautifyFilter = [[FSKGPUImageBeautyFilter alloc] init];
        _beautifyFilter.beautyLevel = 0.9f;//美颜程度
        _beautifyFilter.brightLevel = 0.7f;//美白程度
        _beautifyFilter.toneLevel   = 0.9f;//色调强度
    }
    return _beautifyFilter;
}
//裁剪1:1
-(GPUImageCropFilter *)cropFilter{
    if (_cropFilter == nil) {
        
        /*
         图片宽 = 像素宽 / 分辨率宽
         图片高 = 像素高 / 分辨率高
         
         CropRegion: 在图片内裁剪，宽高按比例默认0.0~1.0，0.0-0.0位于图片左上角
         
         假设一张图片size=100x100，
         如果横屏裁切后展示的区域是CGRectMake(0, 12.5, 100, 75)
         如果竖屏裁切后的展示区域是CGRectMake(12.5, 0, 75, 100)
         */
        
        _cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0,
                                                                                44/[UIScreen mainScreen].bounds.size.height,
                                                                                1,
                                                                                [UIScreen mainScreen].bounds.size.width/[UIScreen mainScreen].bounds.size.height
                                                                                )];
    }
    return _cropFilter;
}
//滤镜组
-(GPUImageFilterGroup *)filterGroup{
    if (_filterGroup == nil) {
        _filterGroup = [[GPUImageFilterGroup alloc] init];
        [_filterGroup addFilter:self.cropFilter];
        [_filterGroup addFilter:self.beautifyFilter];
    }
    return _filterGroup;
}




- (void)dealloc {
    
    [self.imageCamera stopCameraCapture];
    [self.imageCamera removeInputsAndOutputs];
    [self.imageCamera removeAllTargets];
    [self.beautifyFilter removeAllTargets];
    [self.cropFilter removeAllTargets];
    [self.filterGroup removeAllTargets];
    
    self.imageCamera = nil;
    self.videoCamera = nil;
    self.filterView = nil;
    self.beautifyFilter = nil;
    self.cropFilter = nil;
    self.filterGroup = nil;
    
    
}


@end
