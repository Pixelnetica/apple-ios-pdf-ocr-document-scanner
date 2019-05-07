/**
 * @file PxException.h
 */

#pragma once

#import <Foundation/Foundation.h>

/**
 * @interface PxException
 * @brief Exception class to indicate PX programmer errors
 */
@interface PxException : NSException

/**
 * @brief Raises PxException with specifed message (with variable argumuents) and logs message in console
 * @param format message string format
 */
+ (void) raise:(NSString*)format, ...;

/**
 * @brief Raises PxException with specifed message (with variable argumuents) without logging message in console
 * @param format message string format
 */
+ (void) raiseWithoutTrace: (NSString*)format, ...;

@end
