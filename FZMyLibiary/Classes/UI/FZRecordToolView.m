//
//  FZRecordToolView.m
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/17.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

#import "FZRecordToolView.h"
#import "FZMyLibiaryBundle.h"


@interface FZRecordToolView ()

@property (nonatomic,strong) UIButton *pauseButton;

@end

@implementation FZRecordToolView

#pragma mark -- Life Cycle Func ----

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupViews];
    }
    return self;
}


-(void)setupViews{
    [self recordProgressView];
    //[self pauseButton];
}


#pragma mark -- Action Func ----

-(void)reset{
    self.recordProgressView.recordBtn.selected = NO;
    [self animateWithButton:self.recordProgressView.recordBtn];
    [self.recordProgressView resetProgress];
}


-(void)startRecord:(UIButton *)sender{
    sender.selected = !sender.selected;
    [self animateWithButton:sender];
    if ([self.delegate respondsToSelector:@selector(tool:recordAction:)]) {
        [self.delegate tool:self recordAction:sender];
    }
}


-(void)animateWithButton:(UIButton *)sender{
    CGPoint center = sender.center;
    __block CGRect rect = sender.frame;
    [UIView animateWithDuration:0.2 animations:^{
        if (sender.selected) {
            rect.size = CGSizeMake(28, 28);
            sender.layer.cornerRadius = 4;
        }else{
            rect.size = CGSizeMake(52, 52);
            sender.layer.cornerRadius = 52/2.0;
        }
        sender.frame = rect;
        sender.center = center;
    }];
}

#pragma mark -- Lazy Func ----

-(FZRecordProgressView *)recordProgressView{
    if (_recordProgressView == nil) {
        _recordProgressView = [[FZRecordProgressView alloc]init];
        [self addSubview:_recordProgressView];
        _recordProgressView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:_recordProgressView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
        NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:_recordProgressView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:_recordProgressView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:62];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_recordProgressView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:62];
        [self addConstraints:@[centerX,centerY,width,height]];
        
        
        [_recordProgressView.recordBtn addTarget:self action:@selector(startRecord:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _recordProgressView;
}


-(UIButton *)pauseButton{
    if (_pauseButton == nil) {
        _pauseButton = [UIButton new];
        [_pauseButton setImage:[FZMyLibiaryBundle fz_imageNamed:@"video_record_pause"] forState:UIControlStateNormal];
        [self addSubview:_pauseButton];
        _pauseButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:_pauseButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.5 constant:0];
        NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:_pauseButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:_pauseButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:62];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_pauseButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:62];
        [self addConstraints:@[centerX,centerY,width,height]];
        
    }
    return _pauseButton;
}


@end
