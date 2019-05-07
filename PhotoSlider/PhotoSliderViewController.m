//
//  PhotoSliderViewController.m
//  PhotoSlider
//
//  Created by Andrey Glushko on 4/7/13.
//  Copyright 2013 Pixelnetica. All rights reserved.
//

#import "PhotoSliderViewController.h"
#import <DocScanningSDK/PxSDK.h>
#import <DocScanningSDK/PxImageWriter.h>
#import <DocScanningSDK/PxLicense.h>
#import <DocScanningSDK/PxException.h>
#import "ImageHelper.h"
#import "PageEditorController.h"
#import "Error.h"

#import <ImageIO/ImageIO.h> // for exifMetaDataFromFileAtURL

#import <AssetsLibrary/ALAsset.h>
#import <AssetsLibrary/ALAssetRepresentation.h>
#import <ImageIO/CGImageSource.h>
#import <ImageIO/CGImageProperties.h>
#import "UIAlertController+Blocks.h"
#import "UIActionSheet+Blocks.h"
#import "CameraViewController.h"
#import "SettingsViewController.h"
#import "extobjc.h"

@interface PhotoSliderViewController ()

// >>>>>>>>>>> Removes perspective.
- (PxMetaImage*)processPerspective:(PxMetaImage*)source;

// >>>>>>>>>>> Returns document area.
- (BOOL)processCrop:(PxMetaImage*)source outPoints:(PxPoint [4])pts;

// >>>>>>>>>>> Applies profile to the image.
- (void)process;

// >>>>>>>>>>> Different image profiles.
- (PxMetaImage*)doBW:(PxMetaImage*)source;
- (PxMetaImage*)doGray:(PxMetaImage*)source;
- (PxMetaImage*)doColor:(PxMetaImage*)source;
- (PxMetaImage*)doOriginal:(PxMetaImage*)source;

// Helper functions.
- (void)loadPhoto:(PxMetaImage*)meta_img;
- (void)loadPhoto:(UIImage*)img withPath:(NSString*)path;
- (void)loadPhoto:(UIImage*)img withMetadata:(NSDictionary*)metadata;
- (void)setupImagePicker:(UIImagePickerControllerSourceType)sourceType;
- (void)showImagePicker:(UIImagePickerControllerSourceType)sourceType;
- (BOOL)selectCropArea;

@end

@implementation PhotoSliderViewController
{
	UIDocumentInteractionController* m_dic;

	UIImageView *imageView;
	UIImagePickerController *imagePickerController;
	PxPoint points [4];
}

int rotationAngle;

@synthesize isModified;
@synthesize imageView;
@synthesize loadButton;
@synthesize saveButton;
@synthesize inpImage;
@synthesize outImage;

#pragma mark -
#pragma mark PhotoSliderViewController


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	[super viewDidLoad];
    
# pragma mark - DSSDK License key input
    
//    Reading DSSDK license from "license.txt" file. While filename is unsignificant, file should include license key.
    
    NSError* error = nil;
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"license" ofType:@"txt"];
    NSString* key = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (!key) {
        // inspect error
        NSLog(@"\n Error reading license key from file: \"%@\"", [error localizedDescription]);
    }
    

// License key can also be inserted directly in code as follows
//    NSString* key = @"ZIaLsaDx0qUayj28O04jYVcT367MvWCBZdmHILKRSMafmiU3K9sxqIEVLljboI2ABhX/Jkc94VuVfW/YeyOWjf/3RTwjE/9OWkjXXnjzaWi0oa13dYw2/YrO0nUGzbXKqb7+LDByV0p+w8s22kA5jKbTuiCJo2RR1PO1LGnAmdvkqj4ZxlKjdsLIPWxN99HV1UT/ZIPaXeQfCT9sq8oVkiYU9HuWKLm+9YlPCvfHHpvvZg0AvAONRpvLeC1ymxIthPsbgAz+CtmAIYrh3wQr/xfYeQLLVOu4JSy6sPupMRx0n3suLFgEGcFWDDBaEpy0mHnkGDifOW34X/TwVsl2Ow==";
    

# pragma mark DSSDK license initialization
    
