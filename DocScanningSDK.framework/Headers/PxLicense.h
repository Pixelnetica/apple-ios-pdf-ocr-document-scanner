/**
 * @file PxLicense.h
 * @brief License information retrieval
 */

#pragma once

#import <Foundation/Foundation.h>

/**
 * @enum PxLicenseStatus
 * @brief License status values
 */
typedef enum {
	/// No license key specifed
	PxLicenseStatus_None = -1,
	/// The license is active
	PxLicenseStatus_Active,
	/// Malformed or corrupt license key
	PxLicenseStatus_Malformed_Key,
	/// The license cannot be used with this application
	PxLicenseStatus_AppID_Mismatch,
	/// The license cannot be used with this platform
	PxLicenseStatus_PlatformID_Mismatch,
	/// The license has expired
	PxLicenseStatus_Expired,
	/// The subscription has expired
	PxLicenseStatus_Subscruption_Expired,
} PxLicenseStatus;

/**
 * @enum PxLicenseFeature
 * @brief License-controlled product features
 */
typedef enum {
	/// Permission to write PNG files
	PxLicenseFeature_PNG				 = 1 << 0,
	/// Permission to write TIFF G4 files
	PxLicenseFeature_TIFF				 = 1 << 1,
	/// Permission to write PDF files
	PxLicenseFeature_PDF				 = 1 << 2,
	/// Permission to use OCR functions
	PxLicenseFeature_OCR				 = 1 << 3,
} PxLicenseFeature;

/**
 * @interface PxLicense
 * @brief Active license initialization and information
 */
@interface PxLicense : NSObject

/**
 * @brief Activates license with the given key
 * @param key license key string. Pass nilto deactivate current license.
 */
+ (PxLicenseStatus) initializeWithKey:(NSString* _Nullable)key;

/// Active license key
+ (NSString* _Nullable) key;

/// Active license information
+ (PxLicense* _Nonnull) info;

/// License initialization status
@property (assign, readonly, nonatomic) PxLicenseStatus status;

/// License target application ID
@property (assign, readonly, nonatomic, nonnull) NSString* appId;

/// License owner name
@property (assign, readonly, nonatomic, nonnull) NSString* clientName;

/// Extra information about the license owner in human-readable form
@property (assign, readonly, nonatomic, nonnull) NSString* clientExtraInfo;

/// UNIX timestamp before which the licence is valid (0xfffffff for unlimited licenses)
@property (assign, readonly, nonatomic) unsigned validTs;

/// UNIX timestamp before which the subscription is valid (the customer
/// receives updates at no charge)
@property (assign, readonly, nonatomic) unsigned validSubscriptionTs;

/// Mask of features allowed by this license (0xfffffff for full-featured licenses)
@property (assign, readonly, nonatomic) unsigned features;

@end
