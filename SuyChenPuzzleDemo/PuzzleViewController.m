//
//  PuzzleViewController.m
//  SuyChenPuzzleDemo
//
//  Created by CSY on 2019/2/20.
//  Copyright © 2019 suychen. All rights reserved.
//


#import "PuzzleViewController.h"

#define verificationTolerance  20.0
#define SC_WIDTH    [[UIScreen mainScreen] bounds].size.width
#define SC_HEIGHT   [[UIScreen mainScreen] bounds].size.height

typedef NS_ENUM(NSUInteger, SCPieceType) {
    SCPieceTypeInside = -1, // 凹
    SCPieceTypeEmpty = 0, // 平
    SCPieceTypeOutside  = 1 //凸
};

typedef NS_ENUM(NSUInteger, SCPieceSideType) {
    SCPieceSideTypeTop,// 上
    SCPieceSideTypeBottom,// 下
    SCPieceSideTypeRight,// 右
    SCPieceSideTypeLeft,// 左
};

@interface PuzzleViewController ()
//方块凸凹数组
@property (nonatomic, strong) NSMutableArray *SCPieceTypeArray;
//洞高
@property (nonatomic, assign) CGFloat deepnessV;
//洞宽
@property (nonatomic, assign) CGFloat deepnessH;
//小方块宽度
@property (nonatomic, assign) CGFloat cubeWidthValue;
//小方块高度
@property (nonatomic, assign) CGFloat cubeHeightValue;
//每个方块的位置数组
@property (nonatomic, strong) NSMutableArray *pieceCoordinateRectArray;
//方向数组
@property (nonatomic, strong) NSMutableArray *pieceRotationArray;
//每个方块路径数组
@property (nonatomic, strong) NSMutableArray *pieceBezierPathsMutArray;
//每个方块最初的位置X
@property (nonatomic, assign) CGFloat firstX;
//每个方块最初的位置Y
@property (nonatomic, assign) CGFloat firstY;
//拼图背景
@property (nonatomic, strong) UIView* puzzleBoard;
//全部拼图
@property (nonatomic, strong) NSMutableArray* allPiecesArray;
@property (nonatomic, assign) CGFloat baseNum;

@property (weak, nonatomic) IBOutlet UIButton *cancel_btn;

@end

@implementation PuzzleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initData];
    
    [self initUI];
    
    [self setUpPeaceCoordinatesTypesAndRotationValuesArrays];
    
    [self setUpPieceBezierPaths];
    
    [self setUpPuzzlePeaceImages];
    
    [UIView animateWithDuration:3 animations:^{
        
        [self shufflePieces];
    } completion:nil];
    
    [self.view bringSubviewToFront:self.cancel_btn];
    
}
- (void)initUI
{
    
    self.puzzleBoard = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.originalCatImage.size.width, self.originalCatImage.size.height)];
    //    self.puzzleBoard.backgroundColor = [UIColor redColor];
    UIImageView *bgImage = [[UIImageView alloc] initWithImage:self.originalCatImage];
    [self.puzzleBoard addSubview:bgImage];
    [self.view addSubview:self.puzzleBoard];
    self.puzzleBoard.center = CGPointMake(SC_WIDTH / 2, SC_HEIGHT / 2);
    bgImage.alpha = 0.3;
    
}

