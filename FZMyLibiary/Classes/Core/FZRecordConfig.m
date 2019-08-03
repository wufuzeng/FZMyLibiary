//
//  FZRecordConfig.m
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/3.
//

#import "FZRecordConfig.h"

@implementation FZRecordConfig

/** 添加输入对象 */
+(void)session:(AVCaptureSession *)session addInput:(AVCaptureDeviceInput*)input{
    if ([session canAddInput:input]) {
        [FZRecordConfig session:session changeConfig:^(AVCaptureSession *captureSession) {
            [captureSession addInput:input];
        }];
    }
}
/** 添加输出对象 */
+(void)session:(AVCaptureSession *)session addOutput:(id)output{
    if ([session canAddOutput:output]) {
        [FZRecordConfig session:session changeConfig:^(AVCaptureSession *captureSession) {
           [captureSession addOutput:output];
        }];
        
    }
}


/** 设置设备聚焦点 */
+(void)config:(AVCaptureDevice *)device
    focusMode:(AVCaptureFocusMode)focusMode
 exposureMode:(AVCaptureExposureMode)exposureMode
      atPoint:(CGPoint)point{
    
    [FZRecordConfig device:device changeProperty:^(AVCaptureDevice *captureDevice) {
        //设置焦距模式
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        //设置聚焦的兴趣点
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        //设置曝光量模式
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        //设置兴趣曝光点
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}




/**
 设置焦距
 镜头变焦，也就是推近或者拉远焦距：
 方法一:修改AVCaptureDevice的缩放系数videoZoomFactor来实现镜头变焦，
 方法二:修改AVCaptureConnection的缩放系数videoScaleAndCropFactor来实现镜头变焦。
 */
+ (void)focalizeAdjustVideoZoomFactor:(CGFloat )scale{
    AVCaptureDevice *backCamera = [FZRecordConfig cameraDeviceWithPosition:AVCaptureDevicePositionBack];
    if(scale > backCamera.activeFormat.videoMaxZoomFactor) {
        scale = backCamera.activeFormat.videoMaxZoomFactor;
    }
    
    if([backCamera isRampingVideoZoom]){
        [backCamera cancelVideoZoomRamp];
    }
    [FZRecordConfig device:backCamera changeProperty:^(AVCaptureDevice * captureDevice) {
       [captureDevice rampToVideoZoomFactor:scale withRate:10];
    }];
}

/** 切换摄像头 */
+ (AVCaptureDeviceInput *)turnCamera:(AVCaptureSession *)session previewlayer:(CALayer *)previewlayer videoInput:(AVCaptureDeviceInput*)videoInput{
    [session stopRunning];
    CATransition* transition = [CATransition animation];
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.duration = 0.35f;
    transition.type = @"oglFlip";
    
    AVCaptureDevicePosition position = videoInput.device.position;
    if (position == AVCaptureDevicePositionBack) {
        position = AVCaptureDevicePositionFront;
        transition.subtype = kCATransitionFromLeft;
    } else {
        position = AVCaptureDevicePositionBack;
        transition.subtype = kCATransitionFromRight;
    }
    [previewlayer addAnimation:transition forKey:nil];
    
    AVCaptureDevice *device = [FZRecordConfig cameraDeviceWithPosition:position];
    AVCaptureTorchMode torchMode = device.torchMode;
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    [FZRecordConfig session:session changeConfig:^(AVCaptureSession *captureSession) {
        [captureSession removeInput:videoInput];
        [captureSession addInput:newInput];
    }];
    [FZRecordConfig device:device changeProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice hasTorch]) {
            [captureDevice setTorchMode:torchMode];
        }
    }]; 
    [session startRunning];
    return newInput;
}
/** 切换闪光灯状态 */
+(void)config:(AVCaptureDevice *)device torchMode:(AVCaptureTorchMode)torchMode{
    [FZRecordConfig device:device changeProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice hasTorch] && [device isTorchModeSupported:torchMode]) {
            [captureDevice setTorchMode:torchMode];
        }
    }];
}

/** 改变流配置性 */
+(void)session:(AVCaptureSession *)session changeConfig:(void(^)(AVCaptureSession *captureSession))changeConfig{
    [session beginConfiguration];
    changeConfig(session);
    [session commitConfiguration];
}

/** 改变设备属性 */
+(void)device:(AVCaptureDevice *)device changeProperty:(void(^)(AVCaptureDevice *captureDevice))propertyChange{
    NSError *error;
    /**
     注意改变设备属性前一定要首先调用lockForConfiguration:
     调用完之后使用unlockForConfiguration方法解锁
     */
    if ([device lockForConfiguration:&error]) {
        propertyChange(device);
        [device unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}
/** 获取摄像头 */
+(AVCaptureDevice *)cameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras = nil;
    AVCaptureDevice *captureDevice = nil;
    if (@available(iOS 10.0,*)) {
        AVCaptureDeviceDiscoverySession *devicesIOS10 = [AVCaptureDeviceDiscoverySession  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
        cameras  = devicesIOS10.devices;
    }else{
        cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    }
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            captureDevice = camera;
            break;
        }
    }
    
    // frame 长宽比范围 duration:期间 rate:比率 range:范围
    //    CMTime frameDuration = CMTimeMake(3, 10);
    //    NSArray *supportedFrameRateRanges = [captureDevice.activeFormat videoSupportedFrameRateRanges];
    //    BOOL frameRateSupported = NO;
    //    for (AVFrameRateRange *range in supportedFrameRateRanges) {
    //        NSLog(@"AVFrameRateRange : %@",range);
    //        if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) && (CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration))){
    //            frameRateSupported = YES;
    //        }
    //    }
    return captureDevice;
}
/** 获取音频麦克风 */
+(AVCaptureDevice *)microphone{
    AVCaptureDevice *audioCaptureDevice = nil;
    if (@available(iOS 10.0 ,*)) {
        AVCaptureDeviceDiscoverySession *devicesIOS10 = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInMicrophone] mediaType:AVMediaTypeAudio position:AVCaptureDevicePositionUnspecified];
        audioCaptureDevice = devicesIOS10.devices.firstObject;
    }else{
        audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    }
    return audioCaptureDevice;
}



@end
