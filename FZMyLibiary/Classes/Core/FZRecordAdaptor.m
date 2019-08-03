//
//  FZRecordAdaptor.m
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/1.
//

#import "FZRecordAdaptor.h"

@interface FZRecordAdaptor ()

@property (nonatomic,assign) CGFloat previewFrameRate;

@property (nonatomic,strong) NSMutableArray *previousSecondTimestamps;

@end

@implementation FZRecordAdaptor

-(NSMutableArray *)previousSecondTimestamps{
    if (_previousSecondTimestamps == nil) {
        _previousSecondTimestamps = [NSMutableArray array];
    }
    return _previousSecondTimestamps;
}

/** 计算当前时间戳的帧速率 */
- (void)calculateFramerateAtTimestamp:(CMTime)timestamp{
    [self.previousSecondTimestamps addObject:[NSValue valueWithCMTime:timestamp]];
    
    CMTime oneSecond = CMTimeMake( 1, 1 );
    CMTime oneSecondAgo = CMTimeSubtract( timestamp, oneSecond );
    
    while( CMTIME_COMPARE_INLINE( [self.previousSecondTimestamps[0] CMTimeValue], <, oneSecondAgo ) ) {
        [self.previousSecondTimestamps removeObjectAtIndex:0];
    }
    
    if ( [self.previousSecondTimestamps count] > 1 ) {
        const Float64 duration = CMTimeGetSeconds( CMTimeSubtract( [[self.previousSecondTimestamps lastObject] CMTimeValue], [self.previousSecondTimestamps[0] CMTimeValue] ) );
        const float newRate = (float)( [self.previousSecondTimestamps count] - 1 ) / duration;
        self.previewFrameRate = newRate;
        NSLog(@"FrameRate - %f", newRate);
    }
}


/*
 * CMSampleBufferRef转化UIImage的性能问题
 * 前一段时间在开发刷脸的过程中, 由于视频帧(CMSampleBufferRef -> UIImage)性能瓶颈导致,
 * 进行实时的人脸检测处理帧率太慢, 在性能较弱的机器比如iPhone4s, iPhone5中, 检测帧率太低(不到10fps),
 * 导致(动作活体, 反光活体)检测效果不好.
 *
 * 在检查了各个函数的运行时间以后,确定了问题出现的原因:
 * 视频帧 -> UIImage 方法耗时严重, 因此导致帧率下降.
 * 在优图原来使用的将视频帧 -> 图片的方法是用的CoreImage的函数, 具体代码如下:
 */

+(UIImage *)imageFromImageBuffer:(CVImageBufferRef)imageBuffer{
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    
    CGImageRef videoImage = [[CIContext context]
                             createCGImage:ciImage
                             fromRect:CGRectMake(0, 0,
                                                 CVPixelBufferGetWidth(imageBuffer),
                                                 CVPixelBufferGetHeight(imageBuffer))];
    
    UIImage *image = [[UIImage alloc] initWithCGImage:videoImage scale:1.0f orientation:UIImageOrientationUpMirrored];
    CGImageRelease(videoImage);
    return image;
}
/*
 * 在使用该方法每帧数据耗时达100+ms, 因此单位时间内处理例如转化后的UIImage图像时, 检测处理帧率会大幅减少,
 * 测试结果显示,iPhone5上动作检测只有10fps.
 * camera360的一个同行给出建议,切换成CoreGraphic相关函数能够大幅降低处理时间, 具体代码如下:
 */
/*
 * 使用新方法以后, 每帧由视频帧->图片的处理时间降低一个数量级, 在10ms左右, 大大提升了单位时间检测效率.
 * CoreGraphic的应用很广泛, 基本是iOS中图像绘制最棒的框架, 通常我们调整UIImage,例如改变大小宽度,旋转重绘等等都会使用它.
 * 同时我们自定义控件, 例如创建一个圆形进度条 - progressView,
 * 时候我们往往在drawRect中绘制当前进度等等.
 */
+(UIImage *)imageFromCGImageRef:(CGImageRef)cgImageRef{
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:cgImageRef];
    // 释放Quartz image对象
    CGImageRelease(cgImageRef);
    return image;
}

+(CGImageRef)cgImageRefFromSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // 释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return quartzImage;
}


 





@end
