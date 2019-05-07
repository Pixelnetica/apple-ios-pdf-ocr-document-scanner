//
//  CameraView.h
//  Example-ImageSDK-iOS
//
//  Created by Andrey Anisimov on 16.12.15.
//
//

#import <DocScanningSDK/PxSDK.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol CameraViewDelegate <NSObject>
- (void) calculatedTopLeftPos:(CGPoint) topLeftPos andTopRightPos:(CGPoint) topRightPos andBottomLeftPos:(CGPoint) bottomLeftPos andBottomRightPos:(CGPoint) bottomRightPos andColor:(UIColor*) color;
- (void) clearOverlay;
- (void) showLabel:(unsigned)kind;
- (void) updateTorchButtonStateOn;
- (void) updateTorchButtonStateOff;
- (void) progressStart:(CGFloat) animationTime;
- (void) progressStop;
- (void) cameraAutoShot;
@end

@interface CameraView : UIView
@property (nonatomic,weak) id <CameraViewDelegate> calculatedPosDelegate;
@property (nonatomic,strong) AVCaptureSession *captureSession;
@property (nonatomic,strong) AVCaptureDevice *captureDevice;
@property (nonatomic, assign) BOOL torchState;
@property (nonatomic, assign) AVCaptureVideoOrientation orientation;
@property (nonatomic, strong) NSTimer *autoShotTimer;
- (void) setupCameraView;
- (void) startCapture;
- (void) stopCapture;
- (void) torchOnOff;
- (void) torchOn;
- (void) torchOff;
//- (void)captureImageWithCompletionHander:(void(^)(NSString *imageFilePath))completionHandler;
- (void)captureImageWithCompletionBlock:(void(^)(UIImage *image))completionHandler;
@end
