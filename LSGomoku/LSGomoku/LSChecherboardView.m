//
//  LSChecherboardView.m
//  LSGomoku
//
//  Created by xiaoT on 16/9/14.
//  Copyright © 2016年 赖三聘. All rights reserved.
//

#import "LSChecherboardView.h"
#import "UIView+Frame.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_WIDTH_RATIO (SCREEN_WIDTH / 320) //屏宽比
static const NSInteger kGridCount = 15; //格子数
static const CGFloat kChessmanSizeRitio = 0.8;//棋子大小占比
static const CGFloat kBoardSpace = 20;

typedef enum : NSUInteger {
    GmkHorizontal,
    GmkVertical,
    GmkObliqueDown, //斜向下
    GmkObliqueUp //斜向上

}GmkDirection;

@interface LSChecherboardView()
@property (nonatomic, assign) CGFloat gridWidth;
@property (nonatomic, assign) CGFloat isBlack;
@property (nonatomic, strong) NSMutableArray *sameChessArray;//一条线上相同颜色的棋子
@property (nonatomic,strong) NSMutableDictionary * chessmanDict; //存放棋子字典的字典
@property (nonatomic, copy) NSString *lastKey;
@property (nonatomic, assign) BOOL isHighLevel;
@property (nonatomic, assign) NSInteger gridCount;
@property (nonatomic, assign) BOOL isOver;

@end

@implementation LSChecherboardView


-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setFrame:frame];
    }
    return self;
}

-(void)setFrame:(CGRect)frame
{
    CGSize size = frame.size;
    [super setFrame:CGRectMake(frame.origin.x, frame.origin.y,MIN(size.width, size.height) ,MIN(size.width, size.height))];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setUp];
    });
}

-(void)setUp
{
    self.backgroundColor =  [UIColor colorWithRed:200/255.0 green:160/255.0 blue:130/255.0 alpha:1];
    [self drawBackground:self.size];
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapBoard:)]];

}

