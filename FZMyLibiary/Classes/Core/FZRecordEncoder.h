//
//  FZRecordEncoder.h
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/18.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FZWriteStatus) {
    FZWriteStatusInit = 0,
    FZWriteStatusPrepare,
    FZWriteStatusWriting,
    FZWriteStatusCompleted,
    FZWriteStatusFailed,
};

//荧幕的长宽比
typedef NS_ENUM(NSInteger, FZCanvasScale) {
    FZCanvasScale1X1 = 0,
    FZCanvasScale4X3,
    FZCanvasScale9X16,
    FZCanvasScale16X9
};

@interface FZRecordEncoder : NSObject
/** 音频通道 */
@property (nonatomic,assign) NSInteger channels;
/** 音频采样率 */
@property (nonatomic,assign) Float64 samplerate;
/* 视频大小 */
@property (nonatomic,assign) CMVideoDimensions videoDimensions;
/** 显示比例 */
@property (nonatomic,assign) FZCanvasScale canvasScale;
/** 输出size */
@property (nonatomic,assign) CGSize outputSize;
/** 创建写入对象 */ 
-(BOOL)creatWriter;
/** 准备写入 */
- (void)prepareWrite;
/** 停止 */
- (void)stopWriteWithCompletionHandler:(nullable void(^)(BOOL success, NSError *__nullable error))handler;
/** 追加缓存数据 */
- (void)appendBuffer:(CMSampleBufferRef)sampleBuffer ciImage:(CIImage *_Nullable)ciImage type:(NSString *)mediaType; 


@end

NS_ASSUME_NONNULL_END