/** 设置初始化数据 */
- (void)initData
{
    self.SCPieceTypeArray = [NSMutableArray array];
    self.pieceCoordinateRectArray = [NSMutableArray array];
    self.pieceRotationArray = [NSMutableArray array];
    self.pieceBezierPathsMutArray = [NSMutableArray array];
    self.allPiecesArray = [NSMutableArray array];
//    self.pieceHCount = 5;
//    self.pieceVCount = 5;
//    self.originalCatImage = [UIImage imageNamed:@"puzzle"];
//    CGFloat scale = self.originalCatImage.size.height / self.originalCatImage.size.width;
    self.originalCatImage =  [self image:self.originalCatImage ByScalingToSize:CGSizeMake(SC_WIDTH, SC_WIDTH/self.pieceHCount*self.pieceVCount)];
    //这里必须保证方块是正方形
    self.cubeHeightValue = self.originalCatImage.size.height / self.pieceVCount;
    self.cubeWidthValue = self.originalCatImage.size.width / self.pieceHCount;
    self.baseNum = 8 * self.originalCatImage.size.width / self.pieceHCount / (192 - 32);
    self.deepnessH = - (4 * self.baseNum);
    self.deepnessV = - (4 * self.baseNum);
}
/** 设置Piece切片的类型，坐标，以及方向 */
- (void)setUpPeaceCoordinatesTypesAndRotationValuesArrays
{
    NSUInteger mCounter = 0; // 调用计数器
    
    SCPieceType mSideL = SCPieceTypeEmpty;
    SCPieceType mSideT = SCPieceTypeEmpty;
    SCPieceType mSideR = SCPieceTypeEmpty;
    SCPieceType mSideB = SCPieceTypeEmpty;
    
    CGFloat mCubeWidth = 0;
    CGFloat mCubeHeight = 0;
    
    // 构建2维 i为垂直，j为水平
    for(int i = 0; i < self.pieceVCount; i++) {
        for(int j = 0; j < self.pieceHCount; j++) {
            // 1.设置类型
            
            // 1.1 中间 保证一凸一凹
            if(j != 0){
                mSideL = ([[[self.SCPieceTypeArray objectAtIndex:mCounter-1] objectForKey:@(SCPieceSideTypeRight)] intValue] == SCPieceTypeOutside)?SCPieceTypeInside:SCPieceTypeOutside;
            }
            if(i != 0) {
                mSideT = ([[[self.SCPieceTypeArray objectAtIndex:mCounter-self.pieceHCount] objectForKey:@(SCPieceSideTypeBottom)] intValue] == SCPieceTypeOutside)?SCPieceTypeInside:SCPieceTypeOutside;
            }
            mSideR = ((arc4random() % 2) == 1)?SCPieceTypeOutside:SCPieceTypeInside;
            mSideB = ((arc4random() % 2) == 1)?SCPieceTypeOutside:SCPieceTypeInside;
            
            // 1.2 边
            if(j == 0) {
                mSideL = SCPieceTypeEmpty;
            }
            if(i == 0) {
                mSideT = SCPieceTypeEmpty;
            }
            if(j == self.pieceHCount-1) {
                mSideR = SCPieceTypeEmpty;
            }
            if(i == self.pieceVCount - 1) {
                mSideB = SCPieceTypeEmpty;
            }
            
            // 2.设置高度以及宽度
            // 2.1 重置数据
            mCubeWidth = self.cubeWidthValue;
            mCubeHeight = self.cubeHeightValue;
            // 2.2 根据凹凸 进行数据修正
            if(mSideL == SCPieceTypeOutside) {
                mCubeWidth -= self.deepnessV;
            }else if (mSideL == SCPieceTypeInside){
                mCubeWidth -= self.deepnessV / 2;
            }
            if(mSideR == SCPieceTypeOutside) {
                mCubeWidth -= self.deepnessV;
            }else if (mSideR == SCPieceTypeInside){
                mCubeWidth -= self.deepnessV / 2;
            }
            if(mSideB == SCPieceTypeOutside) {
                mCubeHeight -= self.deepnessH;
            }else if (mSideB == SCPieceTypeInside){
                mCubeHeight -= self.deepnessH / 2;
            }
            if(mSideT == SCPieceTypeOutside) {
                mCubeHeight -= self.deepnessH;
            }else if (mSideT == SCPieceTypeInside){
                mCubeHeight -= self.deepnessH / 2;
            }
            
            
            // 3. 组装类型数组
            NSMutableDictionary *mOnePieceDic = [@{} mutableCopy];
            
            [mOnePieceDic setObject:[NSNumber numberWithInteger:mSideT] forKey:@(SCPieceSideTypeTop)];
            [mOnePieceDic setObject:[NSNumber numberWithInteger:mSideR] forKey:@(SCPieceSideTypeRight)];
            [mOnePieceDic setObject:[NSNumber numberWithInteger:mSideB] forKey:@(SCPieceSideTypeBottom)];
            [mOnePieceDic setObject:[NSNumber numberWithInteger:mSideL] forKey:@(SCPieceSideTypeLeft)];
            
            [self.SCPieceTypeArray addObject:mOnePieceDic];
            
            CGFloat startX = (SC_WIDTH - self.originalCatImage.size.width) / 2;
            
            CGFloat startY = (SC_HEIGHT - self.originalCatImage.size.height) / 2;
            
            // 4. 组装裁剪和图像用的 frame
            [self.pieceCoordinateRectArray addObject:[NSArray arrayWithObjects:
                                                      [NSValue valueWithCGRect:CGRectMake(j*self.cubeWidthValue,  i*self.cubeHeightValue,mCubeWidth,mCubeHeight)],
                                                      [NSValue valueWithCGRect:CGRectMake(startX +j*self.cubeWidthValue-(mSideL == SCPieceTypeOutside?-self.deepnessV:0) - (mSideL == SCPieceTypeInside?- self.deepnessV/ 2:0),startY + i*self.cubeHeightValue-(mSideT == SCPieceTypeOutside?-self.deepnessH:0) - (mSideT == SCPieceTypeInside?-self.deepnessH/2:0), mCubeWidth, mCubeHeight)], nil]];
            
            [self.pieceRotationArray addObject:[NSNumber numberWithFloat:0]];
            
            
            mCounter++;
            
        }
    }
    
}
- (void)setUpPieceBezierPaths
{
    
    for (NSInteger i = 0; i < self.SCPieceTypeArray.count; i++)
    {
        CGFloat mYSideStartPos = 0;
        
        CGFloat mXSideStartPos = 0;
        
        if ([[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeLeft)] integerValue] == SCPieceTypeOutside) {
            
            mXSideStartPos = 4 * self.baseNum;
        }else if ([[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeLeft)] integerValue] == SCPieceTypeInside) {
            mXSideStartPos = 2 * self.baseNum;
        }
        
        if ([[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeTop)] integerValue] == SCPieceTypeOutside) {
            
            mYSideStartPos = 4 * self.baseNum;
        }else if ([[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeTop)] integerValue] == SCPieceTypeInside) {
            mYSideStartPos = 2 * self.baseNum;
        }
        
        //初始化凹凸曲线
        UIBezierPath* mPieceBezier = [UIBezierPath bezierPath];
        //起点
        [mPieceBezier moveToPoint: CGPointMake(mXSideStartPos, mYSideStartPos)];
        
        //Top
        if ([[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeTop)] integerValue] != SCPieceTypeEmpty) {
            
            NSInteger direction = [[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeTop)] integerValue];
            
            CGFloat mCustomDeepness = direction * self.baseNum * 4;
            //上
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos + self.baseNum * 7,mYSideStartPos) controlPoint1:CGPointMake(mXSideStartPos, mYSideStartPos) controlPoint2:CGPointMake(mXSideStartPos + self.baseNum * 9, mYSideStartPos + mCustomDeepness - direction * self.baseNum)];
            
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos + self.baseNum * 10, mYSideStartPos - mCustomDeepness) controlPoint1:CGPointMake(mXSideStartPos + self.baseNum * 5, mYSideStartPos - mCustomDeepness + direction * self.baseNum) controlPoint2:CGPointMake(mXSideStartPos + self.baseNum * 7, mYSideStartPos - mCustomDeepness)];
            
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos + self.baseNum * 13, mYSideStartPos) controlPoint1:CGPointMake(mXSideStartPos + self.baseNum * 13, mYSideStartPos - mCustomDeepness) controlPoint2:CGPointMake(mXSideStartPos + self.baseNum * 15, mYSideStartPos - mCustomDeepness + direction * self.baseNum)];
            
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos + 20 * self.baseNum,  mYSideStartPos) controlPoint1:CGPointMake(mXSideStartPos + 11 * self.baseNum, mYSideStartPos + mCustomDeepness - direction * self.baseNum) controlPoint2:CGPointMake(mXSideStartPos + 20 * self.baseNum, mYSideStartPos)];
        }else{
            
            [mPieceBezier addLineToPoint:CGPointMake(mXSideStartPos + 20 * self.baseNum,  mYSideStartPos)];
        }
        //Right
        if ([[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeRight)] integerValue] != SCPieceTypeEmpty) {
            
            NSInteger direction = [[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeRight)] integerValue];
            
            CGFloat mCustomDeepness = direction * self.baseNum * 4;
            
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos + 20 * self.baseNum,mYSideStartPos + self.baseNum * 7) controlPoint1:CGPointMake(mXSideStartPos + 20 * self.baseNum, mYSideStartPos) controlPoint2:CGPointMake(mXSideStartPos + 20 * self.baseNum - 3 * direction * self.baseNum, mYSideStartPos + self.baseNum * 8)];
            
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos + 20 * self.baseNum + mCustomDeepness, mYSideStartPos + self.baseNum * 10) controlPoint1:CGPointMake(mXSideStartPos + self.baseNum * 20 + mCustomDeepness - direction * self.baseNum, mYSideStartPos + 5 * self.baseNum) controlPoint2:CGPointMake(mXSideStartPos + 20 * self.baseNum + mCustomDeepness, mYSideStartPos + self.baseNum * 7)];
            
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos + 20 * self.baseNum, mYSideStartPos + self.baseNum * 13) controlPoint1:CGPointMake(mXSideStartPos + 20 * self.baseNum + mCustomDeepness, mYSideStartPos + self.baseNum * 13) controlPoint2:CGPointMake(mXSideStartPos + self.baseNum * 20 + mCustomDeepness - direction * self.baseNum, mYSideStartPos + self.baseNum * 15)];
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos + 20 * self.baseNum,  mYSideStartPos + 20 * self.baseNum) controlPoint1:CGPointMake(mXSideStartPos + 20 * self.baseNum - 3 * direction * self.baseNum, mYSideStartPos + 11 * self.baseNum) controlPoint2:CGPointMake(mXSideStartPos + 20 * self.baseNum, mYSideStartPos + 20 * self.baseNum)];
        }else{
            [mPieceBezier addLineToPoint:CGPointMake(mXSideStartPos + 20 * self.baseNum,  mYSideStartPos + 20 * self.baseNum)];
            
        }
        //下
        if ([[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeBottom)] integerValue] != SCPieceTypeEmpty) {
            
            NSInteger direction = [[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeBottom)] integerValue];
            
            CGFloat mCustomDeepness = direction * self.baseNum * 4;
            
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos + self.baseNum * 13, mYSideStartPos + 20 * self.baseNum) controlPoint1:CGPointMake(mXSideStartPos + 20 * self.baseNum,  mYSideStartPos + 20 * self.baseNum) controlPoint2:CGPointMake(mXSideStartPos + 11 * self.baseNum, mYSideStartPos  + 20 * self.baseNum - mCustomDeepness + direction * self.baseNum)];
            
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos + self.baseNum * 10, mYSideStartPos + 20 * self.baseNum + mCustomDeepness) controlPoint1:CGPointMake(mXSideStartPos + self.baseNum * 15, mYSideStartPos + 20 * self.baseNum + mCustomDeepness - direction * self.baseNum) controlPoint2:CGPointMake(mXSideStartPos + self.baseNum * 13, mYSideStartPos + 20 * self.baseNum + mCustomDeepness)];
            
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos + self.baseNum * 7, mYSideStartPos + 20 * self.baseNum) controlPoint1:CGPointMake(mXSideStartPos + self.baseNum * 7, mYSideStartPos + 20 * self.baseNum + mCustomDeepness) controlPoint2:CGPointMake(mXSideStartPos + self.baseNum * 5, mYSideStartPos + 20 * self.baseNum + mCustomDeepness - direction * self.baseNum)];
            
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos, mYSideStartPos + 20 * self.baseNum) controlPoint1:CGPointMake(mXSideStartPos + self.baseNum * 9, mYSideStartPos  + 20 * self.baseNum - mCustomDeepness + direction * self.baseNum) controlPoint2:CGPointMake(mXSideStartPos, mYSideStartPos + 20 * self.baseNum)];
        }else{
            [mPieceBezier addLineToPoint:CGPointMake(mXSideStartPos, mYSideStartPos + 20 * self.baseNum)];
            
        }
        //左
        if ([[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeLeft)] integerValue] != SCPieceTypeEmpty) {
            
            NSInteger direction = [[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeLeft)] integerValue];
            
            CGFloat mCustomDeepness = direction * self.baseNum * 4;
            
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos, mYSideStartPos + self.baseNum * 13) controlPoint1:CGPointMake(mXSideStartPos, mYSideStartPos + 20 * self.baseNum) controlPoint2:CGPointMake(mXSideStartPos + 3 * direction * self.baseNum, mYSideStartPos + 11 * self.baseNum)];
            
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos - mCustomDeepness, mYSideStartPos + self.baseNum * 10) controlPoint1:CGPointMake(mXSideStartPos - mCustomDeepness + direction * self.baseNum, mYSideStartPos + self.baseNum * 15) controlPoint2:CGPointMake(mXSideStartPos - mCustomDeepness, mYSideStartPos + self.baseNum * 13)];
            
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos, mYSideStartPos + self.baseNum * 7) controlPoint1:CGPointMake(mXSideStartPos - mCustomDeepness, mYSideStartPos + self.baseNum * 7) controlPoint2:CGPointMake(mXSideStartPos - mCustomDeepness + direction * self.baseNum, mYSideStartPos + 5 * self.baseNum)];
            
            [mPieceBezier addCurveToPoint:CGPointMake(mXSideStartPos, mYSideStartPos) controlPoint1:CGPointMake(mXSideStartPos + 3 * direction * self.baseNum, mYSideStartPos + self.baseNum * 8) controlPoint2:CGPointMake(mXSideStartPos, mYSideStartPos)];
        }else{
            [mPieceBezier addLineToPoint:CGPointMake(mXSideStartPos, mYSideStartPos)];
            
        }
        
        [self.pieceBezierPathsMutArray addObject:mPieceBezier];
        
    }
}
- (void)setUpPuzzlePeaceImages
{
    CGFloat mXAddableVal = 0;
    
    CGFloat mYAddableVal = 0;
    
    for (NSInteger i = 0; i < self.pieceBezierPathsMutArray.count; i++) {
        
        CGRect mCropFrame = [[[self.pieceCoordinateRectArray objectAtIndex:i] objectAtIndex:0] CGRectValue];
        
        CGRect mImageFrame = [[[self.pieceCoordinateRectArray objectAtIndex:i] objectAtIndex:1] CGRectValue];
        
        //拼图小方块
        UIImageView *mPeace = [UIImageView new];
        
        [mPeace setFrame:mImageFrame];
        
        [mPeace setTag:i+100];
        
        [mPeace setUserInteractionEnabled:YES];
        
        [mPeace setContentMode:UIViewContentModeTopLeft];
        
        //修正
        if ([[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeLeft)] integerValue] == SCPieceTypeOutside) {
            mXAddableVal = self.deepnessV;
        }else if ([[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeLeft)] integerValue] == SCPieceTypeInside){
            mXAddableVal = self.deepnessV / 2;
        }else{
            mXAddableVal = 0;
        }
        if ([[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeTop)] integerValue] == SCPieceTypeOutside) {
            mYAddableVal = self.deepnessH;
        }else if ([[[self.SCPieceTypeArray objectAtIndex:i] objectForKey:@(SCPieceSideTypeTop)] integerValue] == SCPieceTypeInside){
            mYAddableVal = self.deepnessH / 2;
        }else{
            mYAddableVal = 0;
        }
        
        mCropFrame.origin.x += mXAddableVal;
        
        mCropFrame.origin.y += mYAddableVal;
        
        //把图片修剪成包含路径的小方块
        [mPeace setImage:[UIImage imageWithCGImage:CGImageCreateWithImageInRect([self.originalCatImage CGImage], mCropFrame)]];
        //按路径切割方块
        [self setClippingPath:[self.pieceBezierPathsMutArray objectAtIndex:i] clipImage:mPeace];
        
        [self.view addSubview:mPeace];
        
        //        //改变方块的方向
        //        [mPeace setTransform:CGAffineTransformMakeRotation([[self.pieceRotationArray objectAtIndex:i] floatValue])];
        
        //绘制边线
        CAShapeLayer *mBorderPathLayer = [CAShapeLayer layer];
        [mBorderPathLayer setPath:[[self.pieceBezierPathsMutArray objectAtIndex:i] CGPath]];
        [mBorderPathLayer setFillColor:[UIColor clearColor].CGColor];
        [mBorderPathLayer setStrokeColor:[UIColor colorWithWhite:0 alpha:0.5].CGColor];
        [mBorderPathLayer setLineWidth:1];
        [mBorderPathLayer setFrame:CGRectZero];
        [[mPeace layer] addSublayer:mBorderPathLayer];
        
        //添加跟随拖拽的手势
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(move:)];
        [mPeace addGestureRecognizer:panRecognizer];
        
        [self.allPiecesArray addObject:mPeace];
    }
}

