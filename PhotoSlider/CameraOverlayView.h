//
//  OverlayView.h
//  Example-ImageSDK-iOS
//
//  Created by Andrey Anisimov on 24.12.15.
//
//

#import <UIKit/UIKit.h>

@interface CameraOverlayView : UIView
/*! Create rect and animate it */
- (void) setCornersTopLeft:(CGPoint) topLeft andTopRight:(CGPoint) topRight andBottomLeft:(CGPoint) bottomLeft andBottomRight:(CGPoint) bottomRight andColor:(UIColor*) color;
/*! Display rect */
- (void) display;
/*! Clear rect */
- (void) clearView;
@end

