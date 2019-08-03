//
//  FZAVPlayerBundle.h
//  FZVideoPlayer
//
//  Created by 吴福增 on 2019/7/9.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FZMyLibiaryBundle : NSBundle

+ (UIImage *)fz_imageNamed:(NSString *)name;

+ (UIImage *)fz_imageNamed:(NSString *)name ofType:(nullable NSString *)type;

+ (NSString *)fz_localizedStringForKey:(NSString *)key;


@end

NS_ASSUME_NONNULL_END
