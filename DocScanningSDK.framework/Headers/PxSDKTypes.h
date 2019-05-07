/**
 * @file PxSDKTypes.h
 * @brief SDK basic types
 */

#pragma once

#import <CoreGraphics/CoreGraphics.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @typedef PxPoint
 * @brief Describes a 2D point with integer coordinates
 */
typedef struct {
	int x;
	int y;
} PxPoint;

/**
 * @brief Converts PxPoint to CGPoint
 */
CGPoint PxToCGPoint( PxPoint pt );

/**
 * @brief Converts CGPoint to PxPoint
 */
PxPoint PxFromCGPoint( CGPoint pt );

/**
 * @brief Converts PxPoint rectangle to CGPoint rectangle
 */
void PxToCGPointRect( const PxPoint inPts[4], CGPoint outPts[4] );

/**
 * @brief Converts CGPoint rectangle to PxPoint rectangle
 */
void PxFromCGPointRect( const CGPoint inPts[4], PxPoint outPts[4] );

/**
 * @typedef PxSize
 * @brief Describes a 2D size with integer coordinates
 */
typedef struct {
	unsigned int x;
	unsigned int y;
} PxSize;

/**
 * @brief Converts PxSize to CGSize
 */
CGSize PxToCGSize( PxSize size );

/**
 * @brief Converts CGSize to PxSize
 */
PxSize PxFromCGSize( CGSize size );

/**
 * @typedef PxDocCorners
 * @brief Document detection parameters and output for PxSDK::detectDocumentCorners:docCorners:
 */
typedef struct {
	/// If true then smart crop mode is activated
	bool isSmartCropMode;
	/// Upper-left point of document
	PxPoint ptUL;
	/// Upper-right point of document
	PxPoint ptUR;
	/// Bottom-left point of document
	PxPoint ptBL;
	/// Bottom-right point of document
	PxPoint ptBR;
} PxDocCorners;

#ifdef __cplusplus
}
#endif
