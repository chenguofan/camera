//
//  RemoteShutterViewController.m
//
//

#import "RemoteShutterViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "PreViewController.h"

@interface RemoteShutterViewController ()
<UIGestureRecognizerDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
AVCapturePhotoCaptureDelegate>
{
    BOOL _flashOn;
}

//AVCaptureSession对象 来执行输入设备和输出设备之间的数据传递
@property (nonatomic,strong) AVCaptureSession * session;

//输入设备 调用所有的输入硬件。例如摄像头和麦克风
@property (nonatomic,strong) AVCaptureDeviceInput *videoInput;

//照片输出流 用于输出图像
@property (nonatomic,strong) AVCapturePhotoOutput *imageOutPut;

@property (nonatomic,strong) UIView * bottomView;
@property (nonatomic,strong) UIButton * leftBtn;
@property (nonatomic,strong) UIButton * rightBtn;
@property (nonatomic,strong) UIButton * photosBtn;

//预览图层  镜头捕捉到得预览图层
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;

//   记录开始的缩放比例
@property(nonatomic,assign) CGFloat beginGestureScale;

//   最后的缩放比例
@property(nonatomic,assign) CGFloat effectiveScale;

@end

@implementation RemoteShutterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化照相相关
    [self initAVCaptureSession];
    
    //手势
    [self setUpGesture];
    
    [self initUI];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = YES;
    
    if (self.session){
        [self.session startRunning];
    }
     
    //判断相机的权限
    [self canCameraHasAuthorization];
    
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    if (self.session){
        [self.session stopRunning];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
}

-(void)canCameraHasAuthorization{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        // 判断授权状态
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusRestricted) {
            UIAlertController *alterVC = [UIAlertController alertControllerWithTitle:@""
                                                                             message:@"系统原因，无法使用相机"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alterVC addAction:okAction];
            [self presentViewController:alterVC animated:true completion:^{
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:^(BOOL success) {
                        }];
                }
            }];
        } else if (authStatus == AVAuthorizationStatusDenied) { // 用户拒绝当前应用访问相机
            UIAlertController *alterVC = [UIAlertController alertControllerWithTitle:@"警告"
                                                                             message:@"请去-> [设置 - 隐私 - 相机 - 念加运动] 打开访问开关"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alterVC addAction:okAction];
            [self presentViewController:alterVC animated:true completion:^{
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:^(BOOL success) {
                        }];
                }
            }];
        }else if (authStatus == AVAuthorizationStatusNotDetermined) { // 用户还没有做出选择
            // 弹框请求用户授权
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
                    if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
                        sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
                    }
                }
            }];
        }else{
            NSLog(@"相机可用");
        }
    }
}