- (void)shufflePieces
{
    CGFloat RangeY = (SC_HEIGHT - self.originalCatImage.size.height) / 2;
    CGFloat RangeX = self.puzzleBoard.frame.size.width;
    
    for (NSInteger i = 0; i < self.allPiecesArray.count / 2; i++) {
        UIImageView *piece = self.allPiecesArray[i];
        CGPoint location = CGPointMake(arc4random_uniform(RangeX - self.cubeWidthValue) + self.cubeWidthValue / 2, arc4random_uniform(RangeY - self.cubeHeightValue) + self.cubeHeightValue / 2);
        piece.center = location;
    }
    for (NSInteger i = self.allPiecesArray.count / 2; i < self.allPiecesArray.count; i++) {
        UIImageView *piece = self.allPiecesArray[i];
        CGPoint location = CGPointMake(arc4random_uniform(RangeX - self.cubeWidthValue) + self.cubeWidthValue / 2, arc4random_uniform(RangeY - self.cubeHeightValue) + (SC_HEIGHT - (SC_HEIGHT - self.originalCatImage.size.height) / 2) + self.cubeHeightValue / 2);
        piece.center = location;
    }
    
}
#pragma mark == 手势
- (void)move:(UIPanGestureRecognizer *)sender {
    //手势跟随
    CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self.view];
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.firstX = sender.view.center.x;
        self.firstY = sender.view.center.y;
    }
    UIImageView *mImgView = (UIImageView *)sender.view;
    translatedPoint = CGPointMake(self.firstX + translatedPoint.x, self.firstY + translatedPoint.y);
    [mImgView setCenter:translatedPoint];
    
    // 验证相关
    if (sender.state == UIGestureRecognizerStateEnded) {
        //获取最初的位置
        CGRect oImageFrame = [[[self.pieceCoordinateRectArray objectAtIndex:mImgView.tag-100] objectAtIndex:1] CGRectValue];
        CGPoint oimageCenter = CGPointMake(oImageFrame.origin.x +oImageFrame.size.width/2, oImageFrame.origin.y + oImageFrame.size.height/2);
        if (fabs(oimageCenter.x - mImgView.center.x) <= verificationTolerance &&
            fabs(oimageCenter.y - mImgView.center.y) <= verificationTolerance) {
            NSLog(@"位置匹配，可以修正");
            [mImgView setCenter:oimageCenter];
            mImgView.userInteractionEnabled = NO;
        }else{
            NSLog(@"位置不匹配，%@--- %@",NSStringFromCGPoint(oimageCenter),NSStringFromCGPoint(translatedPoint));
        }
    }
}

#pragma mark == help
- (void)setClippingPath:(UIBezierPath *)clippingPath clipImage:(UIImageView *)imgView;
{
    if (![[imgView layer] mask])
    {
        [[imgView layer] setMask:[CAShapeLayer layer]];
    }
    
    [(CAShapeLayer*) [[imgView layer] mask] setPath:[clippingPath CGPath]];
}

- (UIImage *)image:(UIImage *)sourceImage ByScalingToSize:(CGSize)targetSize
{
    UIImage *newImage = nil;
    CGRect rect = CGRectMake(0.0, 0.0, targetSize.width, targetSize.height);
    //压缩图片过程
    UIGraphicsBeginImageContext(rect.size);
    [sourceImage drawInRect:rect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil)
        NSLog(@"could not scale image");
    return newImage ;
}
//压缩图片到指定大小
- (UIImage*)imageCompressWithSimple:(UIImage*)image scaledToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0,size.width,size.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (IBAction)dismissVC:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
