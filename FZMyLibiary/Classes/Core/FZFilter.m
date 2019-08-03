//
//  FZFilter.m
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/3.
//

#import "FZFilter.h"

@implementation FZFilter
/**
 * 苹果给我们提供了将近200中滤镜效果
 */
+(void)allCoreImageFilters{
    // 这里我们可以看到总共有多少种滤镜
    NSArray *filterNames = [CIFilter filterNamesInCategory:@"CICategoryBuiltIn"];            NSLog(@"总共有%ld种滤镜效果:%@",(long)filterNames.count,filterNames);
    //以一个具体分类中的滤镜信息
    NSArray* filters =  [CIFilter filterNamesInCategory:kCICategoryDistortionEffect];
    for (NSString* filterName in filters) {
        NSLog(@"filter name:%@",filterName);
        // 我们可以通过filterName创建对应的滤镜对象
        CIFilter* filter = [CIFilter filterWithName:filterName];
        NSDictionary* attributes = [filter attributes];
        //获取属性键/值对（在这个字典中我们可以看到滤镜的属性以及对应的key）
        NSLog(@"filter attributes:%@",attributes);
        
    }
}

+(CIImage *)outputImageWithFilter:(CIFilter *)filter inputImage:(CIImage *)inputImage{
    [filter setDefaults];
    //通过KVC来设置参数
    /** [filter setValue:oldImg forKey:@"inputImage"]; */    
    [filter setValue:inputImage forKey:kCIInputImageKey];
    return filter.outputImage;
}

+(CIFilter *)CoreImageFilter:(FZCoreImageFilterType)filter{
    switch (filter) {
        case FZCoreImageFilterTypeNoir:
            return [CIFilter filterWithName:@"CIPhotoEffectNoir"];
        case FZCoreImageFilterTypeTransfer:
            return [CIFilter filterWithName:@"CIPhotoEffectTransfer"];
        case FZCoreImageFilterTypeMono:
            return [CIFilter filterWithName:@"CIPhotoEffectMono"];
        case FZCoreImageFilterTypeInstant:
            return [CIFilter filterWithName:@"CIPhotoEffectInstant"];
        case FZCoreImageFilterTypeTonal:
            return [CIFilter filterWithName:@"CIPhotoEffectTonal"];
        case FZCoreImageFilterTypeFade:
            return [CIFilter filterWithName:@"CIPhotoEffectFade"];
        case FZCoreImageFilterTypeProcess:
            return [CIFilter filterWithName:@"CIPhotoEffectProcess"];
        case FZCoreImageFilterTypeChrome:
            return [CIFilter filterWithName:@"CIPhotoEffectChrome"];
        default:return nil;
    }
}



/** 给人脸添加马赛克 */
+(CIImage *)faceImage:(CIImage *)faceImage faceObject:(AVMetadataFaceObject *)faceDataObject{
    
    CIFilter *faceFilter = [CIFilter filterWithName:@"CIPixellate"];
    [faceFilter setValue:faceImage forKey:kCIInputImageKey];
    [faceFilter setValue:@(MAX(faceImage.extent.size.width, faceImage.extent.size.height)/120) forKey:kCIInputScaleKey];
    
    CIImage *fullPixelImage = faceFilter.outputImage;
    CIImage *maskImage;
    
    CGRect faceBounds = faceDataObject.bounds;
    
    CGFloat centerX = faceImage.extent.size.width * (faceBounds.origin.x + faceBounds.size.width /2.0);
    CGFloat centerY = faceImage.extent.size.height* (faceBounds.origin.y + faceBounds.size.height/2.0);
    CGFloat radius  = faceBounds.size.width       * faceImage.extent.size.width / 2.0;
    
    // http://blog.csdn.net/qqyinzhe/article/details/51523494
    CIFilter *radialFilter = [CIFilter filterWithName:@"CIRadialGradient"
                                  withInputParameters:@{
                                                        @"inputRadius0":[NSNumber numberWithFloat:radius],
                                                        @"inputRadius1":[NSNumber numberWithFloat:radius + 1],
                                                        @"inputColor0":[CIColor colorWithRed:0 green:1 blue:0 alpha:1],
                                                        @"inputColor1":[CIColor colorWithRed:0 green:0 blue:0 alpha:0],
                                                        kCIInputCenterKey:[CIVector vectorWithX:centerX Y:centerY]}];
    CIImage *radialGradientOutputImage = [radialFilter.outputImage imageByCroppingToRect:faceImage.extent];
    if (!maskImage){
        maskImage = radialGradientOutputImage;
    }else{
        // @"CISourceOverCompositing": 源覆盖
        maskImage = [CIFilter filterWithName:@"CISourceOverCompositing"
                         withInputParameters:@{
                                               kCIInputImageKey:radialGradientOutputImage,
                                               kCIInputBackgroundImageKey:maskImage
                                               }].outputImage;
    }
    // 混合操作: CIBlendWithAlphaMask和CIBlendWithMask允许将两个图像合并成一个
    CIFilter *blendFilter = [CIFilter filterWithName:@"CIBlendWithMask"];
    
    [blendFilter setValue:fullPixelImage forKey:kCIInputImageKey];
    [blendFilter setValue:faceImage forKey:kCIInputBackgroundImageKey];
    [blendFilter setValue:maskImage forKey:kCIInputMaskImageKey];
    
    return blendFilter.outputImage;
}


@end
