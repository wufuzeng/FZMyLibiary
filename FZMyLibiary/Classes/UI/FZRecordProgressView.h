//
//  FZRecordProgressView.h
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/17.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FZRecordProgressView : UIView

@property (nonatomic, strong) UIButton *recordBtn;

//-(instancetype)initWithFrame:(CGRect)frame;
-(void)updateProgressWithValue:(CGFloat)progress;
-(void)resetProgress;

@end

NS_ASSUME_NONNULL_END
