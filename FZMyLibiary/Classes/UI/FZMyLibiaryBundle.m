//
//  FZMyLibiaryBundle.m
//  FZVideoPlayer
//
//  Created by 吴福增 on 2019/7/9.
//

#import "FZMyLibiaryBundle.h"

@implementation FZMyLibiaryBundle
 
+ (NSBundle *)fz_bundle{
    static NSBundle *bundle = nil;
    if (bundle == nil) {
        //frameworkBundle
        NSBundle *currentBundle = [NSBundle bundleForClass:[self class]];
        bundle = [NSBundle bundleWithPath:[currentBundle pathForResource:@"FZMyLibiary" ofType:@"bundle"]];
        if (bundle == nil) {
            //mainBundle
            NSBundle *mainBundle = [NSBundle mainBundle];
            bundle = [NSBundle bundleWithPath:[mainBundle pathForResource:@"FZMyLibiary" ofType:@"bundle"]];
        }
    }
    return bundle;
}

+ (UIImage *)fz_imageNamed:(NSString *)name {
    return [self fz_imageNamed:name ofType:nil];
}

+ (UIImage *)fz_imageNamed:(NSString *)name ofType:(nullable NSString *)type {
    if (name == nil) return nil;
    if ([UIImage respondsToSelector:@selector(imageNamed:inBundle:compatibleWithTraitCollection:)]) {
        //iOS8.0+ 有缓存
        return [UIImage imageNamed:name inBundle:[self fz_bundle] compatibleWithTraitCollection:nil];
    } else {
        //没有缓存
        UIImage *image;
        if (image) {
            image = [[UIImage imageWithContentsOfFile:[[self fz_bundle] pathForResource:[name stringByAppendingString:@"@2x"] ofType:type?:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            return image;
        }else{
            image = [[UIImage imageWithContentsOfFile:[[self fz_bundle] pathForResource:name ofType:type?:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            return image;
        }
    }
}

+ (NSString *)fz_localizedStringForKey:(NSString *)key{
    return [self fz_localizedStringForKey:key value:nil];
}

+ (NSString *)fz_localizedStringForKey:(NSString *)key value:(NSString *)value{
    static NSBundle *bundle = nil;
    if (bundle == nil) {
        // （iOS获取的语言字符串比较不稳定）目前框架只处理en、zh-Hans、zh-Hant三种情况，其他按照系统默认处理
        NSString *language = [NSLocale preferredLanguages].firstObject;
        
        if ([language hasPrefix:@"en"]) {
            language = @"en";
        } else if ([language hasPrefix:@"zh"]) {
            if ([language rangeOfString:@"Hans"].location != NSNotFound) {
                language = @"zh-Hans"; // 简体中文
            } else { // zh-Hant\zh-HK\zh-TW
                language = @"zh-Hant"; // 繁體中文
            }
        } else if ([language hasPrefix:@"ko"]) {
            language = @"ko";
        } else if ([language hasPrefix:@"ru"]) {
            language = @"ru";
        } else if ([language hasPrefix:@"uk"]) {
            language = @"uk";
        } else {
            language = @"en";
        }
        // 从MJRefresh.bundle中查找资源
        bundle = [NSBundle bundleWithPath:[[self fz_bundle] pathForResource:language ofType:@"lproj"]];
    }
    value = [bundle localizedStringForKey:key value:value table:nil];
    return [[NSBundle mainBundle] localizedStringForKey:key value:value table:nil];
}

@end
