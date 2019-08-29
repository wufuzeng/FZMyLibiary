//
//  FZImageAlbumHandler.m
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/9.
//

#import "FZImageAlbumHandler.h"

@interface FZImageAlbumHandler ()

@end

@implementation FZImageAlbumHandler
 

/** 取所有图片相册列表 */
+ (void)fetchPhotoAlbumListWithSelected:(NSArray<FZPHAsset *> *)phAssets
                       completedHandler:(void(^)(NSArray<FZPHAlbum *> *albums))completedHandler{
    /** 所有相册 */
    NSMutableArray<FZPHAlbum *> * allAlbums = [NSMutableArray array];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //获取所有智能相册
        PHFetchResult *smartAlbums =
        [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                 subtype:PHAssetCollectionSubtypeAlbumRegular
                                                 options:nil];

        [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL *stop) {
            //过滤掉视频和最近删除
            if(collection.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumVideos &&
               collection.assetCollectionSubtype < 212){
                
                NSArray<FZPHAsset *> *assets = [self fetchImageAssetsInAssetCollection:collection ascending:NO];
                
                if (assets.count) {
                    FZPHAlbum *album = [FZPHAlbum new];
                    album.assetCollection = collection;
                    album.title  = collection.localizedTitle;
                    album.assets = assets;
                    album.count  = assets.count;
                    //处理上次选择的图片
                    if (phAssets.count) {
                        for (FZPHAsset *phAsset in phAssets) {
                            [self handleSameImageForAlbum:album ofAsset:phAsset setSelect:YES];
                        }
                    }
                    [allAlbums addObject:album];
                }
            }
        }];
        
        //获取用户创建的相册
        PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        
        [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSArray<FZPHAsset *> *assets = [self fetchImageAssetsInAssetCollection:collection ascending:NO];
            
            if (assets.count > 0) {
                FZPHAlbum *album = [FZPHAlbum new];
                album.assetCollection =collection;
                album.title  = collection.localizedTitle;
                album.assets = assets;
                album.count  = assets.count;
                //处理上次选择的图片
                if (phAssets.count > 0) {
                    for (FZPHAsset *phAsset in phAssets) {
                        [self handleSameImageForAlbum:album ofAsset:phAsset setSelect:YES];
                    }
                }
                [allAlbums addObject:album];
            }
        }];
        
        NSInteger firstIndex = -1;
        for (int i = 0; i < allAlbums.count; i ++) {
            FZPHAlbum *albumModel = allAlbums[i];
            if ([albumModel.title isEqualToString:@"相机胶卷"]||
                [albumModel.title isEqualToString:@"所有照片"]){
                firstIndex = i;
                break;
            }
        }
        if (firstIndex > 0) {
            /** 移到首位 */
            FZPHAlbum *albumModel = allAlbums[firstIndex];
            [allAlbums removeObjectAtIndex:firstIndex];
            [allAlbums insertObject:albumModel atIndex:0];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completedHandler) {
                completedHandler(allAlbums.copy);
            }
        });
    });
}

/** 操作相册中相同图片的选中 */
+ (void)handleSameImageForAlbum:(FZPHAlbum *)album ofAsset:(FZPHAsset *)phAsset setSelect:(BOOL)isSelect{
    NSString *preStr = [NSString stringWithFormat:@"asset.localIdentifier == '%@'",phAsset.asset.localIdentifier];
    NSPredicate *pred = [NSPredicate predicateWithFormat:preStr];
    NSArray *preArr = [album.assets filteredArrayUsingPredicate:pred];
    if (preArr.count) {
        for (FZPHAsset *phAsset in preArr) {
            phAsset.isSelected = isSelect;
            isSelect ? album.selectedCount++ : album.selectedCount--;
        }
    }
}

/** 取相册集内的所有图片媒体 */
+ (NSMutableArray<FZPHAsset *>*)fetchImageAssetsInAssetCollection:(PHAssetCollection *)assetCollection
                                                   ascending:(BOOL)ascending {
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    option.sortDescriptors = @[
                               [NSSortDescriptor sortDescriptorWithKey:@"modificationDate"
                                                             ascending:ascending]
                               ];
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:option];
    NSMutableArray<FZPHAsset *> *arr = [NSMutableArray array];
    [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (((PHAsset *)obj).mediaType == PHAssetMediaTypeImage) {
            FZPHAsset *temp = [FZPHAsset new];
            temp.asset = obj;
            [arr addObject:temp];
        } else {
            NSLog(@"不属于图片-PHAssetMediaTypeImage");
        }
    }];
    return arr;
}

/**
 * 根据PHAsset获取图片
 *
 * @param asset PHAsset
 * @param isSynchronous 同步-YES 异步-NO
 * @param completion 返回图片
 */
+ (void)requestImageForAsset:(PHAsset *)asset
                 synchronous:(BOOL)isSynchronous
                  completion:(void (^)(UIImage *image))completion {
    
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeExact;//控制照片尺寸
    option.networkAccessAllowed = YES;
    option.synchronous = isSynchronous;
    CGFloat width  = (CGFloat)asset.pixelWidth;
    CGFloat height = (CGFloat)asset.pixelHeight;
    CGFloat scale  = width/height;
    CGFloat HEIGHT = [UIScreen mainScreen].bounds.size.height;
    CGSize  size   = CGSizeMake(HEIGHT * scale, HEIGHT);
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeDefault options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (isSynchronous) {
            if ([info[@"PHImageResultIsDegradedKey"] boolValue] == NO) {
                completion(result);
            }
        } else {
            completion(result);
        }
    }];
}

/** 操作选择 */
- (void)handleSelected:(FZPHAsset *)phAsset{
    if (phAsset.isSelected) {
        NSString *preStr = [NSString stringWithFormat:@"asset.localIdentifier == '%@'",phAsset.asset.localIdentifier];
        NSPredicate *pred = [NSPredicate predicateWithFormat:preStr];
        NSArray *preArr = [self.selectImages filteredArrayUsingPredicate:pred];
        if (preArr.count) {
            NSMutableArray *phAssets = [NSMutableArray array];
            for (FZPHAsset *obj in preArr) {
                obj.isSelected = NO;
                [phAssets addObject:obj];
            }
            [self.selectImages removeObjectsInArray:phAssets];
        }
    } else {
        [self.selectImages addObject:phAsset];
    }
}


#pragma  mark -- Tool Func ---




#pragma mark -- Lazy Func ---

/** 选中图片 */
-(NSMutableArray *)selectImages{
    if (_selectImages == nil) {
        _selectImages = [NSMutableArray array];
    }
    return _selectImages;
}


@end
