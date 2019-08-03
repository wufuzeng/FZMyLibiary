//
//  FZRecordControlView.m
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/17.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

#import "FZRecordControlView.h"

#import "FZMyLibiaryBundle.h"

@interface FZRecordControlView ()
<
FZRecordToolViewDelegate
> 

@property (strong,nonatomic) UIImageView *focusCursor;

@property (strong,nonatomic) UITapGestureRecognizer *focusGesture;

@end

@implementation FZRecordControlView

#pragma mark -- Life Cycle Func ----

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupViews];
    }
    return self;
}

-(void)setupViews{
    [self naviView];
    [self toolView];
    [self focusCursor];
    [self focusGesture];
}

#pragma mark -- FZRecordToolViewDelegate ----
-(void)tool:(FZRecordToolView *)tool recordAction:(UIButton *)sender{
    if ([self.delegate respondsToSelector:@selector(control: recordAction:)]) {
        [self.delegate control:self recordAction:sender];
    }
}



#pragma mark -- Action Func ----
-(void)cancelButtonAction:(UIButton *)sender{
    if ([self.delegate respondsToSelector:@selector(control:cancelAction:)]) {
        [self.delegate control:self cancelAction:sender];
    }
}
-(void)cameraButtonAction:(UIButton *)sender{
    if ([self.delegate respondsToSelector:@selector(control:turnCameraAction:)]) {
        [self.delegate control:self turnCameraAction:sender];
    }
}
-(void)flashButtonAction:(UIButton *)sender{
    if ([self.delegate respondsToSelector:@selector(control:switchTorchModelAction:)]) {
        [self.delegate control:self switchTorchModelAction:sender];
    }
}
-(void)focusGestureAction:(UITapGestureRecognizer *)sender{
    CGPoint point = [sender locationInView:sender.view];
    CGFloat minY = CGRectGetMaxY(self.naviView.frame) + self.focusCursor.frame.size.height/2.0;
    CGFloat maxY = CGRectGetMinY(self.toolView.frame) - self.focusCursor.frame.size.height/2.0;
    if (point.y < minY || point.y > maxY) {
        return;
    }
    self.focusCursor.center = point;
    self.focusCursor.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursor.alpha = 1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusCursor.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursor.alpha = 0;
    }];
    if ([self.delegate respondsToSelector:@selector(control:focusGestureAction:)]) {
        [self.delegate control:self focusGestureAction:sender];
    }
}



#pragma mark -- Lazy Func ----

-(FZRecordNaviView *)naviView{
    if (_naviView == nil) {
        _naviView = [[FZRecordNaviView alloc]init];
        _naviView.backgroundColor = [UIColor blackColor];
        
        [self addSubview:_naviView];
        _naviView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:_naviView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_naviView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
        NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_naviView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_naviView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:44];
        [self addConstraints:@[top,left,right,height]];
        
        [_naviView.cancelButton addTarget:self action:@selector(cancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_naviView.cameraButton addTarget:self action:@selector(cameraButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_naviView.flashButton addTarget:self action:@selector(flashButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _naviView;
}

-(FZRecordToolView *)toolView{
    if (_toolView == nil) {
        _toolView = [[FZRecordToolView alloc]init];
        _toolView.backgroundColor = [UIColor blackColor];
        _toolView.delegate = self;
        [self addSubview:_toolView];
        _toolView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_toolView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
        NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_toolView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
        NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:_toolView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_toolView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:100];
        [self addConstraints:@[left,right,bottom,height]];
        
    }
    return _toolView;
}

- (UIImageView *)focusCursor{
    if (!_focusCursor) {
        _focusCursor = [[UIImageView alloc]initWithFrame:CGRectMake(100, 100, 50, 50)];
        _focusCursor.image = [FZMyLibiaryBundle fz_imageNamed:@"focusImg"];
        _focusCursor.alpha = 0;
        [self addSubview:_focusCursor];
    }
    return _focusCursor;
}

-(UITapGestureRecognizer *)focusGesture{
    if (_focusGesture == nil) {
        _focusGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(focusGestureAction:)];
        [self addGestureRecognizer:_focusGesture];
    }
    return _focusGesture;
}

@end
