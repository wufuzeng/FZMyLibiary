//
//  FZImageAlbumHandler.h
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/9.
//  图片相册

#import "FZAlbumHandler.h"
NS_ASSUME_NONNULL_BEGIN

@interface FZImageAlbumHandler : FZAlbumHandler

/** 选中图片 */
@property (strong, nonatomic) NSMutableArray<FZPHAsset *> *selectImages;
 


/** 取所有图片相册列表 */
+ (void)fetchPhotoAlbumListWithSelected:(NSArray<FZPHAsset *> *)phAssets
                       completedHandler:(void(^)(NSArray<FZPHAlbum *> *albums))completedHandler;

/** 操作相册中相同图片的选中 */
+ (void)handleSameImageForAlbum:(FZPHAlbum *)album ofAsset:(FZPHAsset *)phAsset setSelect:(BOOL)isSelect;
/** 取相册集内的所有图片媒体 */
+ (NSMutableArray<FZPHAsset *>*)fetchImageAssetsInAssetCollection:(PHAssetCollection *)assetCollection
                                                   ascending:(BOOL)ascending;

/**
 * 根据PHAsset获取图片(本地图片不存在,从云服务获取)
 *
 * @param asset PHAsset
 * @param isSynchronous 同步-YES 异步-NO
 * @param completion 返回图片
 */
+ (void)requestImageForAsset:(PHAsset *)asset
                 synchronous:(BOOL)isSynchronous
                  completion:(void (^)(UIImage *image))completion;
/** 操作选择 */
- (void)handleSelected:(FZPHAsset *)phAsset;



@end

NS_ASSUME_NONNULL_END
