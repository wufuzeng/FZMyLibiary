//
//  FZAlbumHandler.m
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/9.
//

#import "FZAlbumHandler.h"

@implementation FZAlbumHandler

/**
 * 相册授权
 *
 * @param ctrl 当前控制器
 * @param completedHandler 返回是否允许访问
 */
+ (void)photoLibraryAuthorizationStatus:(UIViewController *)ctrl
                       completedHandler:(void (^)(BOOL allowAccess))completedHandler {
    
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    if (authStatus == PHAuthorizationStatusNotDetermined) {//没授权- 开始授权
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completedHandler) {
                    completedHandler(status == PHAuthorizationStatusAuthorized);
                }
            });
        }];
    } else {
        if (completedHandler) {
            completedHandler(authStatus == PHAuthorizationStatusAuthorized);
        }
        if (authStatus != PHAuthorizationStatusAuthorized) {
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            NSString *app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
            NSString *alertTitle;
            if (authStatus == 1) {
                alertTitle = @"未知原因导致相册不允许访问";
            } else {
                alertTitle = [NSString stringWithFormat:@"你拒绝了%@访问相册，请到设置-%@中打开相册访问权限",app_Name,app_Name];
            }
            [FZAlbumHandler authorizationAlert:ctrl tipMessage:alertTitle];
        }
    }
}

/**
 * 相机授权
 *
 * @param ctrl 当前控制器
 * @param completedHandler 返回是否允许访问
 */
+ (void)cameraAuthorizationStatus:(UIViewController *)ctrl
                    completedHandler:(void (^)(BOOL allowAccess))completedHandler {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (authStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completedHandler) {
                    completedHandler(granted);
                }
            });
        }];
    } else {
        if (completedHandler) {
            completedHandler(authStatus == AVAuthorizationStatusAuthorized);
        }
        if (authStatus != AVAuthorizationStatusAuthorized) {
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            NSString *app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
            NSString *alertTitle;
            if (authStatus == 1) {
                alertTitle = @"未知原因导致相机不允许访问";
            } else {
                alertTitle = [NSString stringWithFormat:@"你拒绝了%@访问相机，请到设置-%@中打开相机访问权限",app_Name,app_Name];
            }
            [FZAlbumHandler authorizationAlert:ctrl tipMessage:alertTitle];
        }
    }
}

/**
 麦克风授权
 
 @param ctrl 当前控制器
 @param completedHandler 返回是否允许访问
 */
+ (void)requestRecordPermission:(UIViewController *)ctrl
               completedHandler:(void (^)(BOOL allowAccess))completedHandler {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completedHandler) {
                    completedHandler(granted);
                }
                if (granted) {
                    NSLog(@"接受麦克风授权");
                } else {
                    NSLog(@"拒绝麦克风授权");
                    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
                    NSString *app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
                    NSString *alertTitle = [NSString stringWithFormat:@"你拒绝了%@访问麦克风，请到设置-%@中打开麦克风访问权限",app_Name,app_Name];
                    [FZAlbumHandler authorizationAlert:ctrl tipMessage:alertTitle];
                }
            });
        }];
    }
}



/**
 * 授权提示弹出框
 *
 * @param ctrl 当前控制器
 * @param title 提示语
 */
+ (void)authorizationAlert:(UIViewController *)ctrl
                tipMessage:(NSString *)title {
    
    __block UIViewController *currentCtrl = ctrl;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:title preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *set = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        });
    }];
    [alert addAction:set];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (currentCtrl.presentingViewController) {
                [currentCtrl dismissViewControllerAnimated:YES completion:nil];
            } else {
                [currentCtrl.navigationController popViewControllerAnimated:YES];
            }
        });
    }];
    [alert addAction:cancel];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [ctrl presentViewController:alert animated:YES completion:nil];
    });
}




/**
 * 图片保存到系统相册
 *
 * @param image 图片
 * @param completionHandler 返回结果
 */
+ (void)saveImageToLibraryForImage:(UIImage *)image
                   completeHandler:(void(^)(NSString *localIdentifier, BOOL isSuccess))completionHandler {
    __block NSString *localIdentifier;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        localIdentifier = req.placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"success = %d, error = %@", success, error);
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(localIdentifier, success);
            });
        }
    }];
}


/**
 * 视频保存到系统相册
 *
 * @param path 视频路径
 * @param completionHandler 返回结果
 */
+ (void)saveVideoToLibraryForPath:(NSString *)path
                     completeHandler:(void(^)(NSString *localIdentifier, BOOL isSuccess))completionHandler {
    __block NSString *localIdentifier;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL URLWithString:path]];
        localIdentifier = req.placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"success = %d, error = %@", success, error);
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(localIdentifier, success);
        });
    }];
}

/**
 * 根据相册localid获取PHAsset
 *
 * @param localIdentifier 相册id
 * @param completionHandler 返回PHAsset对象
 */
+ (void)getAssetForLocalIdentifier:(NSString *)localIdentifier
                 completionHandler:(void(^)(PHAsset *kj_object))completionHandler {
    PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
    [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (obj) {
                completionHandler(obj);
            }
        });
        *stop = YES;
    }];
}

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
             completeHandler:(void(^)(NSError *error))completeHandler {
    AVAssetExportSession *export = [AVAssetExportSession exportSessionWithAsset:asset
                                                                        presetName:presetName];
    export.outputURL = savePath;
    export.outputFileType = AVFileTypeMPEG4;
    export.shouldOptimizeForNetworkUse = YES;
    [export exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (export.status == AVAssetExportSessionStatusCompleted) {
                if (completeHandler) {
                    completeHandler(nil);
                }
            } else if (export.status == AVAssetExportSessionStatusFailed) {
                if (completeHandler) {
                    completeHandler(export.error);
                }
            } else {
                NSLog(@"当前压缩进度:%f",export.progress);
            }
        });
    }];
}



@end
