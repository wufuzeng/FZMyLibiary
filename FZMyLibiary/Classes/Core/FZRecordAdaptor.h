//
//  FZRecordAdaptor.h
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/1.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface FZRecordAdaptor : NSObject

/** Core Image 【CPU】*/
+(UIImage *)imageFromImageBuffer:(CVImageBufferRef)imageBuffer;
/** Core Graphic 【GPU】性能比上面好 */
+(UIImage *)imageFromCGImageRef:(CGImageRef)cgImageRef;
+(CGImageRef)cgImageRefFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;

 
@end

NS_ASSUME_NONNULL_END
