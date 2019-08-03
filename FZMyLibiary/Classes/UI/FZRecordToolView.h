//
//  FZRecordToolView.h
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/17.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FZRecordProgressView.h"

NS_ASSUME_NONNULL_BEGIN

@class FZRecordToolView;
@protocol FZRecordToolViewDelegate <NSObject>

-(void)tool:(FZRecordToolView *)tool recordAction:(UIButton *)sender;

@end

@interface FZRecordToolView : UIView

@property (nonatomic,strong) FZRecordProgressView *recordProgressView;

@property (nonatomic,weak) id<FZRecordToolViewDelegate> delegate;

-(void)reset;

@end

NS_ASSUME_NONNULL_END
