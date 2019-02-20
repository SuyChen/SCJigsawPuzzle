//
//  HomeViewController.m
//  SuyChenPuzzleDemo
//
//  Created by CSY on 2019/2/20.
//  Copyright © 2019 suychen. All rights reserved.
//

#import "HomeViewController.h"
#import "PuzzleViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface HomeViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *rowNum_lb;
@property (weak, nonatomic) IBOutlet UILabel *columnNum_lb;
@property (weak, nonatomic) IBOutlet UISlider *rowSlider;
@property (weak, nonatomic) IBOutlet UISlider *columnSlider;
@property (weak, nonatomic) IBOutlet UIButton *puzzle_btn;
@property (nonatomic, strong) UIImage *image;
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

}
//添加相册图片
- (IBAction)addPhotos:(id)sender {
    UIAlertController * alerVC = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction * action1 = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self choiceUploadType:UIImagePickerControllerSourceTypeCamera];
    }];
    UIAlertAction * action2 = [UIAlertAction actionWithTitle:@"PhotoLibrary" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self choiceUploadType:UIImagePickerControllerSourceTypePhotoLibrary];
    }];
    UIAlertAction * action3 = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alerVC addAction:action1];
    [alerVC addAction:action2];
    [alerVC addAction:action3];
    [[[[UIApplication sharedApplication]delegate] window].rootViewController presentViewController:alerVC animated:YES completion:nil];
}
//开始拼图
- (IBAction)startPuzzle:(id)sender {
    
    PuzzleViewController *vc = [[PuzzleViewController alloc] init];
    vc.pieceVCount = self.columnSlider.value;
    vc.pieceHCount = self.rowSlider.value;
    if (self.image) {
        vc.originalCatImage = self.image;
    }else{
        
        vc.originalCatImage = [UIImage imageNamed:@"puzzle"];
    }
    [self presentViewController:vc animated:YES completion:nil];
}
- (IBAction)changeRowNum:(id)sender {
    
    self.rowNum_lb.text = [NSString stringWithFormat:@"Row:%ld", (NSInteger)self.rowSlider.value];
}
- (IBAction)changeColumnNum:(id)sender {
    
    self.columnNum_lb.text = [NSString stringWithFormat:@"Column:%ld", (NSInteger)self.columnSlider.value];
}

- (void)choiceUploadType:(NSInteger )type {
    //权限
    ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
    if (author == ALAuthorizationStatusRestricted || author ==ALAuthorizationStatusDenied) {
        NSString * title = @"Album or camera permissions are not turned on";
        NSString * msg = @"Please open the application album or camera service in System Settings\n(Settings -> Privacy -> Album or Camera -> On)";
        NSString * cancelTitle = @"OK";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:nil, nil];
        [alertView show];
        return ;
    }
    UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    imagePickerController.sourceType = type;
    [self presentViewController:imagePickerController animated:YES completion:NULL];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerEditedImage];
    [self.puzzle_btn setImage:image forState:UIControlStateNormal];
    self.image = image;
}

@end
