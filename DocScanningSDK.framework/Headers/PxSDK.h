/**
 * @file PxSDK.h
 * @brief SDK main API interface
 */

#pragma once

#import "PxSDKTypes.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PxMetaImage;

/**
 * @interface PxSDK
 * @brief SDK main API class 
 */
@interface PxSDK : NSObject

/**
 * @brief Returns max supported image size. This function is not thread safe
 * @param imageSize input image size
 * @return maximal supported image size. Special case: for input (-1, -1) returns maximal image dimensions.
 */
+ (CGSize) supportedImageSize:(CGSize)imageSize;

/**
 * @brief Detects document in the page image and saves document detection quality into the page
 * @param image source image containig the document
 * @param docCorners detection parameters on input and receives detection result on output
 * @return YES on success, otherwise NO.
 */
+ (BOOL) detectDocumentCorners:(PxMetaImage* _Nonnull)image docCorners:(PxDocCorners* _Nonnull)docCorners;

/**
 * @brief Check document corners validity
 * @param corners document corners to validate
 * @param width rotated image width
 * @param height rotated image height
 * @return true if corners are valid.
 */
+ (BOOL) validateDocumentCorners:(const PxPoint[_Nonnull 4])corners width:(uint)width height:(uint)height;

/**
 * @brief Try to regulate document corners compliance to order UL-UR-BL-BR
 * @param corners document corners to validate
 * @return true if corners are valid and regulation was successful.
 */
+ (BOOL) regulateDocumentCorners:(PxPoint[_Nonnull 4])corners;

/**
 * @brief Corrects document perspective distortions in the image, warping corners to corrected image rectangle
 * @param image source image containig the document
 * @param corners 4 corners in the source image coordinate space with the following sequence: (top;left), (top;right),
 *        (bottom;left), (bottom:right). Origin point (0,0) is top-left corner of source image.
 *        All 4 corners are within the source image.
 * @return image containing the document without perpective distortions.
 */
+ (PxMetaImage* _Nonnull) correctDocument:(PxMetaImage* _Nonnull)image corners:(const PxPoint[_Nonnull 4])corners;

/**
 * @brief Creates a new UIImage as a copy of source image with applying UIImageOrientation flag to it
 * @param image image to process
 * @return rotated image.
 */
+ (PxMetaImage* _Nonnull) imageWithoutRotation:(PxMetaImage* _Nonnull)image;

/**
 * @brief Returns new image with orientation reset to normal
 * @param image image to process
 * @return thr resulting image.
 */
+ (PxMetaImage* _Nonnull) imageOriginal:(PxMetaImage* _Nonnull)image;

/**
 * @brief
 * @param image image to process
 * @return black/white binarized image.
 */
+ (PxMetaImage* _Nonnull) imageBWBinarization:(PxMetaImage* _Nonnull)image;

/**
 * @brief
 * @param image image to process
 * @return gray (monochrome) binarized image.
 */
+ (PxMetaImage* _Nonnull) imageGrayBinarization:(PxMetaImage* _Nonnull)image;

/**
 * @brief
 * @param image image to process
 * @return color binarized image.
 */
+ (PxMetaImage* _Nonnull) imageColorBinarization:(PxMetaImage* _Nonnull)image;

@end
