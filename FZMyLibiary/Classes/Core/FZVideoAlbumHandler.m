//
//  FZVideoAlbumHandler.m
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/9.
//

#import "FZVideoAlbumHandler.h"

@implementation FZVideoAlbumHandler

/** 取所有视频相册列表 */
+ (void)fetchVideoAlbumListWithSelected:(NSArray<FZPHAsset *> *)phAssets
                      completedHandler:(void(^)(NSArray<FZPHAlbum *> *albums))completedHandler{
    
    NSMutableArray *allAlbums = [NSMutableArray array];
    //获取所有智能相册
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL *stop) {
        NSArray<FZPHAsset *> *assets = [self fetchVideoAssetsInAssetCollection:collection ascending:NO];
        //去掉最近删除
        if(collection.assetCollectionSubtype < 212){
            if (assets.count > 0) {
                FZPHAlbum *album = [FZPHAlbum new];
                album.title = collection.localizedTitle;
                album.assets = assets;
                album.assetCollection = collection;
                album.count = assets.count;
                //处理上次选择的视频
                if (phAssets.count) {
                    for (FZPHAsset *phAsset in phAssets) {
                        [self handleSameVideoForAlbum:album ofAsset:phAsset setSelect:YES];
                    }
                }
                [allAlbums addObject:album];
            }
        }
    }];
    
    //获取用户创建的相册
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<FZPHAsset *> *assets = [self fetchVideoAssetsInAssetCollection:collection ascending:NO];
        if (assets.count > 0) {
            FZPHAlbum *album = [FZPHAlbum new];
            album.assetCollection =collection;
            album.title = collection.localizedTitle;
            album.assets = assets;
            album.count = assets.count;
            //处理上次选择的视频
            if (phAssets.count) {
                for (FZPHAsset *phAsset in phAssets) {
                    [self handleSameVideoForAlbum:album ofAsset:phAsset setSelect:YES];
                }
            }
            [allAlbums addObject:album];
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completedHandler) {
            completedHandler(allAlbums.copy);
        }
    });
    
}

/** 取相册集内的所有视频媒体 */
+ (NSMutableArray<FZPHAsset *>*)fetchVideoAssetsInAssetCollection:(PHAssetCollection *)assetCollection
                                                        ascending:(BOOL)ascending {
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    option.sortDescriptors = @[
                               [NSSortDescriptor sortDescriptorWithKey:@"modificationDate"
                                                             ascending:ascending]
                               ];
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:option];
    NSMutableArray<FZPHAsset *> *arr = [NSMutableArray array];
    [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (((PHAsset *)obj).mediaType == PHAssetMediaTypeVideo) {
            FZPHAsset *temp = [FZPHAsset new];
            temp.asset = obj;
            [arr addObject:temp];
        } else {
            NSLog(@"不属于图片-PHAssetMediaTypeImage");
        }
    }];
    return arr;
}
/** 操作相册中相同视频媒体的选中 */
+(void)handleSameVideoForAlbum:(FZPHAlbum *)album ofAsset:(FZPHAsset *)phAsset setSelect:(BOOL)isSelect{
    NSString *preStr = [NSString stringWithFormat:@"asset.localIdentifier == '%@'",phAsset.asset.localIdentifier];
    NSPredicate *pred = [NSPredicate predicateWithFormat:preStr];
    NSArray *preArr = [album.assets filteredArrayUsingPredicate:pred];
    if (preArr.count > 0) {
        for (FZPHAsset *obj in preArr) {
            obj.isSelected = isSelect;
            isSelect ? album.selectedCount++ : album.selectedCount--;
        }
    }
}

/**
 * 根据PHAsset获取视频(本地不存在,从云获取)
 *
 * @param asset PHAsset
 * @param completion AVURLAsset
 */
+ (void)requestVideoForAsset:(PHAsset *)asset
                  completion:(void (^)(AVURLAsset *localUrlAsset))completion{
    PHVideoRequestOptions *option = [[PHVideoRequestOptions alloc] init];
    option.version = PHVideoRequestOptionsVersionCurrent;
    option.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    option.networkAccessAllowed = YES;
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset
                                                    options:option
                                              resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
          AVURLAsset *localUrlAsset = (AVURLAsset *)asset;
          completion(localUrlAsset);
    }];
}



@end
