//
//  FZPHAlbum.h
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/9.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "FZPHAsset.h"
NS_ASSUME_NONNULL_BEGIN

/*
 * |-PhotoAlbum
 * |  |—smartAlbums(智能定义)
 * |  |  |-Album(智能定义相册名)
 * |  |  |  |—PHAsset
 * |  |  |  |—AVURLAsset
 * |  |
 * |  |—userAlbums(用户定义)
 * |  |  |-Album(用户定义相册名)
 * |  |  |  |—PHAsset
 * |  |  |  |—AVURLAsset
 *
 *
 * |-FZPHAlbum (album Of smartAlbums / userAlbums)
 * |  |—FZPHAsset
 * |  |   |—PHAsset
 * |  |   |—AVURLAsset
 */

@interface FZPHAlbum : NSObject
//所属相册集
@property (nonatomic,strong) PHAssetCollection *assetCollection;
//相册名称
@property (nonatomic,strong) NSString *title;
//资源(图片/视频)集
@property (nonatomic,strong) NSArray<FZPHAsset *> *assets;
//相册内资源数 assets.count
@property (nonatomic,assign) NSInteger count;
//在该相册中选择了多少张图片
@property (nonatomic,assign) NSInteger selectedCount;

@end

NS_ASSUME_NONNULL_END
