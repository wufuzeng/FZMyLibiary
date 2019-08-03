//
//  FZRecordEngine.h
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/18.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
//NS_ASSUME_NONNULL_BEGIN

/** 录制状态 */
typedef NS_ENUM(NSInteger, FZRecordStatus) {
    FZRecordStatusInit = 0,  //初始化
    FZRecordStatusPrepare,   //准备录制
    FZRecordStatusRecording, //正在录制
    FZRecordStatusPaused,    //暂停
    FZRecordStatusResuming,  //继续
    FZRecordStatusFinished,  //完成
};

@class FZRecordEngine;
@protocol FZRecordEngineDelegate <NSObject>

/** 录制进度 */
-(void)recorder:(FZRecordEngine *)recorder recordProgress:(CGFloat)progress;
/** 录制完成 */
-(void)recorder:(FZRecordEngine *)recorder didCompleteWithSuccess:(BOOL)success error:(NSError *)error;

@end

@interface FZRecordEngine : NSObject

@property (nonatomic, weak) id<FZRecordEngineDelegate> delegate;
/**
 * 预览层
 * 需要实时显示处理过的视频流,需自定义一个layer显示,否则用系统的AVCaptureVideoPreviewLayer */
@property (nonatomic, strong) CALayer *previewlayer;
/** 闪光动模式 */
@property (nonatomic, assign) AVCaptureTorchMode torchMode;
/** 录制最长时间 */
@property (atomic, assign) CGFloat maxRecordTime;
 

/** 启动录制功能 */
- (void)startUp;
/** 关闭录制功能 */
- (void)shutDown;

/** 开始录制 */
-(void)startRecord;
/** 暂停录制 */
-(void)pauseRecord;
/** 停止录制 */
-(void)stopRecord;


/** 切换摄像头 */
-(void)turnCamera;

/** 设置设备聚焦点 */
-(void)configFocusMode:(AVCaptureFocusMode)focusMode
          exposureMode:(AVCaptureExposureMode)exposureMode
               atPoint:(CGPoint)point;


@end

//NS_ASSUME_NONNULL_END
