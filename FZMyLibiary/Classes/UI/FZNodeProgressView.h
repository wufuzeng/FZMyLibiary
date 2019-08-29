//
//  FZNodeProgressView.h
//  FZMyLibiary
//
//  Created by 吴福增 on 2019/8/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FZNodeProgressView : UIView

//必须设置  最大进度
@property (nonatomic,assign) CGFloat maxProgress;
//当前进度
@property (nonatomic,assign) CGFloat progress;
//进度条颜色
@property (nonatomic,strong) UIColor *bgColor;
//节点颜色
@property (nonatomic,strong) UIColor *nodeColor;
//节点段选中颜色
@property (nonatomic,strong) UIColor *selectColor;
//是否被选中
@property (nonatomic,assign,readonly) BOOL isSelected;


///增加节点
- (UIView *)addNodeView;
///删除最后一个节点
- (void)removeLastNode;
///选中最后一个节点
- (void)selectLastNode;


@end

NS_ASSUME_NONNULL_END