-(void)initUI{
    
    self.effectiveScale = self.beginGestureScale = 1.0f;
    
    self.leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.leftBtn.frame = CGRectMake(25,[UIApplication sharedApplication].statusBarFrame.size.height,40,40);
    self.leftBtn.tag = 100;
    [self.leftBtn setImage:[UIImage imageNamed:@"equipment_camera_flashlight_automatic"] forState:UIControlStateNormal];
    [self.leftBtn setImage:[UIImage imageNamed:@"equipment_camera_flashlight_off"] forState:UIControlStateSelected];
    [self.leftBtn addTarget:self action:@selector(lightOff:) forControlEvents:UIControlEventTouchUpInside];
    self.leftBtn.selected = !_flashOn;
    [self.view addSubview:self.leftBtn];
    
    self.rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.rightBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 65,[UIApplication sharedApplication].statusBarFrame.size.height
                                     , 40, 40);
    self.rightBtn.tag = 200;
    [self.rightBtn setImage:[UIImage imageNamed:@"equipment_camera_shot"] forState:UIControlStateNormal];
    [self.rightBtn setImage:[UIImage imageNamed:@"equipment_camera_shot"] forState:UIControlStateSelected];
    [self.rightBtn addTarget:self action:@selector(cameraSwitch:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.rightBtn];
    
    self.bottomView = [[UIView alloc] init];
    if ([UIApplication sharedApplication].statusBarFrame.size.height > 20) {
        self.bottomView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 95.0 - 49.0, [UIScreen mainScreen].bounds.size.width, 95.0 + 49.0);
    }else{
        self.bottomView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 95, [UIScreen mainScreen].bounds.size.width, 95.0);
    }
    [self.view addSubview:self.bottomView];
    
    self.photosBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.photosBtn.frame = CGRectMake(25, 27.5, 40, 40);
    [self.photosBtn setImage:[UIImage imageNamed:@"equipment_camera_img"] forState:UIControlStateNormal];
    [self.photosBtn setImage:[UIImage imageNamed:@"equipment_camera_img"] forState:UIControlStateSelected];
    [self.photosBtn addTarget:self action:@selector(selectPicture:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.photosBtn];
    
    UIButton *takePhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    takePhotoBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2.0 - 37.5, 10, 75, 75);
    [takePhotoBtn setBackgroundImage:[UIImage imageNamed:@"equipment_camera_button"] forState:UIControlStateNormal];
    [takePhotoBtn setBackgroundImage:[UIImage imageNamed:@"equipment_camera_button"] forState:UIControlStateSelected];
    takePhotoBtn.layer.cornerRadius = 37.5;
    [takePhotoBtn addTarget:self action:@selector(takePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:takePhotoBtn];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 65, 27.5, 40, 40);
    [cancelBtn setImage:[UIImage imageNamed:@"equipment_camera_cancel"] forState:UIControlStateNormal];
    [cancelBtn setImage:[UIImage imageNamed:@"equipment_camera_cancel"] forState:UIControlStateSelected];
    [cancelBtn addTarget:self action:@selector(cancelTakePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:cancelBtn];
}

#pragma mark --5个按钮的点击事件
-(void)lightOff:(UIButton *)btn{
    btn.selected = !btn.selected;
    if (btn.selected == true) {
        _flashOn = false;
    }else{
        _flashOn = true;
    }
    AVCaptureDevice *device = self.videoInput.device;
    AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
    //必须判定是否有闪光灯，否则如果没有闪光灯会崩溃
    if ([device hasFlash]){
        if (_flashOn == true) {
            settings.flashMode = AVCaptureFlashModeOn;
        }else{
            settings.flashMode = AVCaptureFlashModeOff;
        }
    }
    [self.imageOutPut capturePhotoWithSettings:settings delegate:self];
}

-(void)selectPicture:(UIButton *)btn{
    UIImagePickerController *pickerVC = [[UIImagePickerController alloc] init];
    pickerVC.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    pickerVC.delegate = self;
    [self presentViewController:pickerVC animated:YES completion:nil];
}

/// 切换摄像头
///
-(void)cameraSwitch:(UIButton *)btn{
    AVCaptureDeviceInput *currentInput = self.videoInput;
    AVCaptureDeviceInput *newVideoInput;
    if (currentInput.device.position == AVCaptureDevicePositionBack) {
        AVCaptureDevice *font = [self getCameraWithPosition:AVCaptureDevicePositionFront];
        NSError *error;
        newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:font error:&error];
        if (error != nil) {
            NSLog(@"error == %@",error);
        }
    }else if (currentInput.device.position == AVCaptureDevicePositionFront){
        AVCaptureDevice *back = [self getCameraWithPosition:AVCaptureDevicePositionBack];
        NSError *error;
        newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:back error:&error];
    }else{
        return;
    }
    [self.session beginConfiguration];
    [self.session removeInput:currentInput];
    if ([self.session canAddInput:newVideoInput]) {
        [self.session addInput:newVideoInput];
        self.videoInput = newVideoInput;
    }else{
        [self.session addInput:currentInput];
    }
    [self.session commitConfiguration];
}

-(void)takePhoto:(UIButton *)btn{
    AVCaptureConnection *connection = [self.imageOutPut connectionWithMediaType:AVMediaTypeVideo];
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    AVCapturePhotoSettings * settings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecTypeJPEG}];
    if (self.videoInput.device.hasFlash == true) {
        if (_flashOn == true) {
            settings.flashMode = AVCaptureFlashModeOn;
        }else{
            settings.flashMode = AVCaptureFlashModeOff;
        }
    }
    [self.imageOutPut capturePhotoWithSettings:settings delegate:self];
