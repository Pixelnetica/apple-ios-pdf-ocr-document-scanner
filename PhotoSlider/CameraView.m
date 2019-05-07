//
//  CameraView.m
//  Example-ImageSDK-iOS
//
//  Created by Andrey Anisimov on 16.12.15.
//
//

#import "CameraView.h"
#import <DocScanningSDK/PxMetaImage.h>
#import <DocScanningSDK/PxDocCutout.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <GLKit/GLKit.h>
#import "extobjc.h"

#import "ImageHelper.h"

#define HEIGHT 1920.0

@interface CameraView () <AVCaptureVideoDataOutputSampleBufferDelegate>


@property (nonatomic,strong) EAGLContext *context;
@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;
@property (nonatomic, assign) CMSampleBufferRef bufRef;
@property (nonatomic, strong) NSTimer *cropTimer;
@property (nonatomic, strong) PxMetaImage *myImage;

@property (nonatomic, retain) AVCaptureSession *session;
@property (nonatomic,retain) AVCaptureDeviceInput *videoInput;


@end

@implementation CameraView
{
    CIContext *_coreImageContext;
    GLuint _renderBuffer;
    GLKView *_glkView;

	PxDocCorners docCorners;
	PxDocCutout* docCutout;
	BOOL docAreaChecked;
	BOOL docDistorsionChecked;

	BOOL _isStopped;
    
    CGFloat _imageDedectionConfidence;
    NSTimer *_borderDetectTimeKeeper;
    BOOL _borderDetectFrame;
    CIRectangleFeature *_borderDetectLastRectangleFeature;
    
    BOOL _isCapturing;
    dispatch_queue_t _captureQueue;
    dispatch_queue_t backgroundQueue;
    CGPoint pts_[4];
    CGPoint pts__[4];
    BOOL busy;
}

- (void) dealloc {
}

- (void) startTimer {
    if(!self.cropTimer) {
        self.cropTimer = [NSTimer scheduledTimerWithTimeInterval: 0.3
                                                          target: self
                                                        selector:@selector(onTick:)
                                                        userInfo: nil repeats:YES];
    } else {
        [self stopTimer];
    }
}

- (CGPoint)convertPoint:(CGPoint)sourcePoint fromContentSize:(CGSize)sourceSize {
	float x = sourcePoint.x;
	float y = sourcePoint.y;

	float hx = sourceSize.width * 0.5f;
	float hy = sourceSize.height * 0.5f;

	x -= hx;
	y -= hy;

	float tx = self.bounds.size.width;
	float ty = self.bounds.size.height;

	tx *= 0.5f;
	ty *= 0.5f;

	float k = tx / hx;
	float kk = ty / hy;

	if( k < kk )
		k = kk;

	x *= k;
	y *= k;

	x += tx;
	y += ty;

    return CGPointMake( x, y );
}

-(void) onTick:(NSTimer *)timer {
    [self detectBorder];
}

- (void) detectBorder {
    if(self.myImage ) {
        //border detection on
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if ([defaults boolForKey:@"borderDetector"]) {
            [self loadPhoto:self.myImage];

			@weakify(self)
			dispatch_async(dispatch_get_main_queue(), ^{
				@strongify(self)

				if( !docCorners.isSmartCropMode )
				{
					[self stopAutoShutTimer];
					[self.calculatedPosDelegate clearOverlay];
					[self.calculatedPosDelegate showLabel:1];
					return;
				}

				unsigned kind = 0;

				do {
					if( !docAreaChecked )
						kind = 2;
					else if( !docDistorsionChecked )
						kind = 3;
					else
						break;

					[self stopAutoShutTimer];
				} while( false );

				[self.calculatedPosDelegate showLabel:kind];

				if( kind == 0 )
					[self startAutoShutTimer];

				CGSize size = self.myImage.image.size;

				CGPoint p0 = [self convertPoint:pts_[0] fromContentSize:size];
				CGPoint p1 = [self convertPoint:pts_[1] fromContentSize:size];
				CGPoint p2 = [self convertPoint:pts_[2] fromContentSize:size];
				CGPoint p3 = [self convertPoint:pts_[3] fromContentSize:size];

				[self.calculatedPosDelegate calculatedTopLeftPos:p0 andTopRightPos:p1 andBottomLeftPos:p2 andBottomRightPos:p3 andColor:[UIColor colorWithRed:0 green:0.8 blue:0.0 alpha:0.6]];
			});
        }
    }
}

- (void) startAutoShutTimer {
    if (!self.autoShotTimer) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if ([defaults boolForKey:@"borderDetector"] && [defaults boolForKey:@"autoShot"]) {
            
            NSString *strTimeout = [defaults objectForKey:@"DelayValue"];
            strTimeout = [strTimeout stringByReplacingOccurrencesOfString:@"," withString:@"."];
            CGFloat timeout = [strTimeout floatValue];
            
            //if(self.shakeDetector.shaking)
            {
                
                if (timeout > 0 && self.autoShotTimer == nil) {
                    
                    if ([self.calculatedPosDelegate respondsToSelector:@selector(progressStart:)]) {
                        [self.calculatedPosDelegate progressStart:(CGFloat) timeout];
                    }
                    self.autoShotTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                                                          target: self
                                                                        selector:@selector(autoShot:)
                                                                        userInfo: nil repeats:NO];
                }
            }
        }
    } 
}