#pragma 绘制棋盘
-(void)drawBackground:(CGSize)size
{
    self.gridWidth = (self.width - 2 * kBoardSpace) / self.gridCount;//计算格子宽度
    //开启上下文
    UIGraphicsBeginImageContext(size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(ctx, 0.8f);
    // 画16条线
    for (int i = 0; i <= self.gridCount; i++) {
        CGContextMoveToPoint(ctx, kBoardSpace + i * self.gridWidth, kBoardSpace);
        CGContextAddLineToPoint(ctx, kBoardSpace + i * self.gridWidth, kBoardSpace + self.gridCount * self.gridWidth);
    }
    
    for (int i = 0; i <= self.gridCount; i++) {
        CGContextMoveToPoint(ctx,kBoardSpace , kBoardSpace + i * self.gridWidth);
        CGContextAddLineToPoint(ctx,kBoardSpace + self.gridCount * self.gridWidth, kBoardSpace + i * self.gridWidth);
    }
    CGContextStrokePath(ctx);
    
    //获取生成的图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    //显示生成的图片到imageView
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [self addSubview:imageView];
    UIGraphicsEndImageContext();
}

-(void)tapBoard:(UIGestureRecognizer *)tap
{
    CGPoint point = [tap locationInView:tap.view];
    //计算下子的行号列号
    NSInteger col = (point.x - kBoardSpace + 0.5 * self.gridWidth) / self.gridWidth;
    NSInteger row = (point.y - kBoardSpace + 0.5 * self.gridWidth) / self.gridWidth;
    NSString *key = [NSString stringWithFormat:@"%ld-%ld",col,row];
    if (![self.chessmanDict.allKeys containsObject:key]) {
        UIView *chessman = [self chessman];
        chessman.center = CGPointMake(kBoardSpace + col * self.gridWidth, kBoardSpace + row * self.gridWidth);
        [self addSubview:chessman];
        [self.chessmanDict setValue:chessman forKey:key];
        self.lastKey = key;
        //检查游戏结果
        [self checkResult:col andRow:row andColor:self.isBlack];
        self.isBlack = !self.isBlack;
    }
}

#pragma mark - 私有方法
//检查游戏结果
-(void)checkResult:(NSInteger)col andRow:(NSInteger)row andColor:(BOOL)isBlack
{
    [self checkResult:col andRow:row andColor:isBlack andDirection:GmkHorizontal];
    [self checkResult:col andRow:row andColor:isBlack andDirection:GmkVertical];
    [self checkResult:col andRow:row andColor:isBlack andDirection:GmkObliqueDown];
    [self checkResult:col andRow:row andColor:isBlack andDirection:GmkObliqueUp];
}

//判断是否大于等于五个同色相连
- (BOOL)checkResult:(NSInteger)col andRow:(NSInteger)row andColor:(BOOL)isBlack andDirection:(GmkDirection)direction
{
    if (self.sameChessArray.count >= 5) {
        return YES;
    }
    UIColor *currentChessmanColor = [self.chessmanDict[[NSString stringWithFormat:@"%ld-%ld",col,row]] backgroundColor];
    [self.sameChessArray addObject:self.chessmanDict[self.lastKey]];
    switch (direction) {
            //水平方向检查结果
        case GmkHorizontal:{
            //向前遍历
            for (NSInteger i = col - 1; i > 0; i --) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",i,row];
                if (![self.chessmanDict.allKeys containsObject:key] || [self.chessmanDict[key] backgroundColor] != currentChessmanColor) break;
                [self.sameChessArray addObject:self.chessmanDict[key]];
            }
            //向后遍历
            for (NSInteger i = col + 1; i < kGridCount; i ++) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",i,row];
                if (![self.chessmanDict.allKeys containsObject:key] || [self.chessmanDict[key] backgroundColor] != currentChessmanColor) break;
                [self.sameChessArray addObject:self.chessmanDict[key]];
            }
            if (self.sameChessArray.count >= 5) {
                [self alertResult];
                return YES;
            }
            [self.sameChessArray removeAllObjects];
            
        }
            break;
        case GmkVertical:{
            //向前遍历
            for (NSInteger i = row - 1; i > 0; i --) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",col,i];
                if (![self.chessmanDict.allKeys containsObject:key] || [self.chessmanDict[key] backgroundColor] != currentChessmanColor) break;
                [self.sameChessArray addObject:self.chessmanDict[key]];
            }
            //向后遍历
            for (NSInteger i = row + 1; i < kGridCount; i ++) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",col,i];
                if (![self.chessmanDict.allKeys containsObject:key] || [self.chessmanDict[key] backgroundColor] != currentChessmanColor) break;
                [self.sameChessArray addObject:self.chessmanDict[key]];
            }
            if (self.sameChessArray.count >= 5) {
                [self alertResult];
                return YES;
            }
            [self.sameChessArray removeAllObjects];
            
        }
            break;
        case GmkObliqueDown:{
            
            //向前遍历
            NSInteger j = col - 1;
            for (NSInteger i = row - 1; i >= 0; i--,j--) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",j,i];
                if (![self.chessmanDict.allKeys containsObject:key] || [self.chessmanDict[key] backgroundColor] != currentChessmanColor || j < 0) break;
                [self.sameChessArray addObject:self.chessmanDict[key]];
            }
            //向后遍历
            j = col + 1;
            for (NSInteger i = row + 1 ; i < kGridCount; i++,j++) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",j,i];
                if (![self.chessmanDict.allKeys containsObject:key] || [self.chessmanDict[key] backgroundColor] != currentChessmanColor || j > kGridCount) break;
                [self.sameChessArray addObject:self.chessmanDict[key]];
            }
            if (self.sameChessArray.count >= 5) {
                [self alertResult];
                return YES;
            }
            [self.sameChessArray removeAllObjects];
            
            
        }
            break;
        case GmkObliqueUp:{
            //向前遍历
            NSInteger j = col + 1;
            for (NSInteger i = row - 1; i >= 0; i--,j++) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",j,i];
                if (![self.chessmanDict.allKeys containsObject:key] || [self.chessmanDict[key] backgroundColor] != currentChessmanColor || j > kGridCount) break;
                [self.sameChessArray addObject:self.chessmanDict[key]];
            }
            //向后遍历
            j = col - 1;
            for (NSInteger i = row + 1 ; i < kGridCount; i++,j--) {
                NSString * key = [NSString stringWithFormat:@"%ld-%ld",j,i];
                if (![self.chessmanDict.allKeys containsObject:key] || [self.chessmanDict[key] backgroundColor] != currentChessmanColor || j < 0) break;
                [self.sameChessArray addObject:self.chessmanDict[key]];
            }
            if (self.sameChessArray.count >= 5) {
                [self alertResult];
                return YES;
            }
            [self.sameChessArray removeAllObjects];
            
        }
            break;
    }

    return NO;
}

