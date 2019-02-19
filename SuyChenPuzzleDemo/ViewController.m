//
//  ViewController.m
//  SuyChenPuzzleDemo
//
//  Created by CSY on 2019/2/15.
//  Copyright © 2019 suychen. All rights reserved.
//

#import "ViewController.h"

#define verificationTolerance  20.0

typedef NS_ENUM(NSUInteger, SCPieceType) {
    SCPieceTypeInside = -1, // 凹
    SCPieceTypeEmpty = 0, // 平
    SCPieceTypeOutside  = 1 //凸
};

typedef NS_ENUM(NSUInteger, SCPieceSideType) {
    SCPieceSideTypeTop = 0,// 上
    SCPieceSideTypeRight,// 右
    SCPieceSideTypeBottom,// 下
    SCPieceSideTypeLeft// 左
};

@interface ViewController ()
//原始图片
@property (nonatomic, strong) UIImage *originalCatImage;
//垂直数量
@property (nonatomic, assign) NSInteger pieceVCount;
//水平数量
@property (nonatomic, assign) NSInteger pieceHCount;
//方块凸凹数组
@property (nonatomic, strong) NSMutableArray *SCPieceTypeArray;
//洞高
@property (nonatomic, assign) NSInteger deepnessV;
//洞宽
@property (nonatomic, assign) NSInteger deepnessH;
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
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.originalCatImage = [UIImage imageNamed:@"puzzletest"];
    
    CGFloat scale = self.originalCatImage.size.height / self.originalCatImage.size.width;

    self.originalCatImage =  [self image:self.originalCatImage ByScalingToSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.width*scale)];
    
    [self initUI];
    
    [self initData];

    [self setUpPeaceCoordinatesTypesAndRotationValuesArrays];

    [self setUpPeaceBezierPaths];

    [self setUpPuzzlePeaceImages];
    
