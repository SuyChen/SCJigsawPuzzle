//
//  PuzzleViewController.h
//  SuyChenPuzzleDemo
//
//  Created by CSY on 2019/2/20.
//  Copyright © 2019 suychen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PuzzleViewController : UIViewController
//原始图片
@property (nonatomic, strong) UIImage *originalCatImage;
//垂直数量
@property (nonatomic, assign) NSInteger pieceVCount;
//水平数量
@property (nonatomic, assign) NSInteger pieceHCount;
@end

NS_ASSUME_NONNULL_END
