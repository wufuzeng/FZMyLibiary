//
//  FZRecordControlView.h
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/17.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FZRecordNaviView.h"
#import "FZRecordToolView.h"

NS_ASSUME_NONNULL_BEGIN

@class FZRecordControlView;

@protocol FZRecordControlViewDelegate <NSObject>
/** 取消 */
-(void)control:(FZRecordControlView *)control cancelAction:(UIButton *)sender;
/** 切换相机 */
-(void)control:(FZRecordControlView *)control turnCameraAction:(UIButton *)sender;
/** 切换闪光灯模式 */
-(void)control:(FZRecordControlView *)control switchTorchModelAction:(UIButton *)sender;
/** 聚焦点 */
-(void)control:(FZRecordControlView *)control focusGestureAction:(UITapGestureRecognizer *)sender;
/** 录制 */
-(void)control:(FZRecordControlView *)control recordAction:(UIButton *)sender;

@end


@interface FZRecordControlView : UIView

@property (nonatomic,weak) id<FZRecordControlViewDelegate> delegate;

@property (nonatomic,strong) FZRecordNaviView *naviView;
@property (nonatomic,strong) FZRecordToolView *toolView;
@end

NS_ASSUME_NONNULL_END