- (void) stopAutoShutTimer {
    if ([self.calculatedPosDelegate respondsToSelector:@selector(progressStop)]) {
        [self.calculatedPosDelegate progressStop];
    }
    [self.autoShotTimer invalidate];
    self.autoShotTimer = nil;
}

- (void) autoShot:(NSTimer *)timer {
    
    @weakify(self)
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self)
        if ([self.calculatedPosDelegate respondsToSelector:@selector(clearOverlay)]) {
            [self.calculatedPosDelegate clearOverlay];
        }
        [self stopTimer];
        
        if ([self.calculatedPosDelegate respondsToSelector:@selector(cameraAutoShot)]) {
            [self.calculatedPosDelegate cameraAutoShot];
        }
    });
}

- (void) stopTimer {
    [self.cropTimer invalidate];
    self.cropTimer = nil;
}

- (void) startCapture {
    [self.captureSession startRunning];
    [self startTimer];
}

- (void) stopCapture {
    [self.captureSession stopRunning];
    [self stopTimer];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    _captureQueue = dispatch_queue_create("com.sharpscan.AVCameraCaptureQueue", DISPATCH_QUEUE_SERIAL);
}

- (void) torchOnOff {
    
    if (self.captureDevice.hasFlash == NO && self.captureDevice.hasTorch == NO) {
        return;
    }
    if (self.torchState) {
        self.torchState = NO;
        [self torchOff];
        [self.calculatedPosDelegate updateTorchButtonStateOff];
    } else {
        self.torchState = YES;
        [self torchOn];
        [self.calculatedPosDelegate updateTorchButtonStateOn];
    }
    //save torch state
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.torchState forKey:@"torchState"];
    [defaults synchronize];
}

- (void) torchOn {
    if (self.captureDevice.hasFlash == NO && self.captureDevice.hasTorch == NO) {
        return;
    }
    [self.captureDevice lockForConfiguration:nil];
    [self.captureDevice setTorchMode:AVCaptureTorchModeOn];
    [self.captureDevice unlockForConfiguration];
}

- (void) torchOff {
    if (self.captureDevice.hasFlash == NO && self.captureDevice.hasTorch == NO) {
        return;
    }
    [self.captureDevice lockForConfiguration:nil];
    [self.captureDevice setTorchMode:AVCaptureTorchModeOff];
    [self.captureDevice unlockForConfiguration];
}

- (AVCaptureDevice *) backFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (void) setupCameraView
{
	self.myImage = [PxMetaImage new:nil];

	docCutout = [PxDocCutout new];

	AVCaptureDevice *device = [self backFacingCamera];
	if (!device)
		return;

    _captureQueue = dispatch_queue_create("com.sharpscan.AVCameraCaptureQueue", DISPATCH_QUEUE_SERIAL);
    // Set torch and flash mode to auto
    if ([device hasFlash]) {
        if ([device lockForConfiguration:nil]) {
            if ([device isFlashModeSupported:AVCaptureFlashModeAuto]) {
                [device setFlashMode:AVCaptureFlashModeOff];
            }
            [device unlockForConfiguration];
        }
    }
    if ([device hasTorch]) {
        if ([device lockForConfiguration:nil]) {
            if ([device isTorchModeSupported:AVCaptureTorchModeAuto]) {
                [device setTorchMode:AVCaptureTorchModeOff];
            }
            [device unlockForConfiguration];
        }
    }
    backgroundQueue = dispatch_queue_create("com.razeware.imagegrabber.bgqueue", NULL);

    _imageDedectionConfidence = 0.0;
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    self.captureSession = session;
    [session beginConfiguration];
    self.captureDevice = device;
    
   
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
    if ([session canAddInput:input]) {
        [session addInput:input];
    }
    
    
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        session.sessionPreset = AVCaptureSessionPreset640x480;
    } else {
        if ([session canSetSessionPreset:AVCaptureSessionPreset3840x2160]) {
            session.sessionPreset = AVCaptureSessionPreset3840x2160;
        }
        else if ([session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
            session.sessionPreset = AVCaptureSessionPreset1920x1080;
        }
        else if ([session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            session.sessionPreset = AVCaptureSessionPreset1280x720;
        }
        else {
            session.sessionPreset = AVCaptureSessionPresetMedium;
        }
    }

    
    AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [dataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)}];
    [dataOutput setSampleBufferDelegate:self queue:_captureQueue];
    [session addOutput:dataOutput];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [session addOutput:self.stillImageOutput];
    
    AVCaptureConnection *connection = [dataOutput.connections firstObject];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    if (device.isFlashAvailable)
    {
        [device lockForConfiguration:nil];
        [device setFlashMode:AVCaptureFlashModeOff];
        [device unlockForConfiguration];
        
        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        {
            [device lockForConfiguration:nil];
            [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [device unlockForConfiguration];
        }
    }
    
    [session commitConfiguration];
    //set saved torch state
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.torchState = [defaults boolForKey:@"torchState"];
    if(self.torchState) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self torchOn];
        });
        
    } else {
        [self torchOff];
    }
    self.orientation = AVCaptureVideoOrientationLandscapeLeft;
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little
                                                 | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

	UIImage* image_ = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationUp];

	// Release the Quartz image
	CGImageRelease(quartzImage);

    @weakify(self)
    dispatch_sync(dispatch_get_main_queue(), ^{
        @strongify(self)
        self.myImage.image = image_;
    });
}

