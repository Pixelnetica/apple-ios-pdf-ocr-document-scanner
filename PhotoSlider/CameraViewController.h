//
//  CameraViewController.h
//  Example-ImageSDK-iOS
//
//  Created by Andrey Anisimov on 16.12.15.
//
//

#import <DocScanningSDK/PxSDK.h>
#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSInteger, controllerCloseReason) {
    cancelTapReason = 0,
    snapTapReason = 1
};

@interface CameraViewController : UIViewController

@property (nonatomic,readwrite,copy) void (^completion)(NSString *imagePath);
@property (nonatomic,readwrite,copy) void (^imageCompletion)(UIImage *image);

@end