// DSSDK License initialization
    
	PxLicenseStatus status = [PxLicense initializeWithKey:key];
    
// License status debug informartion
    
    if( status != PxLicenseStatus_Active )
    {
        
        switch (status) {
            case PxLicenseStatus_None:
                NSLog(@"\n Due to \"No license key specified\" error DSSDK will continue working with results watermarked.");
                break;
            case PxLicenseStatus_Malformed_Key:
                NSLog(@"\n Due to \"Malformed or corrupted license key\" error DSSDK will continue working with results watermarked. \n Please contact <dssdk_support@pixelnetica.com>");
                break;
            case PxLicenseStatus_AppID_Mismatch:
                NSLog(@"\n Due to \"Wrong Bundle ID\" error DSSDK will continue working with results watermarked. \n Please contact <dssdk_support@pixelnetica.com>");
                break;
            case PxLicenseStatus_PlatformID_Mismatch:
                NSLog(@"\n Due to \"Wrong Platform\" error DSSDK will continue working with results watermarked. \n Please contact <dssdk_support@pixelnetica.com>");
                break;
            case PxLicenseStatus_Expired:
                NSLog(@"\n Due to \"The license has expired\" error DSSDK will continue working with results watermarked. \n Please contact <dssdk_support@pixelnetica.com>");
                break;
            case PxLicenseStatus_Subscruption_Expired:
                NSLog(@"\n Due to \"License SMUA has expired\" error DSSDK will continue working with results watermarked. \n Please contact <dssdk_support@pixelnetica.com>");
                break;
                
            default:
                NSLog(@"\n Licens status: \"Unspecified license problem\". \n Please contact <dssdk_support@pixelnetica.com>");
                break;
        }
        
    }
    else NSLog(@"\n DSSDK licens status: \"License is active\"");
    

	imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;

	self.saveButton.enabled = NO;
	self->m_dic = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.loadButton = nil;
    self.saveButton = nil;
    self.inpImage = nil;
    self.outImage = nil;
    self.imageView = nil;
	self->m_dic = nil;
}

