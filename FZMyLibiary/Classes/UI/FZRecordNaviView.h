//
//  FZRecordNaviView.h
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/17.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FZRecordTimeView.h"

NS_ASSUME_NONNULL_BEGIN

@interface FZRecordNaviView : UIView

@property (nonatomic,strong) UIButton *cancelButton;
@property (nonatomic,strong) UIButton *cameraButton;
@property (nonatomic,strong) UIButton *flashButton;

@property (nonatomic,strong) FZRecordTimeView *timeView;

@end

NS_ASSUME_NONNULL_END
