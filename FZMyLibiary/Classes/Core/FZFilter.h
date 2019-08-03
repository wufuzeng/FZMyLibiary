//
//  FZFilter.h
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/3.
//

/**
 使用苹果自带的CoreImage框架对图片进行处理，
 用CoreImage框架里的CIFilter对图片进行滤镜处理，
 首先我们应该了解下CoreImage框架能够对图像进行那些处理和拥有哪些特效
 苹果iOS官方文档:
 https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html#//apple_ref/doc/uid/TP30000136-SW29
 */

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FZCoreImageFilterType){
    FZCoreImageFilterTypeNoir     = 0,// 黑白
    FZCoreImageFilterTypeTransfer = 1,// 岁月
    FZCoreImageFilterTypeMono     = 2,// 单色
    FZCoreImageFilterTypeInstant  = 3,// 怀旧
    FZCoreImageFilterTypeTonal    = 4,// 色调
    FZCoreImageFilterTypeFade     = 5,// 褪色
    FZCoreImageFilterTypeProcess  = 6,// 冲印
    FZCoreImageFilterTypeChrome   = 7,// 铬黄 
};

typedef NS_ENUM(NSUInteger, FZGPUImageFilterType){
   FZGPUImageFilterNormal    = 0  
};


@interface FZFilter : NSObject
/** Core Image Filter */
+(CIFilter *)CoreImageFilter:(FZCoreImageFilterType)filter;

/** 给人脸添加马赛克 */
+(CIImage *)faceImage:(CIImage *)faceImage faceObject:(AVMetadataFaceObject *)faceDataObject;

@end

NS_ASSUME_NONNULL_END