- (BOOL) selectCropArea:(PxMetaImage*)image
{
    CGPoint points [4];
    BOOL smartCrop = [self processCrop:image outPoints:points];
    return smartCrop;
}

- (BOOL) processCrop:(PxMetaImage*)source outPoints:(CGPoint [4])pts
{
    BOOL isSmartCropMode = NO;

	if( source.image )
	{
		BOOL result = [PxSDK detectDocumentCorners:source docCorners:&docCorners];
		if (result)
		{
			isSmartCropMode = docCorners.isSmartCropMode;

			pts [0] = CGPointMake(docCorners.ptUL.x, docCorners.ptUL.y);
			pts [1] = CGPointMake(docCorners.ptUR.x, docCorners.ptUR.y);
			pts [2] = CGPointMake(docCorners.ptBL.x, docCorners.ptBL.y);
			pts [3] = CGPointMake(docCorners.ptBR.x, docCorners.ptBR.y);

			//*
			pts_[0] =  pts [0];
			pts_[1] =  pts [1];
			pts_[2] =  pts [2];
			pts_[3] =  pts [3];
			//*/
			if( isSmartCropMode )
			{
				CGSize size = source.image.size;

				PxPoint pxpts[4];
				PxFromCGPointRect( pts, pxpts );

				[docCutout checkGeometry:pxpts width:(int)size.width height:(int)size.height];

				docAreaChecked = [docCutout isFullnessChecked];
				docDistorsionChecked = [docCutout isDistortionChecked];
			}
		}
	}

	return isSmartCropMode;
}


- (UIImage *)makeUIImageFromCIImage:(CIImage *)ciImage {
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:[ciImage extent]];
    
    UIImage* uiImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return uiImage;
}

#pragma mark -2
//prepare selected image
- (BOOL) loadPhoto:(PxMetaImage*)img
{
    @autoreleasepool
    {
		UIImage* image = img.image;

		CGSize size = image.size;

        CGSize supMaxImageSize = [PxSDK supportedImageSize:size];
        if (CGSizeEqualToSize(size, supMaxImageSize) == NO)
        {
            // Resizes input image img if it size is larger than supported image size.
            img.image = [ImageHelper imageWithImage:image scaledToSize:supMaxImageSize];
        }

		return [self selectCropArea:img];
    }
}

- (void) makeSnapShot {
    
}

- (void) changeToPhotoPreset {
    [self.captureSession beginConfiguration];
    self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    [self.captureSession commitConfiguration];
}

- (void) changeToVideoPreset {
    [self.captureSession beginConfiguration];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    } else {
        if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset3840x2160]) {
            self.captureSession.sessionPreset = AVCaptureSessionPreset3840x2160;
        }
        else if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
            self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
        }
        else if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
            self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        }
        else {
            self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;
        }
    }
    
    [self.captureSession commitConfiguration];
}

- (void)captureImageWithCompletionBlock:(void(^)(UIImage *image))completionHandler {
    dispatch_suspend(_captureQueue);
    
    [self changeToPhotoPreset];
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    self.torchState = [defaults boolForKey:@"torchState"];
//    if(self.torchState){
//        [self torchOn];
//    }
    if (self.torchState) {
        [self torchOn];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        AVCaptureConnection *videoConnection = nil;
        for (AVCaptureConnection *connection in self.stillImageOutput.connections)
        {
            for (AVCaptureInputPort *port in [connection inputPorts])
            {
                if ([[port mediaType] isEqual:AVMediaTypeVideo] )
                {
                    videoConnection = connection;
                    break;
                }
            }
            if (videoConnection) break;
        }
        
        
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
             if (error)
             {
                 dispatch_resume(_captureQueue);
                 return;
             }
             
             @autoreleasepool
             {
                 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                 UIImage *image__ = [[UIImage alloc] initWithData:imageData];
                 
                 dispatch_async(dispatch_get_main_queue(), ^
                                {
									//UIImage *image = [UIImage imageWithCGImage:[image__ CGImage] scale:[image__ scale] orientation: UIImageOrientationUp];
									UIImage *image = image__;

									completionHandler(image);

									dispatch_resume(_captureQueue);
                                });
             }
         }];

    });
}

@end
