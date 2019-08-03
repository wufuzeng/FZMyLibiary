//
//  FZRecordView.m
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/17.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

#import "FZRecordView.h"

#import "FZRecordEngine.h"
#import "FZRecordControlView.h"
#import "FZMyLibiaryBundle.h"
@interface FZRecordView ()
<
FZRecordControlViewDelegate,
FZRecordEngineDelegate
>

@property (nonatomic,strong) FZRecordEngine *recordEngine;
@property (nonatomic,strong) FZRecordControlView *controlView;

@end

@implementation FZRecordView

#pragma mark -- Life Cycle Func ----

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupInit];
        [self setupViews];
    }
    return self;
}

-(void)setupInit{ 
    [self.recordEngine startUp];
}

-(void)setupViews{
    [self controlView];
}

-(void)dealloc{
    [self.recordEngine shutDown];
}

#pragma mark -- FZRecordControlViewDelegate ----------

/** 取消 */
-(void)control:(FZRecordControlView *)control cancelAction:(UIButton *)sender{
    [self.recordEngine shutDown];
    
    if ([self.delegate respondsToSelector:@selector(record:cancelAction:)]) {
        [self.delegate record:self cancelAction:sender];
    }
}
/** 切换相机 */
-(void)control:(FZRecordControlView *)control turnCameraAction:(UIButton *)sender{
    [self.recordEngine turnCamera];
}
/** 切换闪光灯模式 */
-(void)control:(FZRecordControlView *)control switchTorchModelAction:(UIButton *)sender{
    self.recordEngine.torchMode += 1;
    switch (self.recordEngine.torchMode) {
        case AVCaptureTorchModeOff:{
            [sender setImage:[FZMyLibiaryBundle fz_imageNamed:@"listing_flash_off"] forState:UIControlStateNormal];
            break;}
        case AVCaptureTorchModeOn:{
            [sender setImage:[FZMyLibiaryBundle fz_imageNamed:@"listing_flash_on"] forState:UIControlStateNormal];
            break;}
        case AVCaptureTorchModeAuto:{
            [sender setImage:[FZMyLibiaryBundle fz_imageNamed:@"listing_flash_auto"] forState:UIControlStateNormal];
            break;}
        default:{
            break;}
    }
}
/** 聚焦点 */
-(void)control:(FZRecordControlView *)control focusGestureAction:(UITapGestureRecognizer *)sender{
    CGPoint point = [sender locationInView:sender.view];
    //将UI坐标转化为摄像头坐标
    //CGPoint cameraPoint = [self.recordEngine.previewlayer captureDevicePointOfInterestForPoint:point];
    CGPoint cameraPoint = CGPointMake(point.x/sender.view.frame.size.width, point.y/sender.view.frame.size.height);
    //配置聚焦
    [self.recordEngine configFocusMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
    
}
/** 录制 */
-(void)control:(FZRecordControlView *)control recordAction:(UIButton *)sender{
    if (sender.selected) {
        [self.recordEngine startRecord];
    }else{
        [self.recordEngine pauseRecord];
    }
}

#pragma mark -- FZRecordEngineDelegate ---
/** 录制进度 */
-(void)recorder:(FZRecordEngine *)recorder recordProgress:(CGFloat)progress{
    
    NSInteger currentTime = progress * recorder.maxRecordTime;
    self.controlView.naviView.timeView.hidden = NO;
    self.controlView.naviView.timeView.timeLabel.text = [NSString stringWithFormat:@"%02li:%02li",lround(floor(currentTime/60.f)),lround(floor(currentTime/1.f))%60];
    
    [self.controlView.toolView.recordProgressView updateProgressWithValue:progress];
    
}
/** 录制完成 */
-(void)recorder:(FZRecordEngine *)recorder didCompleteWithSuccess:(BOOL)success error:(NSError *)error{
    self.controlView.naviView.timeView.hidden = YES;
    self.controlView.naviView.timeView.timeLabel.text = nil;
    [self.controlView.toolView reset];
    
    if (success) {
        NSLog(@"保存成功");
    }else{
        NSLog(@"保存失败");
    }
}



#pragma mark -- Lazy Func ----

-(FZRecordEngine *)recordEngine{
    if (_recordEngine == nil) { 
        _recordEngine = [[FZRecordEngine alloc]init];
        //_recordEngine.previewlayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        //_recordEngine.previewlayer.bounds = self.layer.bounds;
        [self.layer insertSublayer:_recordEngine.previewlayer atIndex:0];
        _recordEngine.delegate = self;
    }
    return _recordEngine;
}

-(FZRecordControlView *)controlView{
    if (_controlView == nil) {
        _controlView = [[FZRecordControlView alloc]init];
        [self addSubview:_controlView];
        _controlView.delegate = self;
        _controlView.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:_controlView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_controlView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
        NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:_controlView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_controlView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
        [self addConstraints:@[top,left,bottom,right]];
    }
    return _controlView;
}



@end
