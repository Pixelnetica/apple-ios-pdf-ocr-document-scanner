/**
 * @file PxDocCutout.h
 */

#pragma once

#import "PxSDKTypes.h"
#import <Foundation/Foundation.h>

/**
 * @interface PxDocCutout
 * @brief Helper class to validate and configure document bounds
 */
@interface PxDocCutout : NSObject;

/**
 * @brief Detect document corners on GPU in the page image and save document detection quality into the page
 * @param corners document corners to validate
 * @param width rotated image width
 * @param height rotated image height
 * @return true if corners are valid.
 */
+ (BOOL) validateDocumentCorners:(const PxPoint[_Nonnull 4])corners width:(int)width height:(int)height;

/**
 * @brief Try to regulate document corners compliance to order UL-UR-BL-BR
 * @param corners document corners to validate
 * @return true if corners are valid and regulation was successful.
 */
+ (BOOL) regulateDocumentCorners:(PxPoint[_Nonnull 4])corners;

/// Document fullness threshold
@property (assign, readwrite, nonatomic) float fullnesThreshold;

/// Document distoration threshold
@property (assign, readwrite, nonatomic) float distortionThreshold;

/// Computed document fullness rate during checking
@property (assign, readonly, nonatomic) float checkedFullnessRate;

/// Computed document distortion rate during checking
@property (assign, readonly, nonatomic) float checkedDistortionRate;

/// TRUE is document fullness check passed
@property (assign, readonly, nonatomic) BOOL isFullnessChecked;

/// TRUE is document distorion check passed
@property (assign, readonly, nonatomic) BOOL isDistortionChecked;

/**
 * @brief Check document fullness and distortion
 * @param corners document corners to check
 * @param width image width
 * @param height image height
 */
- (void) checkGeometry:(const PxPoint[_Nonnull 4])corners width:(int)width height:(int)height;

@end
