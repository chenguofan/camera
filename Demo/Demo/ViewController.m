//
//  ViewController.m
//  Demo
//
//  Created by Apple on 2022/6/25.
//

#import "ViewController.h"
#import "RemoteShutterViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = UIColor.redColor;
    btn.frame = CGRectMake(0, 0, 100, 100);
    btn.center = self.view.center;
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

-(void)btnClick{
    RemoteShutterViewController *vc = [[RemoteShutterViewController alloc] init];
    [self.navigationController pushViewController:vc animated:true];
}

@end
