//
//  PreViewController.m
//  JieliJianKang
//
//  Created by Apple on 2022/6/23.
//

#import "PreViewController.h"

@interface PreViewController ()

@property(nonatomic,strong) UIImageView *bgImageView;

@end

@implementation PreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    [self initUI];
    
}

-(void)initUI{
    self.view.backgroundColor = UIColor.blackColor;
    self.bgImageView = [[UIImageView alloc] init];
    self.bgImageView.frame = CGRectMake(0, 0,[UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    self.bgImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.bgImageView];
    
    if (self.selectImg != nil) {
        self.bgImageView.image = self.selectImg;
    }
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([UIApplication sharedApplication].statusBarFrame.size.height > 20.0) {
        cancelBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 65,[UIScreen mainScreen].bounds.size.height - 95.0 - 49.0 + 27.5 , 40, 40);
    }else{
        cancelBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 65,[UIScreen mainScreen].bounds.size.height - 95 + 27.5 , 40, 40);
    }
    [cancelBtn setImage:[UIImage imageNamed:@"equipment_camera_cancel"] forState:UIControlStateNormal];
    [cancelBtn setImage:[UIImage imageNamed:@"equipment_camera_cancel"] forState:UIControlStateSelected];
    [cancelBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelBtn];
    
}

-(void)cancel{
    [self dismissViewControllerAnimated:true completion:^{
        
    }];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self dismissViewControllerAnimated:true completion:^{
        
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
