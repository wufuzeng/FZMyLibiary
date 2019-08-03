//
//  FZRecordProgressView.m
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/17.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

#import "FZRecordProgressView.h"

@interface FZRecordProgressView ()

@property (nonatomic, assign) CGFloat progress;

@property (nonatomic,strong ) CAShapeLayer *backLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;



@end


@implementation FZRecordProgressView

#pragma mark -- Lazy Func ---

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupViews];
    }
    return self;
}


#pragma mark -- Customs Func ----

-(void)setupViews {
    
    [self recordBtn];
}


-(void)updateProgressWithValue:(CGFloat)progress {
    self.progress = progress;
    //self.progressLayer.opacity = 0;
    [self setNeedsDisplay];
}

-(void)resetProgress{
    [self updateProgressWithValue:0];
}


-(void)drawRect:(CGRect)rect{
    
    CGPoint center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    CGFloat radius = self.frame.size.width/2;
    CGFloat startA = - M_PI_2;
    CGFloat endA   = -M_PI_2 + M_PI * 2 * self.progress;
    
    if (self.frame.size.width > 0 && self.frame.size.height > 0) {
        
        UIBezierPath *path0 = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:0 endAngle: M_PI * 2 clockwise:YES];
        self.backLayer.path =[path0 CGPath];
        
    }
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startA endAngle:endA clockwise:YES];
    self.progressLayer.path =[path CGPath];
    
}




#pragma mark -- Lazy Func ------

-(CAShapeLayer *)backLayer{
    if (_backLayer == nil) {
        _backLayer = [CAShapeLayer layer];
        _backLayer.frame = self.bounds;
        _backLayer.fillColor = [[UIColor clearColor] CGColor];
        _backLayer.strokeColor = [[UIColor whiteColor] CGColor];
        //_backLayer.opacity = 1; //背景颜色的透明度
        _backLayer.lineCap = kCALineCapRound;
        _backLayer.lineWidth = 5;
        [self.layer addSublayer:_backLayer];
    }
    return _backLayer;
}

-(CAShapeLayer *)progressLayer{
    if (_progressLayer == nil) {
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.frame = self.bounds;
        _progressLayer.fillColor = [[UIColor clearColor] CGColor];
        _progressLayer.strokeColor = [[UIColor colorWithRed:155/255.0 green:241/255.0 blue:97/255.0 alpha:1] CGColor];
        //_progressLayer.opacity = 1; //背景颜色的透明度
        _progressLayer.lineCap = kCALineCapButt;
        _progressLayer.lineWidth = 5;
        
        [self.layer addSublayer:_progressLayer];
    }
    return _progressLayer;
}

-(UIButton *)recordBtn{
    if (_recordBtn == nil) {
        _recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _recordBtn.backgroundColor = [UIColor redColor];
        _recordBtn.layer.cornerRadius = 52/2.0;
        _recordBtn.layer.masksToBounds = YES;
        [self addSubview:_recordBtn];
        _recordBtn.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:_recordBtn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
        NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:_recordBtn attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:_recordBtn attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:52];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_recordBtn attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:52];
        [self addConstraints:@[centerX,centerY,width,height]];
        
        
        [self resetProgress];
    }
    return _recordBtn;
}


@end
