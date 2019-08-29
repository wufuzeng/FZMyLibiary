//
//  FZVideoAlbumHandler.h
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/9.
//

#import "FZAlbumHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface FZVideoAlbumHandler : FZAlbumHandler
/** 取所有视频相册列表 */
+ (void)fetchVideoAlbumListWithSelected:(NSArray<FZPHAsset *> *)phAssets
                       completedHandler:(void(^)(NSArray<FZPHAlbum *> *albums))completedHandler;

/** 取相册集内的所有视频媒体 */
+ (NSMutableArray<FZPHAsset *>*)fetchVideoAssetsInAssetCollection:(PHAssetCollection *)assetCollection
                                                        ascending:(BOOL)ascending;
/** 操作相册中相同视频媒体的选中 */
+(void)handleSameVideoForAlbum:(FZPHAlbum *)album ofAsset:(FZPHAsset *)phAsset setSelect:(BOOL)isSelect;

/**
 * 根据PHAsset获取视频(本地不存在,从云获取)
 *
 * @param asset PHAsset
 * @param completion AVURLAsset
 */
+ (void)requestVideoForAsset:(PHAsset *)asset
                  completion:(void (^)(AVURLAsset *localUrlAsset))completion;

@end

NS_ASSUME_NONNULL_END