//    [self shufflePieces];
    
}
- (void)initUI
{
    
    self.puzzleBoard = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.originalCatImage.size.width, self.originalCatImage.size.height)];
    UIImageView *bgImage = [[UIImageView alloc] initWithImage:self.originalCatImage];
    [self.puzzleBoard addSubview:bgImage];
    [self.view addSubview:self.puzzleBoard];
    self.puzzleBoard.center = self.view.center;
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

    self.pieceHCount = 4;
    self.pieceVCount = 4;
    self.cubeHeightValue = self.originalCatImage.size.height / self.pieceVCount;
    self.cubeWidthValue = self.originalCatImage.size.width / self.pieceHCount;
    self.deepnessH = - (self.cubeHeightValue / self.pieceVCount);
    self.deepnessV = -(self.cubeWidthValue / self.pieceHCount);
}
/** 设置Piece切片的类型，坐标，以及方向 */
- (void)setUpPeaceCoordinatesTypesAndRotationValuesArrays
{
    NSUInteger mCounter = 0; // 调用计数器
    
    SCPieceType mSideL = SCPieceTypeEmpty;
    SCPieceType mSideT = SCPieceTypeEmpty;
    SCPieceType mSideR = SCPieceTypeEmpty;
    SCPieceType mSideB = SCPieceTypeEmpty;
    
    NSUInteger mCubeWidth = 0;
    NSUInteger mCubeHeight = 0;
    
    // 构建2维 i为垂直，j为水平
    for(int i = 0; i < self.pieceVCount; i++) {
        for(int j = 0; j < self.pieceHCount; j++) {
            // 1.设置类型
            
            // 1.1 中间 保证一凸一凹
            if(j != 0) {
                mSideT = ([[[self.SCPieceTypeArray objectAtIndex:mCounter-1] objectAtIndex:SCPieceSideTypeBottom] intValue] == SCPieceTypeOutside)?SCPieceTypeInside:SCPieceTypeOutside;
            }
            if(i != 0){
                mSideL = ([[[self.SCPieceTypeArray objectAtIndex:mCounter-self.pieceHCount] objectAtIndex:SCPieceSideTypeRight] intValue] == SCPieceTypeOutside)?SCPieceTypeInside:SCPieceTypeOutside;
            }
            mSideR = ((arc4random() % 2) == 1)?SCPieceTypeOutside:SCPieceTypeInside;
            mSideB = ((arc4random() % 2) == 1)?SCPieceTypeOutside:SCPieceTypeInside;
            
            // 1.2 边
            if(i == 0) {
                mSideL = SCPieceTypeEmpty;
            }
            if(j == 0) {
                mSideT = SCPieceTypeEmpty;
            }
            if(i == self.pieceVCount-1) {
                mSideR = SCPieceTypeEmpty;
            }
            if(j == self.pieceHCount - 1) {
                mSideB = SCPieceTypeEmpty;
            }
            
            // 2.设置高度以及宽度
            // 2.1 重置数据
            mCubeWidth = self.cubeWidthValue;
            mCubeHeight = self.cubeHeightValue;
            // 2.2 根据凹凸 进行数据修正
            if(mSideT == SCPieceTypeOutside) {
                mCubeWidth -= self.deepnessV;
            }
            if(mSideB == SCPieceTypeOutside) {
                mCubeWidth -= self.deepnessV;
            }
            if(mSideR == SCPieceTypeOutside) {
                mCubeHeight -= self.deepnessH;
            }
            if(mSideL == SCPieceTypeOutside) {
                mCubeHeight -= self.deepnessH;
            }
            
            // 3. 组装类型数组
            [self.SCPieceTypeArray addObject:[NSArray arrayWithObjects:
                                            [NSString stringWithFormat:@"%ld", mSideT],
                                            [NSString stringWithFormat:@"%ld", mSideR],
                                            [NSString stringWithFormat:@"%ld", mSideB],
                                            [NSString stringWithFormat:@"%ld", mSideL],
                                            nil]];
            
            CGFloat startX = (self.view.frame.size.width - self.originalCatImage.size.width) / 2;
            
            CGFloat startY = (self.view.frame.size.height - self.originalCatImage.size.height) / 2;
            
            // 4. 组装裁剪和图像用的 frame
            [self.pieceCoordinateRectArray addObject:[NSArray arrayWithObjects:
                                                      [NSValue valueWithCGRect:CGRectMake(j * self.cubeWidthValue, i * self.cubeHeightValue, mCubeWidth, mCubeHeight)],
                                                      [NSValue valueWithCGRect:CGRectMake(startX + j * self.cubeWidthValue - (mSideT == SCPieceTypeOutside ? -self.deepnessV : 0), startY + i * self.cubeHeightValue - (mSideL == SCPieceTypeOutside ? -self.deepnessH : 0), mCubeWidth, mCubeHeight)], nil]];
            
            [self.pieceRotationArray addObject:[NSNumber numberWithFloat:0]];
            
            
            mCounter++;
            
        }
    }
    
}

