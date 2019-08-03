//
//  FZRecordTimeView.m
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/17.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

#import "FZRecordTimeView.h"
#import "FZMyLibiaryBundle.h"

@interface FZRecordTimeView ()
@property (nonatomic,strong) UIButton *pauseButton;
@property (nonatomic,strong) UIView *pointView;

@end

@implementation FZRecordTimeView

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        [self setupViews];
    }
    return self;
}

-(void)setupViews{
    
    [self pointView];
    [self timeLabel];
    //[self pauseButton];
}

-(UIButton *)pauseButton{
    if (_pauseButton == nil) {
        _pauseButton = [UIButton new];
        [_pauseButton setImage:[FZMyLibiaryBundle fz_imageNamed:@"video_record_pause"] forState:UIControlStateNormal];
        [self addSubview:_pauseButton];
        _pauseButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_pauseButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10];
        NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:_pauseButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:_pauseButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:15];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_pauseButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:15];
        [self addConstraints:@[left,centerY,width,height]];
        
    }
    return _pauseButton;
}

-(UIView*)pointView{
    if (_pointView == nil ) {
        _pointView = [[UIView alloc]init];

        [self addSubview:_pointView];
        _pointView.translatesAutoresizingMaskIntoConstraints = NO;
        
        
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_pointView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10];
        NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:_pointView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:_pointView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:6];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_pointView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:6];
        [self addConstraints:@[left,centerY,width,height]];
        
        _pointView.layer.cornerRadius = 3;
        _pointView.layer.masksToBounds = YES;
        _pointView.backgroundColor = [UIColor redColor];
        
    }
    return _pointView;
}


-(UILabel *)timeLabel{
    if (_timeLabel == nil) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:13];
        _timeLabel.textColor = [UIColor whiteColor];
        
        [self addSubview:_timeLabel];
        
        _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_timeLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.pointView attribute:NSLayoutAttributeRight multiplier:1.0 constant:10];
        NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:_timeLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
        NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_timeLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_timeLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:44];
        [self addConstraints:@[left,centerY,right,height]];
        
    }
    return _timeLabel;
}

@end
