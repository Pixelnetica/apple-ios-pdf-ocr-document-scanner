/**
 * @file PxMetaImage.h
 * @brief Image with metadata support
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * @enum PxMetaImage_DevicePlatform
 * @brief Image device platform
 */
typedef enum {
	PxMetaImage_DevicePlatform_Unknown,
	PxMetaImage_DevicePlatform_iPhone4,
	PxMetaImage_DevicePlatform_iPhone4S,
	PxMetaImage_DevicePlatform_iPhone5,
	PxMetaImage_DevicePlatform_iPad,
	PxMetaImage_DevicePlatform_Android,
} PxMetaImage_DevicePlatform;

/**
 * @enum PxMetaImage_ColorHint
 * @brief Image color hint
 */
typedef enum {
	/// No hint (use default behavior)
	PxMetaImage_ColorHint_Default,
	/// 1-bit image
	PxMetaImage_ColorHint_1Bit,
	/// Monochrome image
	PxMetaImage_ColorHint_Mono,
	/// RGBA image
	PxMetaImage_ColorHint_RGBA,
} PxMetaImage_ColorHint;

/**
 * @enum PxMetaImage_Orientation
 * @brief Image orientation. Matches the EXIF orientation.
 */
typedef enum {
	/**
	 * Unknown
	 */
	PxMetaImage_Orientation_Unknown,

	/**
	 * 0th Row on TOP, 0th Column on LEFT SIDE
	 *
	 * 888888
	 * 88
	 * 8888
	 * 88
	 * 88
	 */
	PxMetaImage_Orientation_Normal,

	/**
	 * 0th Row on TOP, 0th Column on RIGHT SIDE
	 *
	 * 888888
	 *     88
	 *   8888
	 *     88
	 *     88
	 */
	PxMetaImage_Orientation_FlipHorizontal,

	/**
	 * 0th Row on BOTTOM, 0th Column on RIGHT SIDE
	 *
	 *     88
	 *     88
	 *   8888
	 *     88
	 * 888888
	 */
	PxMetaImage_Orientation_Rotate180,

	/**
	 * 0th Row BOTTOM, 0th Column on LEFT SIDE
	 *
	 * 88
	 * 88
	 * 8888
	 * 88
	 * 888888
	 */
	PxMetaImage_Orientation_FlipVertical,

	/**
	 * 0th Row on LEFT SIDE, 0th Column on TOP
	 *
	 *  8888888888
	 *  88  88
	 *  88
	 */
	PxMetaImage_Orientation_Transpose,

	/**
	 * 0th Row RIGHT SIDE, 0th Column on TOP
	 *
	 * 88
	 * 88  88
	 * 8888888888
	 */
	PxMetaImage_Orientation_Rotate90,

	/**
	 * 0th Row on RIGHT SIDE, 0th Column on BOTTOM
	 *
	 *         88
	 *     88  88
	 * 8888888888
	 */
	PxMetaImage_Orientation_Transverse,

	/**
	 * 0th Row on LEFT SIDE, 0th Column on BOTTOM
	 *
	 * 8888888888
	 *     88  88
	 *         88
	 */
	PxMetaImage_Orientation_Rotate270,
} PxMetaImage_Orientation;

/**
 * @enum PxMetaImage_FlashStatus
 * @brief Image flash usage status
 */
typedef enum {
	/// Value unknown
	PxMetaImage_FlashStatus_Unknown,
	/// Image was taken without flash
	PxMetaImage_FlashStatus_NotFired,
	/// Image was taken with flash
	PxMetaImage_FlashStatus_Fired,
} PxMetaImage_FlashStatus;

/**
 * @@interface PxMetaImage
 * @brief Bitmap with metadata (image orientation, flash status, etc)
 */
@interface PxMetaImage : NSObject

/**
 * @brief Creates {@link #PxMetaImage} from image. Attempts to retrieve metadata information
 *        from the image specifed.
 * @param image input image
 * @return Created object.
 */
+ (PxMetaImage* _Nonnull) new:(UIImage* _Nullable)image;

/**
 * @brief Creates {@link #PxMetaImage} from image and its associated metadata
 * @param image input image
 * @param metadata dictionary with metadata values
 * @return Created object.
 */
+ (PxMetaImage* _Nonnull) new:(UIImage* _Nonnull)image withMetadata:(NSDictionary* _Nonnull)metadata;

/**
 * @brief Creates {@link #PxMetaImage} from image and its local file system path
 * @param image input image
 * @param path image path
 * @return Created object.
 */
+ (PxMetaImage* _Nonnull) new:(UIImage* _Nonnull)image withPath:(NSString* _Nonnull)path;

/**
 * @brief Creates {@link #PxMetaImage} from image and its URL
 * @param image input image
 * @param url image URL
 * @return Created object.
 */
+ (PxMetaImage* _Nonnull) new:(UIImage* _Nonnull)image withURL:(NSString* _Nonnull)url;

/// The underlying UIImage
@property (assign, readwrite, nonatomic, nonnull) UIImage* image;
/// Image color hint
@property (assign, readwrite, nonatomic) PxMetaImage_ColorHint colorHint;
/// Image device platform
@property (assign, readwrite, nonatomic) PxMetaImage_DevicePlatform devicePlatform;
/// Image orientation
@property (assign, readwrite, nonatomic) PxMetaImage_Orientation orientation;
/// Image flash usage status
@property (assign, readwrite, nonatomic) PxMetaImage_FlashStatus flashStatus;
/// Image ISO speed ratings
@property (assign, readwrite, nonatomic) unsigned short isoSpeedRatings;
/// YES if image has strong shadows
@property (assign, readwrite, nonatomic) BOOL hasStrongShadows;
/// Image page number
@property (assign, readwrite, nonatomic) unsigned int pageNumber;

@end