- (IBAction)settingsAction:(id)sender {
    
    SettingsViewController *vc = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
    @weakify(vc)
    [self presentViewController:vc animated:NO completion:nil];
    [vc setCompletion:^(NSString *imgPath) {
        @strongify(vc)
        [vc dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (IBAction)rotateLeft:(id)sender {
    [self rotateOnAngle:-90];
}

- (IBAction)rotateRight:(id)sender {
    [self rotateOnAngle:90];
}

- (void)rotateOnAngle:(int)angle
{
    rotationAngle += angle;
	if( rotationAngle < 0 )
		rotationAngle += 360;
	else if( rotationAngle >= 360 )
		rotationAngle -= 360;

	if (rotationAngle == 0) {
		self.outImage.orientation = PxMetaImage_Orientation_Normal;
    } else if (rotationAngle == 90) {
		self.outImage.orientation = PxMetaImage_Orientation_Rotate90;
    } else if (rotationAngle == 180) {
		self.outImage.orientation = PxMetaImage_Orientation_Rotate180;
    } else if (rotationAngle == 270) {
		self.outImage.orientation = PxMetaImage_Orientation_Rotate270;
    }

    self.imageView.image = self.outImage.image;
}

- (IBAction)loadAction:(id)sender
{
    @weakify(self)
    [UIActionSheet showInView:self.view
                    withTitle:@"Please, select image source"
            cancelButtonTitle:@"Cancel"
       destructiveButtonTitle:nil
            otherButtonTitles:@[@"Camera", @"Photo album"]
                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                         @strongify(self)
                         if(buttonIndex == 1) {
                             if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                                 [self dismissViewControllerAnimated:NO completion:^{
                                     [self showImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
                                 }];
                             } else {
                                 [self showImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
                             }
                         } else if(buttonIndex == 0) {
                             // load camera view
                             if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                                 [self dismissViewControllerAnimated:NO completion:^{
                                     [self openCameraView];
                                 }];
                             } else {
                                 [self openCameraView];
                             }
                        }
                     }];
}

- (void) openCameraView {
//	CameraViewController *vc = [[CameraViewController alloc] initWithSdk:sdk];
	CameraViewController *vc = [CameraViewController new];

    [self presentViewController:vc animated:YES completion:NULL];
    @weakify(vc)
    [vc setCompletion:^(NSString *imgPath) {
        @strongify(vc)
        //return temp saved image path
        [vc dismissViewControllerAnimated:YES completion:nil];
        if(imgPath) {
            UIImage *img = [UIImage imageWithContentsOfFile:imgPath];
			
            [self loadPhoto:img withPath:imgPath];
            [self selectCropArea];
        }
    }];
    [vc setImageCompletion:^(UIImage *img) {
        //return image
        @strongify(vc)
        [vc dismissViewControllerAnimated:YES completion:nil];
        if(img) {
			[self loadPhoto:[PxMetaImage new:img]];
            [self selectCropArea];
        }
    }];
}

- (IBAction)saveAction:(id)sender
{
    if( !self.outImage )
		return;

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	PxImageWriter_Type img_writer_type = PxImageWriter_Type_JPEG;
	NSString* file_ext = @"jpg";

	NSString* uti = @"public.jpeg";

	uint save_format = (uint)[defaults integerForKey:@"selectedSaveFormat"];
	switch( save_format )
	{
		case 0:
		{
			img_writer_type = PxImageWriter_Type_PDF;
			file_ext = @"pdf";
			uti = @"com.adobe.pdf";
			break;
		}

		case 1:
		{
			img_writer_type = PxImageWriter_Type_PNG_EXT;
			file_ext = @"pdf";
			uti = @"com.adobe.pdf";
			break;
		}

		case 2:
		{
			img_writer_type = PxImageWriter_Type_TIFF;
			file_ext = @"tiff";
			uti = @"public.tiff";
			break;
		}

		case 3:
		{
			img_writer_type = PxImageWriter_Type_PNG_EXT;
			file_ext = @"png";
			uti = @"public.png";
			break;
		}
/*
		case 4:
		{
			img_writer_type = PxImageWriter_Type_JPEG;
			break;
		}
 */
	}

	PxImageWriter* img_writer = [PxImageWriter newWithType:img_writer_type];

	NSString* file_name = [@"image." stringByAppendingString:file_ext];

	NSString* dir_path = NSTemporaryDirectory();
//	NSString* dir_path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];

	NSString* file_local_path = [dir_path stringByAppendingPathComponent:file_name];

	NSString* file_local_path2 = file_local_path;
	if( save_format == 1 )
		// PDF from PNG => build PNG file first
		file_local_path2 = [file_local_path stringByAppendingString:@".png"];

	if( ![img_writer open:file_local_path2] )
	{
		[Error Alert:self title:@"Error" message:@"failed to start sequence '%@'!", file_local_path2];
		return;
	}

	BOOL simulate_multi_page_file = [defaults boolForKey:@"simulateMultipageFile"];
	if( save_format > 2 )
		simulate_multi_page_file = NO;

	int c = 1;
	if( simulate_multi_page_file && save_format != 1 )
		c += 2;

	NSString* s;

	// Pick original orientation
	PxMetaImage_Orientation original_orientation = self.outImage.orientation;

	if( save_format == 1 )
		self.outImage.orientation = PxMetaImage_Orientation_Normal;

	@try {
		do {
			if( (s = [img_writer write:self.outImage]) == nil )
			{
				[Error Alert:self title:@"Error" message:@"failed to write '%@'!", file_local_path2];
				break;
			}
		} while( --c > 0 );
	} @catch( PxException* e ) {
		// License error
		s = nil;
	}

	[img_writer close];

	if( s == nil )
		return;

	if( save_format == 1 )
	{
		self.outImage.orientation = original_orientation;

		img_writer = [PxImageWriter newWithType:PxImageWriter_Type_PDF];

		if( ![img_writer open:file_local_path] )
		{
			[Error Alert:self title:@"Error" message:@"failed to start sequence '%@'!", file_local_path];
			return;
		}

		c = 1;
		if( simulate_multi_page_file )
			c += 2;

		@try {
			do {
				if( (s = [img_writer writeFile:file_local_path2 :PxImageWriter_FileType_PNG :original_orientation]) == nil )
				{
					[Error Alert:self title:@"Error" message:@"failed to write '%@'!", file_local_path];
					break;
				}
			} while( --c > 0 );
		} @catch( PxException* e ) {
			// License error
			s = nil;
		}

		[img_writer close];

		if( s == nil )
			return;
	}

	NSURL* file_url = [NSURL fileURLWithPath:file_local_path];

	m_dic = [UIDocumentInteractionController interactionControllerWithURL:file_url];
	m_dic.UTI = uti;

	if( ! [m_dic presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES] )
	{
		[Error Alert:self title:@"Error" message:@"failure open the file sharing dialog"];
		return;
	}

	//self.saveButton.enabled = NO;
}

- (UIViewController*)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController*)controller
{
	return self;
}

- (void)showImagePicker:(UIImagePickerControllerSourceType)sourceType
{
    if (self.imageView.isAnimating) {
        [self.imageView stopAnimating];
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:sourceType])
    {
        [self setupImagePicker:sourceType];
        [self presentViewController:imagePickerController animated:YES completion:NULL];
    }
}

- (void)setupImagePicker:(UIImagePickerControllerSourceType)sourceType
{
    imagePickerController.sourceType = sourceType;
    imagePickerController.allowsEditing = NO;
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    @weakify(self)
    //UIImage *img;// = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    NSLog(@"");
//got selected image
    void (^LoadPhotoBlock)(NSDictionary *metadata, UIImage *image) = ^(NSDictionary *metadata, UIImage *image) {
        @strongify(self)
        [self dismissViewControllerAnimated:YES completion:^(void){
            [self loadPhoto:image withMetadata:metadata];
            [self selectCropArea]; //try to get crop
        }];
    };

	NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    if (assetURL)
    {
        ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
        {
            NSDictionary *metadata = myasset.defaultRepresentation.metadata;
            UIImage *image = [UIImage imageWithCGImage:myasset.defaultRepresentation.fullResolutionImage];
            LoadPhotoBlock(metadata, image);
        };
        ALAssetsLibraryAccessFailureBlock failureblock = ^(NSError *myerror)
        {
            NSLog(@"cant get image - %@", [myerror localizedDescription]);
            LoadPhotoBlock(nil, nil);
        };
        ALAssetsLibrary *assetsLib = [[ALAssetsLibrary alloc] init];
        [assetsLib assetForURL:assetURL resultBlock:resultblock failureBlock:failureblock];
    }
    
/*
    [self loadPhoto:img];
    [self dismissViewControllerAnimated:YES completion:^(void){
        [self selectCropArea]; }];
 */
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)img editingInfo:(NSDictionary *)editingInfo
{
    NSDictionary *dict = [NSDictionary dictionaryWithObject:img forKey:@"UIImagePickerControllerOriginalImage"];
    [self imagePickerController: imagePickerController didFinishPickingMediaWithInfo:dict];
}

#pragma mark - PageEditorControllerDelegate

-(void)pageEditorController:(PageEditorController *)editor didFinishedEditingPage:(CGPoint [4])pts
{
	PxFromCGPointRect(pts, points);
//    [editor dismissModalViewControllerAnimated:YES];
    [editor dismissViewControllerAnimated:YES completion:nil];
    [self process];
}

-(void)pageEditorControllerCancel:(PageEditorController *)editor
{
//    [editor dismissModalViewControllerAnimated:YES];
    [editor dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -

- (BOOL)selectCropArea
{
    BOOL smartCrop = [self processCrop:self.inpImage outPoints:points];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(![defaults boolForKey:@"cropState"] || !smartCrop) {
    
        // Open Page Editor window for manual crop
        //add modal view controller for show crop result

		CGPoint cg_points[4];
		PxToCGPointRect(points, cg_points);
        PageEditorController *pageEditor = [PageEditorController createWith:self.inpImage.image points:cg_points];
        pageEditor.delegate = self;
        [self presentViewController:pageEditor animated:NO completion:NULL];
    } else if([defaults boolForKey:@"cropState"] && smartCrop) {
        [self process];
    }
    return smartCrop;
}

#pragma mark -

- (void) loadPhoto:(UIImage*)img withPath:(NSString*)path
{
	PxMetaImage* meta_img = [PxMetaImage new:img withPath:path];

	return [self loadPhoto:meta_img];
}

- (void) loadPhoto:(UIImage*)img withMetadata:(NSDictionary*)metadata
{
	PxMetaImage* meta_img = [PxMetaImage new:img withMetadata:metadata];

	return [self loadPhoto:meta_img];
}

- (void) loadPhoto:(PxMetaImage*)meta_img
{
    @autoreleasepool
    {
		UIImage* img = meta_img.image;
        CGSize supMaxImageSize = [PxSDK supportedImageSize:img.size];
        if (CGSizeEqualToSize(img.size, supMaxImageSize) == NO)
            // Resizes input image img if it size is larger than supported image size.
            meta_img.image = [ImageHelper imageWithImage:img scaledToSize:supMaxImageSize];

        self.inpImage = meta_img;
        self.imageView.image = meta_img.image;
        self.saveButton.enabled = NO;
    }
}

- (void)process
{
    PxMetaImage *outImg;

	@autoreleasepool
    {
        outImg = [self processPerspective:self.inpImage];

        self.inpImage = nil;

		if( outImg )
		{
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			if([defaults integerForKey:@"selectedProfile"] == 0) {
				outImg = [self doOriginal:outImg];
			}
			else if([defaults integerForKey:@"selectedProfile"] == 1) {
				outImg = [self doBW:outImg];
			}
			else if([defaults integerForKey:@"selectedProfile"] == 2) {
				outImg = [self doGray:outImg];
			}
			else if([defaults integerForKey:@"selectedProfile"] == 3) {
				outImg = [self doColor:outImg];
			}
		}
    }

	switch( outImg.orientation )
	{
		case PxMetaImage_Orientation_Normal:
			rotationAngle = 0;
			break;
		case PxMetaImage_Orientation_Rotate90:
			rotationAngle = 90;
			break;
		case PxMetaImage_Orientation_Rotate180:
			rotationAngle = 180;
			break;
		case PxMetaImage_Orientation_Rotate270:
			rotationAngle = 270;
			break;
		default:
			break;
	}

    // Save the image to disk and load it back!
	/*
    if (outImg)
    {
        // Save the image to disk and load it back!
        NSString *path =
        [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
         stringByAppendingPathComponent:@"image.jpg"];
        assert(path);
        const CGFloat compressionQuality = 0.8f;
        NSData *data = UIImageJPEGRepresentation(outImg.image, compressionQuality);
        NSURL *url = [NSURL fileURLWithPath:path];
        [data writeToURL:url atomically:YES];
        
        outImg.image = [UIImage imageWithContentsOfFile:path];
    }
	 //*/
    
    if (outImg)
        self.saveButton.enabled = YES;

	self.imageView.image = outImg.image;
    self.outImage = outImg;
}

- (PxMetaImage*)processPerspective:(PxMetaImage*)source
{
    // Get image without perspective distortion.
    return [PxSDK correctDocument:source corners:points];
}

- (BOOL)processCrop:(PxMetaImage*)source outPoints:(PxPoint [4])pts
{
    
    BOOL isSmartCropMode = NO;
    PxDocCorners docCorners;
	BOOL result = [PxSDK detectDocumentCorners:source docCorners:&docCorners];
    if (result)
	{
        isSmartCropMode = docCorners.isSmartCropMode;

		pts[0] = docCorners.ptUL;
		pts[1] = docCorners.ptUR;
		pts[2] = docCorners.ptBL;
		pts[3] = docCorners.ptBR;
    }
    return isSmartCropMode;
}

#pragma mark -

- (PxMetaImage*)doBW:(PxMetaImage*)source
{
    return [PxSDK imageBWBinarization:source];
}

- (PxMetaImage*)doGray:(PxMetaImage*)source
{
    return [PxSDK imageGrayBinarization:source];
}

- (PxMetaImage*)doColor:(PxMetaImage*)source
{
    return [PxSDK imageColorBinarization:source];
}

- (PxMetaImage*)doOriginal:(PxMetaImage*)source
{
    return [PxSDK imageOriginal:source];
}

@end
