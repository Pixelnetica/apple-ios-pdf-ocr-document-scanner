//
//  CameraViewController.m
//  Example-ImageSDK-iOS
//
//  Created by Andrey Anisimov on 16.12.15.
//
//

#import "CameraViewController.h"
#import "CameraView.h"
#import "CameraOverlayView.h"
#import "CircularProgressView.h"

@interface CameraViewController () <CameraViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, weak) IBOutlet CameraView *camView;
@property (nonatomic, weak) IBOutlet CameraOverlayView *overlayView;
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, weak) IBOutlet UILabel *label;
@property (nonatomic, weak) IBOutlet UILabel *labelForDocArea;
@property (nonatomic, weak) IBOutlet UILabel *labelForDocDistortion;
@property (nonatomic, weak) IBOutlet UIButton *flashButton;
@property (nonatomic, weak) IBOutlet UIImageView *flashImageView;
@property (nonatomic, weak) IBOutlet CircularProgressView *progressView;
@end

@implementation CameraViewController
{
}

- (CameraViewController*) init
{
	CameraViewController* vc = [self initWithNibName:@"CameraViewController" bundle:nil];

	return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraAutoShot)];
    [singleTap setDelegate:self];
    [singleTap setNumberOfTapsRequired:1];
    [self.overlayView addGestureRecognizer:singleTap];//areaOverlayView
    
    // Do any additional setup after loading the view from its nib.
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	//CGSize size = [UIScreen mainScreen].bounds.size;
	//self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    self.camView.calculatedPosDelegate = self;

    [self.progressView setupCircleView];
    self.progressView.layer.cornerRadius = self.progressView.frame.size.width/2;
    self.progressView.hidden = YES;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
	[self.camView setupCameraView];
    [self.camView startCapture];
    
    if (self.camView.captureDevice.hasFlash == YES && self.camView.captureDevice.hasTorch == YES) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if([defaults boolForKey:@"torchState"]) {
            [self updateTorchButtonStateOn];
        } else {
            [self updateTorchButtonStateOff];
        }
    }

    if (self.camView.captureSession) {
        AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.camView.captureSession];
        UIView *view = self.camView;
        CALayer *viewLayer = [view layer];
        //[viewLayer setMasksToBounds:YES];
        
        CGRect bounds = [view bounds];

        [newCaptureVideoPreviewLayer setFrame:bounds];
        
        if ([newCaptureVideoPreviewLayer.connection isVideoOrientationSupported])
            [newCaptureVideoPreviewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        
		[newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [viewLayer insertSublayer:newCaptureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
        [self setCaptureVideoPreviewLayer:newCaptureVideoPreviewLayer];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [self.camView torchOff];
    [self.camView stopCapture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updateTorchButtonStateOn {
    self.flashImageView.image = [UIImage imageNamed:@"camera-torch"];
}

- (void) updateTorchButtonStateOff {
    
    
    self.flashImageView.image = [UIImage imageNamed:@"camera-torch_off"];
}
- (IBAction)flashModeAction:(id)sender {
    [self.camView torchOnOff];
}

- (IBAction)closeView:(id)sender {
    [self complete:nil];
}

- (IBAction)snapShot:(id)sender {
    
    //    [self.camView captureImageWithCompletionHander:^(NSString *imageFilePath) {
    //        [self complete:imageFilePath];
    //    }];
    
    [self.camView captureImageWithCompletionBlock:^(UIImage *image) {
        [self imageComplete:image];
    }];
    
}

- (void) progressStart:(CGFloat) animationTime {
    self.progressView.hidden = NO;
    [self.progressView startWithMaxTime:animationTime];
}

- (void) progressStop {
    [self.progressView stop];
    self.progressView.hidden = YES;
}

- (void) cameraAutoShot {
    [self snapShot: nil];
}

- (void) showLabel:(unsigned)kind {
	self.label.hidden = kind != 1;
	self.labelForDocArea.hidden = kind != 2;
	self.labelForDocDistortion.hidden = kind != 3;
}

-(void) calculatedTopLeftPos:(CGPoint) topLeftPos andTopRightPos:(CGPoint) topRightPos andBottomLeftPos:(CGPoint) bottomLeftPos andBottomRightPos:(CGPoint) bottomRightPos andColor:(UIColor *)color {
    
    [self.overlayView setCornersTopLeft:topLeftPos andTopRight:topRightPos andBottomLeft:bottomLeftPos andBottomRight:bottomRightPos andColor:color];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW,
                                            (int64_t)(0.001 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self.overlayView display];
    });
    
}

- (void) clearOverlay {
    [self.overlayView clearView];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW,
                                            (int64_t)(0.001 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self.overlayView display];
    });
}


- (void)imageComplete:(UIImage*) image {
    if (_imageCompletion)
        _imageCompletion(image);
    self.imageCompletion = nil;
}

- (void)complete:(NSString*) reason {
    if (_completion)
        _completion(reason);
    self.completion = nil;
}

@end
