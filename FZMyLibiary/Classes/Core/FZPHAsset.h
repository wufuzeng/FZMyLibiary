//
//  FZPHAsset.h
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/9.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
NS_ASSUME_NONNULL_BEGIN

@interface FZPHAsset : NSObject

/** 是否选中 */
@property (assign, nonatomic) BOOL isSelected;
/** 媒体 */
@property (strong, nonatomic) PHAsset *asset;
/** 本地图片 */
@property (strong, nonatomic) UIImage *localImage;
/** 本地视频媒体 */
@property (strong, nonatomic) AVURLAsset *localUrlAsset;

@end

NS_ASSUME_NONNULL_END
