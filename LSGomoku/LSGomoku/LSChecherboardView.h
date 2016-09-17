//
//  LSChecherboardView.h
//  LSGomoku
//
//  Created by xiaoT on 16/9/14.
//  Copyright © 2016年 赖三聘. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LSChecherboardView : UIView

-(void)backOneStep:(UIButton *)sender;//悔棋
-(void)newGame;
-(void)changeBoardLevel;//改变棋盘

@end
