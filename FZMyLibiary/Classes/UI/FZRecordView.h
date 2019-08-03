//
//  FZRecordView.h
//  FZOCProject
//
//  Created by 吴福增 on 2019/1/17.
//  Copyright © 2019 wufuzeng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FZRecordView;

@protocol FZRecordViewDelegate <NSObject>

/** 取消录制 */
-(void)record:(FZRecordView *)record cancelAction:(UIButton *)sender;

@end



@interface FZRecordView : UIView

@property (nonatomic,weak) id<FZRecordViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
