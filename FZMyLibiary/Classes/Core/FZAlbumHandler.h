//
//  FZAlbumHandler.h
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/9.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "FZPHAlbum.h"
#import "FZPHAsset.h"
NS_ASSUME_NONNULL_BEGIN

@interface FZAlbumHandler : NSObject
 
/**
 * 相册授权
 *
 * @param ctrl 当前控制器
 * @param completedHandler 返回是否允许访问
 */
+ (void)photoLibraryAuthorizationStatus:(UIViewController *)ctrl
                       completedHandler:(void (^)(BOOL allowAccess))completedHandler;

/**
 * 图片保存到系统相册
 *
 * @param image 图片
 * @param completionHandler 返回结果
 */
+ (void)saveImageToLibraryForImage:(UIImage *)image
                   completeHandler:(void(^)(NSString *localIdentifier, BOOL isSuccess))completionHandler;


/**
 * 视频保存到系统相册
 *
 * @param path 视频路径
 * @param completionHandler 返回结果
 */
+ (void)saveVideoToLibraryForPath:(NSString *)path
                  completeHandler:(void(^)(NSString *localIdentifier, BOOL isSuccess))completionHandler;


/**
 * 根据相册localid获取PHAsset
 *
 * @param localIdentifier 相册id
 * @param completionHandler 返回PHAsset对象
 */
+ (void)getAssetForLocalIdentifier:(NSString *)localIdentifier
                 completionHandler:(void(^)(PHAsset *kj_object))completionHandler;

/**
 * 视频转码/压缩
 *
 * @param asset AVAsset
 * @param presetName 视频质量（建议压缩使用AVAssetExportPresetMediumQuality，存相册AVAssetExportPreset1920x1080，根据需求设置）
 * @param savePath 保存的路径
 * @param completeHandler 返回状态
 */
+ (void)compressedVideoAsset:(AVAsset *)asset
                  presetName:(NSString *)presetName
                    savePath:(NSURL *)savePath
             completeHandler:(void(^)(NSError *error))completeHandler;
@end

NS_ASSUME_NONNULL_END