//    [DFTips showHUDAddedTo:self.view animated:true];
    
}

-(void)logoutTakePhoto{
    [self.navigationController popViewControllerAnimated:true];
}

-(void)cancelTakePhoto:(UIButton *)btn{
    [self.navigationController popViewControllerAnimated:YES];
}

-(AVCaptureDevice *)getCameraWithPosition:(AVCaptureDevicePosition )position{
    AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
    NSArray * devices = [session devices];
    
    for (AVCaptureDevice * device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return  nil;
}

- (void)initAVCaptureSession{
    if ([self getCameraWithPosition:AVCaptureDevicePositionBack] == nil) {
        return;
    }
    
    AVCaptureDevice *backCamera = [self getCameraWithPosition:AVCaptureDevicePositionBack];
    NSError *error = nil;
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:backCamera error:&error];
    if (error != nil) {
        NSLog(@"相机输入出现错误");
        return;
    }
    
    self.videoInput = input;
    self.session = [[AVCaptureSession alloc] init];
    [self.session beginConfiguration];
    
    AVCaptureSessionPreset preset = AVCaptureSessionPreset1280x720;
    if ([self.session canSetSessionPreset:preset]) {
        self.session.sessionPreset = preset;
    }else{
        self.session.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    
    self.imageOutPut = [[AVCapturePhotoOutput alloc] init];
    self.imageOutPut.livePhotoCaptureEnabled = false;
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    if ([self.session canAddOutput:self.imageOutPut]) {
        [self.session addOutput:self.imageOutPut];
    }
    
    [self.session commitConfiguration];
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    self.previewLayer.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    [self.view.layer addSublayer:self.previewLayer];
 
    [self.view bringSubviewToFront:self.leftBtn];
    [self.view bringSubviewToFront:self.rightBtn];
    [self.view bringSubviewToFront:self.bottomView];
    
}

//接下来搞一个获取设备方向的方法，再配置图片输出的时候需要使用
-(AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

#pragma 创建手势
- (void)setUpGesture{
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinch.delegate = self;
    [self.view addGestureRecognizer:pinch];
}

//缩放手势 用于调整焦距
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.view];
        CGPoint convertedLocation = [self.previewLayer convertPoint:location fromLayer:self.previewLayer.superlayer];
        if ( ! [self.previewLayer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        self.effectiveScale = self.beginGestureScale * recognizer.scale;
        if (self.effectiveScale < 1.0){
            self.effectiveScale = 1.0;
        }
//        NSLog(@"%f-------------->%f------------recognizerScale%f",self.effectiveScale,self.beginGestureScale,recognizer.scale);
        CGFloat maxScaleAndCropFactor = [[self.imageOutPut connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        
//        NSLog(@"%f",maxScaleAndCropFactor);
        if (self.effectiveScale > maxScaleAndCropFactor)
            self.effectiveScale = maxScaleAndCropFactor;
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:.025];
        [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        [CATransaction commit];
    }
}

#pragma mark 手势代理
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}

#pragma mark --UIImagePickerController
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    UIImage *resultImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    //使用模态返回到软件界面
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        PreViewController *preVC = [[PreViewController alloc] init];
        preVC.selectImg = resultImage;
        preVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:preVC animated:true completion:^{
            
        }];
    }];
    
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    //这是捕获点击右上角cancel按钮所触发的事件，如果我们需要在点击cancel按钮的时候做一些其他逻辑操作。就需要实现该代理方法，如果不做任何逻辑操作，就可以不实现
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error API_AVAILABLE(ios(11.0), macCatalyst(14.0)) API_UNAVAILABLE(tvos){
 
    if (!error) {
        //使用该方式获取图片，可能图片会存在旋转的问题，在使用的时候调整
        NSData *data = [photo fileDataRepresentation];
        UIImage *image = [UIImage imageWithData:data];
        NSLog(@"image == %@",image);
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
    }
    
//    [DFTips hideHUDForView:self.view animated:true];
    
}

@end

