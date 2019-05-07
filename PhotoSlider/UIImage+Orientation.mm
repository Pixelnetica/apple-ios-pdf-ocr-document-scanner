/**
 * @file: UIImage+Orientation.m
 */

#import "UIImage+Orientation.h"

@implementation UIImage( Orientation )

- (UIImage*)imageByNormalizingOrientation
{
	if( self.imageOrientation == UIImageOrientationUp )
		return self;

	CGSize size = self.size;

	UIGraphicsBeginImageContextWithOptions( size, NO, self.scale );

	[self drawInRect:(CGRect){{0, 0}, size}];

	UIImage* normalizedImage = UIGraphicsGetImageFromCurrentImageContext();

	UIGraphicsEndImageContext();

	return normalizedImage;
}

@end
