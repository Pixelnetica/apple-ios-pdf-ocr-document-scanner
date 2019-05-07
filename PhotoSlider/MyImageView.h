//
//  MyImageView.h
//  PhotoSlider
//
//  Created by Andrey Glushko on 4/7/13.
//  Copyright 2013 Pixelnetica. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
    CornerTypeLeftTop,
    CornerTypeRightTop,
    CornerTypeLeftBottom,
    CornerTypeRightBottom
} CornerType;

@interface CornerView : UIImageView
{
    CGPoint centerOffset;
    CGPoint pushCenter;
    CornerType cornerType;
    BOOL isSelected;
    UIImage *imageNormal;
    UIImage *imageSelected;
}

@property (nonatomic, assign) CGPoint centerOffset;
@property (nonatomic, assign) CGPoint pushCenter;
@property (nonatomic, assign) CornerType cornerType;
@property (nonatomic, assign) BOOL selected;

- (id)initWithImage:(UIImage *)normal andSelected:(UIImage *)selected;

@end

#pragma mark -

@interface MyImageView : UIView
{
    UIImage *image;
    CGLayerRef layerBottom; // contains image preview
    CGFloat minScale;
    CGFloat scale;
    
    CGPoint startLocation;
    
    CornerView *corner[4];
    CornerView *corverDragged;
}

@property (nonatomic, strong) UIImage *image;

- (id)initWithFrame:(CGRect)frame;

- (void)getCorners:(CGPoint[4])points coordinates:(BOOL)inImage;
- (void)setCorners:(const CGPoint[4])points coordinates:(BOOL)inImage;

- (void)setDefaultPositionOfCorners;

- (CGRect)wholeImageRectInView;
- (CornerView *)nearestCornerView:(CGPoint)point;
- (CGPoint)getCornerPoint:(CornerView *)corner;
- (BOOL)correctCornerPosition:(CGPoint *)point corner:(CornerView *)aCorner;

- (CGPoint)convertFromViewToImagePt:(CGPoint)pt;
- (CGPoint)convertFromImageToViewPt:(CGPoint)pt;

@end
