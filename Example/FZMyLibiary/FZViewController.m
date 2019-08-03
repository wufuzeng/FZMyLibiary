//
//  FZViewController.m
//  FZMyLibiary
//
//  Created by wufuzeng on 11/28/2018.
//  Copyright (c) 2018 wufuzeng. All rights reserved.
//

#import "FZViewController.h"

#import "FZMyLibiary.h"

@interface FZViewController ()
<
FZRecordViewDelegate
>
@property (nonatomic,strong) FZRecordView *videoRecordView;


@end

@implementation FZViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupViews];
    
}

-(void)setupViews{
    
    
    [self videoRecordView];
}

#pragma mark -- FZRecordViewDelegate ----
/** 取消 */
-(void)record:(FZRecordView *)record cancelAction:(UIButton *)sender{
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -- Lazy Func ----


-(FZRecordView *)videoRecordView{
    if (_videoRecordView == nil) {
        _videoRecordView = [[FZRecordView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        _videoRecordView.delegate = self;
        [self.view addSubview:_videoRecordView];
    }
    return _videoRecordView;
}





@end
