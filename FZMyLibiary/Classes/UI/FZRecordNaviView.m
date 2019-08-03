//
//  FZRecordNaviView.m
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/17.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

#import "FZRecordNaviView.h"
#import "FZMyLibiaryBundle.h"

@interface FZRecordNaviView ()

@end

@implementation FZRecordNaviView

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        [self setupViews];
        
    }
    return self;
}

-(void)setupViews{
    [self cancelButton];
    [self cameraButton];
    [self flashButton];
    [self timeView];
}

#pragma mark -- Lazy Func ----



-(UIButton *)cancelButton{
    if (_cancelButton == nil) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self addSubview:_cancelButton];
        _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_cancelButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10];
        NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:_cancelButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:_cancelButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:44];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_cancelButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:44];
        [self addConstraints:@[left,bottom,width,height]];
        [_cancelButton setImage:[FZMyLibiaryBundle fz_imageNamed:@"cancel"] forState:UIControlStateNormal];
        //[_cancelButton addTarget:self action:@selector(dismissVC) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}
-(UIButton *)cameraButton{
    if (_cameraButton == nil) {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [self addSubview:_cameraButton];
        _cameraButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_cameraButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.flashButton attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-10];
        NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:_cameraButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:_cameraButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:44];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_cameraButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:44];
        [self addConstraints:@[right,bottom,width,height]];
        
        [_cameraButton setImage:[FZMyLibiaryBundle fz_imageNamed:@"listing_camera_lens"] forState:UIControlStateNormal];
        //[_cameraButton addTarget:self action:@selector(turnCameraAction) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _cameraButton;
}
-(UIButton *)flashButton{
    if (_flashButton == nil) {
        
        _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [self addSubview:_flashButton];
        _flashButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_flashButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10];
        NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:_flashButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:_flashButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:44];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_flashButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:44];
        [self addConstraints:@[right,bottom,width,height]];
        
        
        [_flashButton setImage:[FZMyLibiaryBundle fz_imageNamed:@"listing_flash_off"] forState:UIControlStateNormal];
        
    }
    return _flashButton;
}

-(FZRecordTimeView *)timeView{
    if (_timeView == nil) {
        _timeView = [[FZRecordTimeView alloc]init];
        _timeView.hidden = YES;
        [self addSubview:_timeView];
        _timeView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:_timeView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
        NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:_timeView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:_timeView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:100];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_timeView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:44];
        [self addConstraints:@[centerX,bottom,width,height]];
        
    }
    return _timeView;
}


 

@end