//画贝塞尔曲线
- (void)setUpPeaceBezierPaths
{
    float mYSideStartPos = 0;
    
    float mXSideStartPos = 0;
    
    float mCustomDeepness = 0;
    
    float mCurveHalfVLength = self.cubeWidthValue / 10;
    
    float mCurveHalfHLength = self.cubeHeightValue / 10;
    
    float mCurveStartXPos = self.cubeWidthValue / 2 - mCurveHalfVLength;
    
    float mCurveStartYPos = self.cubeHeightValue / 2 - mCurveHalfHLength;
    
    float mTotalHeight = 0;
    
    float mTotalWidth = 0;
    
    
    for (NSInteger i = 0; i < self.SCPieceTypeArray.count; i++) {
        
        mXSideStartPos  = ([[[self.SCPieceTypeArray objectAtIndex:i] objectAtIndex:SCPieceSideTypeTop] integerValue] == SCPieceTypeOutside) ? -self.deepnessV : 0;
        mYSideStartPos = ([[[self.SCPieceTypeArray objectAtIndex:i] objectAtIndex:SCPieceSideTypeLeft] integerValue] == SCPieceTypeOutside) ? -self.deepnessH : 0;
        
        mTotalHeight = mYSideStartPos + mCurveStartYPos * 2 + mCurveHalfHLength * 2;
        
        mTotalWidth = mXSideStartPos + mCurveStartXPos * 2 + mCurveHalfVLength * 2;
        
        //初始化凹凸曲线
        UIBezierPath* mPieceBezier = [UIBezierPath bezierPath];
        //起点
        [mPieceBezier moveToPoint: CGPointMake(mXSideStartPos, mYSideStartPos)];
        
        //-----Left-----
        [mPieceBezier addLineToPoint: CGPointMake(mXSideStartPos, mYSideStartPos + mCurveStartYPos)];
        
        if([[[self.SCPieceTypeArray objectAtIndex:i] objectAtIndex:SCPieceSideTypeTop] integerValue] != SCPieceTypeEmpty)
        {
            mCustomDeepness = self.deepnessV * [[[self.SCPieceTypeArray objectAtIndex:i] objectAtIndex:SCPieceSideTypeTop] integerValue];
            
            [mPieceBezier addCurveToPoint: CGPointMake(mXSideStartPos + mCustomDeepness, mYSideStartPos + mCurveStartYPos+mCurveHalfHLength)
                            controlPoint1: CGPointMake(mXSideStartPos, mYSideStartPos + mCurveStartYPos)
                            controlPoint2: CGPointMake(mXSideStartPos + mCustomDeepness, mYSideStartPos + mCurveStartYPos + mCurveHalfHLength - mCurveStartYPos)];//25
            
            [mPieceBezier addCurveToPoint: CGPointMake(mXSideStartPos, mYSideStartPos + mCurveStartYPos + mCurveHalfHLength * 2)
                            controlPoint1: CGPointMake(mXSideStartPos + mCustomDeepness, mYSideStartPos + mCurveStartYPos + mCurveHalfHLength + mCurveStartYPos)
                            controlPoint2: CGPointMake(mXSideStartPos, mYSideStartPos+mCurveStartYPos + mCurveHalfHLength*2)]; //156
        }
        
        [mPieceBezier addLineToPoint: CGPointMake(mXSideStartPos, mTotalHeight)];
        
        //-----Top-----
        [mPieceBezier addLineToPoint: CGPointMake(mXSideStartPos+ mCurveStartXPos, mTotalHeight)];
        
        if([[[self.SCPieceTypeArray objectAtIndex:i] objectAtIndex:SCPieceSideTypeRight] integerValue] != SCPieceTypeEmpty)
        {
            mCustomDeepness = self.deepnessH * [[[self.SCPieceTypeArray objectAtIndex:i] objectAtIndex:SCPieceSideTypeRight] intValue];
            
            [mPieceBezier addCurveToPoint: CGPointMake(mXSideStartPos + mCurveStartXPos + mCurveHalfVLength, mTotalHeight - mCustomDeepness)
                            controlPoint1: CGPointMake(mXSideStartPos + mCurveStartXPos, mTotalHeight)
                            controlPoint2: CGPointMake(mXSideStartPos + mCurveHalfVLength, mTotalHeight - mCustomDeepness)];
            
            [mPieceBezier addCurveToPoint: CGPointMake(mXSideStartPos + mCurveStartXPos + mCurveHalfVLength+mCurveHalfVLength, mTotalHeight)
                            controlPoint1: CGPointMake(mTotalWidth - mCurveHalfVLength, mTotalHeight - mCustomDeepness)
                            controlPoint2: CGPointMake(mXSideStartPos + mCurveStartXPos + mCurveHalfVLength + mCurveHalfVLength, mTotalHeight)];
        }
        
        [mPieceBezier addLineToPoint: CGPointMake(mTotalWidth, mTotalHeight)];
        
        //-----Right-----
        [mPieceBezier addLineToPoint: CGPointMake(mTotalWidth, mTotalHeight - mCurveStartYPos)];
        
        if([[[self.SCPieceTypeArray objectAtIndex:i] objectAtIndex:SCPieceSideTypeBottom] integerValue] != SCPieceTypeEmpty)
        {
            mCustomDeepness = self.deepnessV * [[[self.SCPieceTypeArray objectAtIndex:i] objectAtIndex:SCPieceSideTypeBottom] intValue];
            
            [mPieceBezier addCurveToPoint: CGPointMake(mTotalWidth - mCustomDeepness, mYSideStartPos + mCurveStartYPos + mCurveHalfHLength)
                            controlPoint1: CGPointMake(mTotalWidth, mYSideStartPos + mCurveStartYPos + mCurveHalfHLength * 2)
                            controlPoint2: CGPointMake(mTotalWidth - mCustomDeepness, mTotalHeight - mCurveHalfHLength)];
            
            [mPieceBezier addCurveToPoint: CGPointMake(mTotalWidth, mYSideStartPos + mCurveStartYPos)
                            controlPoint1: CGPointMake(mTotalWidth - mCustomDeepness, mYSideStartPos + mCurveHalfHLength)
                            controlPoint2: CGPointMake(mTotalWidth, mCurveStartYPos + mYSideStartPos)];
        }
        
        [mPieceBezier addLineToPoint: CGPointMake(mTotalWidth, mYSideStartPos)];
        
        //-----Bottom-----
        [mPieceBezier addLineToPoint: CGPointMake(mTotalWidth - mCurveStartXPos, mYSideStartPos)];
        
        if([[[self.SCPieceTypeArray objectAtIndex:i] objectAtIndex:SCPieceSideTypeLeft] integerValue] != SCPieceTypeEmpty)
        {
            mCustomDeepness = self.deepnessH * [[[self.SCPieceTypeArray objectAtIndex:i] objectAtIndex:SCPieceSideTypeLeft] intValue];
            
            [mPieceBezier addCurveToPoint: CGPointMake(mTotalWidth - mCurveStartXPos - mCurveHalfVLength, mYSideStartPos + mCustomDeepness)
                            controlPoint1: CGPointMake(mTotalWidth - mCurveStartXPos, mYSideStartPos)
                            controlPoint2: CGPointMake(mTotalWidth - mCurveHalfVLength, mYSideStartPos + mCustomDeepness)];
            
            [mPieceBezier addCurveToPoint: CGPointMake(mXSideStartPos + mCurveStartXPos, mYSideStartPos)
                            controlPoint1: CGPointMake(mXSideStartPos + mCurveHalfVLength, mYSideStartPos + mCustomDeepness)
                            controlPoint2: CGPointMake(mXSideStartPos + mCurveStartXPos, mYSideStartPos)];
        }
        
        [mPieceBezier addLineToPoint: CGPointMake(mXSideStartPos, mYSideStartPos)];
        
        
        [self.pieceBezierPathsMutArray addObject:mPieceBezier];
    }
}

