/**
 * @file PxImageWriter.h
 * @brief Image writer support
 */

#pragma once

#import "PxMetaImage.h"

/**
 * @enum PxImageWriter_Type
 * @brief Image writer type
 */
typedef enum {
	/// JPEG format
	PxImageWriter_Type_JPEG,
	/// PNG format (basic)
	PxImageWriter_Type_PNG,
	/// PNG format with more configuration options
	PxImageWriter_Type_PNG_EXT,
	/// TIFF format
	PxImageWriter_Type_TIFF,
	/// PDF format
	PxImageWriter_Type_PDF,
} PxImageWriter_Type;

/**
 * @enum PxImageWriter_Cfg
 * @brief Image writer configuration key
 */
typedef enum {
	/**
	 * @brief Compression quality from 0 to 100
	 *
	 * A compression (quality) float value for JPEG/PNG. Integer value from 1 to 100.
	 * Must be set before call PxImageWriter::write method.
	 */
	PxImageWriter_Cfg_COMPRESSION = 1,

	/**
	 * @brief PDF page paper format (A4, A5, receipt, etc)
	 *
	 * Page size preset for PRF, such an A4, Letter etc. PxImageWriter_PaperFormat value.
	 * NOTE: by specifying {@link #PxImageWriter_Cfg_PAGE_WIDTH} or {@link #PxImageWriter_Cfg_PAGE_HEIGHT}
	 * you can override one or both paper dimensions.
	 */
	PxImageWriter_Cfg_PAGE_PAPER,

	/**
	 * @brief PDF page width/height units (mm, inches, etc)
	 *
	 * Number of units for page dimensions. PxImageWriter_PaperFormat value. Can be Millimeters or Inches.
	 */
	PxImageWriter_Cfg_PAGE_UNITS,

	/**
	 * @brief PDF page width
	 *
	 * A page width for PDFs. Float value in mm or {@link #PX_IMAGEWRITER_PAGE_EXTENSIBLE} to make page proper width.
	 */
	PxImageWriter_Cfg_PAGE_WIDTH,

	/**
	 * @brief PDF page height
	 *
	 * A page height for PDFs. Float value in mm or {@link #PX_IMAGEWRITER_PAGE_EXTENSIBLE} to make page proper height.
	 */
	PxImageWriter_Cfg_PAGE_HEIGHT,

	/**
	 * @brief PDF footer text
	 */
	PxImageWriter_Cfg_FOOTER_TEXT,

	/**
	 * @brief PDF footer URL
	 */
	PxImageWriter_Cfg_FOOTER_URL,

	/**
	 * @brief PDF footer height
	 */
	PxImageWriter_Cfg_FOOTER_HEIGHT
} PxImageWriter_Cfg;

/// An "infinite" value for page dimensions. Can be used to calculate page dimension related image.
/// Both {@link #PxImageWriter_Cfg_PAGE_WIDTH} and {@link #PxImageWriter_Cfg_PAGE_HEIGHT} cannot be {@link #PX_IMAGEWRITER_PAGE_EXTENSIBLE}.
#define PX_IMAGEWRITER_PAGE_EXTENSIBLE -1.0f

/**
 * @enum PxImageWriter_PaperFormat
 * @brief Paper format for {@link #PxImageWriter_Cfg_PAGE_PAPER}
 */
typedef enum {
	PxImageWriter_PaperFormat_Terminator = -1,
	PxImageWriter_PaperFormat_Unknown = 0,
	PxImageWriter_PaperFormat_A4,
	PxImageWriter_PaperFormat_A5,
	PxImageWriter_PaperFormat_A6,
	PxImageWriter_PaperFormat_HalfLetter,
	PxImageWriter_PaperFormat_Letter,
	PxImageWriter_PaperFormat_Legal,
	PxImageWriter_PaperFormat_JuniorLegal,
	PxImageWriter_PaperFormat_Leger,
	PxImageWriter_PaperFormat_BusinessCard,
	PxImageWriter_PaperFormat_BusinessCard2,
	PxImageWriter_PaperFormat_ReceiptMobile,
	PxImageWriter_PaperFormat_ReceiptStation,
	PxImageWriter_PaperFormat_ReceiptKitchen,
} PxImageWriter_PaperFormat;

/**
 * @enum PxImageWriter_PaperUnits
 * @brief Paper unit for {@link #PxImageWriter_Cfg_PAGE_UNITS}
 */
typedef enum {
	PxImageWriter_PaperUnits_Millimeters,
	PxImageWriter_PaperUnits_Inches,
	PxImageWriter_PaperUnits_Dpi72,
} PxImageWriter_PaperUnits;

/**
 * @enum PxImageWriter_CfgResult
 * @brief Image writer configuration result
 */
typedef enum {
	/// Configuration option is not supported
	PxImageWriter_CfgResult_Unknown = -1,
	/// Configuration failed e.g. due to an incorrect value
	PxImageWriter_CfgResult_Failed,
	/// Configuration succeeded
	PxImageWriter_CfgResult_Ok,
} PxImageWriter_CfgResult;

/**
 * @enum PxImageWriter_FileType
 * @brief Image writer file type for PxImageWriter::writeFile:::
 */
typedef enum {
	/// JPEG file format
	PxImageWriter_FileType_JPEG,
	/// PNG file format
	PxImageWriter_FileType_PNG,
} PxImageWriter_FileType;

/**
 * @protocol PxImageWriter
 * @brief Writes {@link PxMetaImage} in different formats
 */
@interface PxImageWriter : NSObject

/**
 * @brief Creates {@link #PxImageWriter} of the specifed type
 * @param type requested image writer type
 * @return Created object.
 */
+ (PxImageWriter*) newWithType:(PxImageWriter_Type)type;

/**
 * @brief Start to write a new picture sequence
 * @param fileName path to file
 * @return YES on success, NO otherwise.
 */
- (BOOL) open:(NSString*)fileName;

/**
 * @brief Change configuration option with integer value
 * @param key configuration key
 * @param value configuration value
 * @return The result of the operation.
 */
- (PxImageWriter_CfgResult) configure:(PxImageWriter_Cfg)key withInt:(int)value;

/**
 * @brief Change configuration option with float value
 * @param key configuration key
 * @param value configuration value
 * @return The result of the operation.
 */
- (PxImageWriter_CfgResult) configure:(PxImageWriter_Cfg)key withFloat:(float)value;

/**
 * @brief Change configuration option with string value
 * @param key configuration key
 * @param value configuration value
 * @return The result of the operation.
 */
- (PxImageWriter_CfgResult) configure:(PxImageWriter_Cfg)key withString:(NSString*)value;

/**
 * @brief Write an image to the current sequence
 * @param image {@link PxMetaImage} to write
 * @return path to saved image or nil on error. File name may be different from one passed to PxImageWriter::open:.
 * @throws PxException if feature is not enabled by the license
 */
- (NSString*) write:(PxMetaImage*)image;

/**
 * @brief Write to the specified file. Currently supported for PDFs only.
 * @param imageFile file to write
 * @param imageType file type
 * @param orientation EXIF orientation value
 * @return same as PxImageWriter::write:
 * @throws PxException if feature is not enabled by the license
 */
- (NSString*) writeFile:(NSString*)imageFile :(PxImageWriter_FileType)imageType :(PxMetaImage_Orientation)orientation;

/**
 * @brief Close current sequence
 * @return YES on success, NO otherwise.
 */
- (BOOL) close;

@end

