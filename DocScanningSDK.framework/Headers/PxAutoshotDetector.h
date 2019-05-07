/**
 * @file PxAutoShotDetector.h
 */

#pragma once

#import "PxSDKTypes.h"
#import <Foundation/Foundation.h>

/**
 * @interface PxAutoShotDetector
 * @brief Helper class detect when document corners are stable and it is safe to make a shot
 */
@interface PxAutoShotDetector : NSObject;

@property (assign, readwrite, nonatomic) int stableRadius;
@property (assign, readwrite, nonatomic) int stableDelay;
@property (assign, readwrite, nonatomic) int stableCount;

/**
 * @brief Append next document corners to detect stable state
 * @param points array of points to add
 * @param count point array length
 */
- (BOOL) addDetectedPoints:(const PxPoint[_Nonnull])points :(int)count;

/**
 * @brief Reset to the initial state
 */
- (void) reset;

@end
