//
//  FZRecordConfig.h
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/3.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface FZRecordConfig : NSObject
/** 添加输入对象 */
+(void)session:(AVCaptureSession *)session addInput:(AVCaptureDeviceInput*)input;
/** 添加输出对象 */
+(void)session:(AVCaptureSession *)session addOutput:(id)output;
/** 设置设备聚焦点 */
+(void)config:(AVCaptureDevice *)device
    focusMode:(AVCaptureFocusMode)focusMode
 exposureMode:(AVCaptureExposureMode)exposureMode
      atPoint:(CGPoint)point;
/**
 设置焦距
 镜头变焦，也就是推近或者拉远焦距：
 方法一:修改AVCaptureDevice的缩放系数videoZoomFactor来实现镜头变焦，
 方法二:修改AVCaptureConnection的缩放系数videoScaleAndCropFactor来实现镜头变焦。
 */
+ (void)focalizeAdjustVideoZoomFactor:(CGFloat )scale;
/** 切换摄像头 */
+(AVCaptureDeviceInput *)turnCamera:(AVCaptureSession *)session previewlayer:(CALayer *)previewlayer videoInput:(AVCaptureDeviceInput*)videoInput;
/** 切换闪光灯状态 */
+(void)config:(AVCaptureDevice *)device torchMode:(AVCaptureTorchMode)torchMode;
/** 改变流配置性 */
+(void)session:(AVCaptureSession *)session changeConfig:(void(^)(AVCaptureSession *captureSession))changeConfig;
/** 改变设备属性 */
+(void)device:(AVCaptureDevice *)device changeProperty:(void(^)(AVCaptureDevice *captureDevice))propertyChange;

/** 获取摄像头 */
+(AVCaptureDevice *)cameraDeviceWithPosition:(AVCaptureDevicePosition )position;
/** 获取音频麦克风 */
+(AVCaptureDevice *)microphone;
@end

NS_ASSUME_NONNULL_END