//游戏结束，提示效果
-(void)alertResult
{
    self.isOver = YES;
    NSLog(@"self.sameChessmanArray == %ld",self.sameChessArray.count);
    for (UIView *view in self.sameChessArray) {
        NSString *key = [self.chessmanDict allKeysForObject:view].firstObject;
        NSLog(@"%@",key);
    }
    
    CGFloat width = SCREEN_WIDTH * 0.4 * SCREEN_WIDTH_RATIO;
    UIView *tip = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, width * 0.6)];
    tip.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
    tip.alpha = 1;
    tip.layer.cornerRadius = 8.0f;
    [self addSubview:tip];
    tip.center = CGPointMake(self.width * 0.5, self.height * 0.5);
    UILabel *label = [[UILabel alloc]init];
    label.text = self.isBlack ? @"白方胜" : @"黑方胜";
    [label sizeToFit];
    label.center = CGPointMake(tip.width * 0.5, tip.height * 0.5);
    [tip addSubview:label];
    
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animation];
    anim.values = @[@(1),@(0),@(1)];
    anim.keyPath = @"opacity";
    anim.duration = 0.8f;
    anim.repeatCount = CGFLOAT_MAX;
    for (UIView *view in self.sameChessArray) {
        [view.layer addAnimation:anim forKey:@"alpha"];
    }
    
    self.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tip removeFromSuperview];
    });
}

#pragma mark - 功能方法
-(void)newGame
{
    self.isOver = NO;
    self.lastKey = nil;
    [self.sameChessArray removeAllObjects];
    self.userInteractionEnabled = YES;
    [self.chessmanDict removeAllObjects];
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            continue;
        }
        [view removeFromSuperview];
    }
    self.isBlack = NO;
}

//悔棋
-(void)backOneStep:(UIButton *)sender
{
    if (self.isOver) return;
    
    if (self.lastKey == nil) {
        sender.enabled = NO;
        CGFloat width = SCREEN_WIDTH * 0.4 * SCREEN_WIDTH_RATIO;
        
        UIView * tip = [[UIView alloc]initWithFrame:CGRectMake(0, 0, width, 0.6 * width)];
        tip.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
        tip.layer.cornerRadius = 8.0f;
        [self addSubview:tip];
        tip.center = CGPointMake(self.width * 0.5, self.height * 0.5);
        UILabel * label = [[UILabel alloc]init];
        label.text = self.chessmanDict.count > 0 ? @"只能悔一步棋" : @"清先落子!";
        label.font = [UIFont systemFontOfSize:15];
        [label sizeToFit];
        label.center = CGPointMake(tip.width * 0.5, tip.height * 0.5);
        [tip addSubview:label];
        
        self.userInteractionEnabled = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.userInteractionEnabled = YES;
            sender.enabled = YES;
            [tip removeFromSuperview];
        });
        return;
    }
    [self.chessmanDict removeObjectForKey:self.lastKey];
    [self.subviews.lastObject removeFromSuperview];
    self.isBlack = !self.isBlack;
    self.lastKey = nil;
}

//改变棋盘级别
-(void)changeBoardLevel
{
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    [self newGame];
    self.isHighLevel = !self.isHighLevel;
    [self drawBackground:self.bounds.size];
}

#pragma getter/setter 方法

-(UIView *)chessman
{
    UIView *chessmanView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.gridWidth * kChessmanSizeRitio, self.gridWidth * kChessmanSizeRitio)];
    chessmanView.layer.cornerRadius = chessmanView.width * 0.5;
    chessmanView.backgroundColor = !self.isBlack ? [UIColor blackColor] : [UIColor whiteColor];
    return chessmanView;
    
}

-(NSMutableDictionary *)chessmanDict
{
    if (!_chessmanDict) {
        _chessmanDict = [NSMutableDictionary dictionary];
    }
    return _chessmanDict;
}

-(NSMutableArray *)sameChessArray
{
    if (!_sameChessArray) {
        _sameChessArray = [NSMutableArray array];
    }
    return _sameChessArray;
}

//根据棋盘等级绘制棋盘
- (NSInteger)gridCount
{
    return self.isHighLevel ? kGridCount : (kGridCount - 4);
}

@end