- (void)setUpPuzzlePeaceImages
{
    float mXAddableVal = 0;
    
    float mYAddableVal = 0;
    
    for (NSInteger i = 0; i < self.pieceBezierPathsMutArray.count; i++) {
        
        CGRect mCropFrame = [[[self.pieceCoordinateRectArray objectAtIndex:i] objectAtIndex:0] CGRectValue];
        
        CGRect mImageFrame = [[[self.pieceCoordinateRectArray objectAtIndex:i] objectAtIndex:1] CGRectValue];
        
        //拼图小方块
        UIImageView *mPeace = [UIImageView new];
        
        [mPeace setFrame:mImageFrame];
        
        [mPeace setTag:i+100];
        
        [mPeace setUserInteractionEnabled:YES];
        
        [mPeace setContentMode:UIViewContentModeTopLeft];
        
        mXAddableVal = ([[[self.SCPieceTypeArray objectAtIndex:i] objectAtIndex:SCPieceSideTypeTop] intValue] == 1)?self.deepnessV:0;
        
        mYAddableVal = ([[[self.SCPieceTypeArray objectAtIndex:i] objectAtIndex:SCPieceSideTypeLeft] intValue] == 1)?self.deepnessH:0;
        
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
        [mBorderPathLayer setStrokeColor:[UIColor blackColor].CGColor];
        [mBorderPathLayer setLineWidth:2];
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
    CGFloat RangeY = (self.view.frame.size.height - self.originalCatImage.size.height) / 2;
    CGFloat RangeX = self.puzzleBoard.frame.size.width;
    
    for (NSInteger i = 0; i < self.allPiecesArray.count / 2; i++) {
        UIImageView *piece = self.allPiecesArray[i];
        CGPoint location = CGPointMake(arc4random_uniform(RangeX - self.cubeWidthValue) + self.cubeWidthValue / 2, arc4random_uniform(RangeY - self.cubeHeightValue) + self.cubeHeightValue / 2);
        piece.center = location;
    }
    for (NSInteger i = self.allPiecesArray.count / 2; i < self.allPiecesArray.count; i++) {
        UIImageView *piece = self.allPiecesArray[i];
        CGPoint location = CGPointMake(arc4random_uniform(RangeX - self.cubeWidthValue) + self.cubeWidthValue / 2, arc4random_uniform(RangeY - self.cubeHeightValue) + (self.view.frame.size.height - (self.view.frame.size.height - self.originalCatImage.size.height) / 2) + self.cubeHeightValue / 2);
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

@end
