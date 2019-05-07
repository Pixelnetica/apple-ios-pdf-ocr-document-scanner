//
//  MyImageView.m
//  PhotoSlider
//
//  Created by Andrey Glushko on 4/7/13.
//  Copyright 2013 Pixelnetica. All rights reserved.
//

#import "MyImageView.h"
#import "UIImage+Orientation.h"


#define kCorner1Tag             201
#define kCorner2Tag             202
#define kCorner3Tag             203
#define kCorner4Tag             204

#define kPageEditorNavBar      100
#define kPageEditorToolBar     101
#define kPageEditorProfileBar  102


static const CGFloat GAP = 20;
static const CGFloat SCALE = 2.0f;

#pragma mark-
#pragma mark Class CornerView

@implementation CornerView

@synthesize centerOffset, pushCenter, cornerType, selected = isSelected;

- (id)initWithImage:(UIImage *)normal andSelected:(UIImage *)selected
{
    self = [super initWithImage:normal];
    if (self) {
        // Initialization code
        imageNormal = normal;
        
        imageSelected = selected;
    }
    return self;
    
}


- (void)setSelected:(BOOL)selected
{
    if (selected != isSelected) {
        isSelected = selected;
        self.image = (!isSelected) ? imageNormal : imageSelected;
        [self setNeedsDisplay];
    }
}

@end


#pragma mark-
#pragma mark Class MyImageView

@implementation MyImageView

@synthesize image;

- (CornerView *)createCorner:(CornerType)type
                      normal:(NSString *)normal
                    selected:(NSString *)selected
{
    CornerView *cv = [[CornerView alloc] initWithImage:[UIImage imageNamed:normal]
                                           andSelected:[UIImage imageNamed:selected]];
    corner [type] = cv;
    cv.cornerType = type;
    [self addSubview:cv];
    
    return cv;
}

- (void)initInternal
{
    self.userInteractionEnabled = YES;
    //self.contentMode = UIViewContentModeRedraw;
    self.backgroundColor = [UIColor blackColor];
    self.clipsToBounds = YES;
    
    [self createCorner:CornerTypeLeftTop normal:@"ltn.png" selected:@"lta.png"];
    [self createCorner:CornerTypeRightTop normal:@"rtn.png" selected:@"rta.png"];
    [self createCorner:CornerTypeLeftBottom normal:@"lbn.png" selected:@"lba.png"];
    [self createCorner:CornerTypeRightBottom normal:@"rbn.png" selected:@"rba.png"];
    
    corner[CornerTypeLeftTop].centerOffset = CGPointMake(2., 2.);
    corner[CornerTypeRightTop].centerOffset = CGPointMake(-1., 2.);
    corner[CornerTypeLeftBottom].centerOffset = CGPointMake(2., -1.);
    corner[CornerTypeRightBottom].centerOffset = CGPointMake(-1., -1.);
    
    corner[CornerTypeLeftTop].tag = kCorner1Tag;
    corner[CornerTypeRightTop].tag = kCorner2Tag;
    corner[CornerTypeLeftBottom].tag = kCorner3Tag;
    corner[CornerTypeRightBottom].tag = kCorner4Tag;
    
    minScale = 1.0;
    scale = 1.0;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initInternal];
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self initInternal];
}

- (void)dealloc
{
    if (layerBottom) {
        CGLayerRelease(layerBottom);
    }
}

#pragma mark -
#pragma mark Configure MyImageView to display new image

- (void)calculateMinScale
{
    minScale = 1.0;
        
    if (image)
    {
        CGSize imageSize = [image size];
        CGRect bounds = self.bounds;
    
        // Calculate and set the zoom scale values
        CGFloat xscale = (bounds.size.width  - GAP*2.) / imageSize.width;
        CGFloat yscale = (bounds.size.height - GAP*2.) / imageSize.height;
    
        minScale = MIN(xscale, yscale);
        //minScale = 0.2;
    }
}

- (void)setImage:(UIImage *)aImage
{
	image = [aImage imageByNormalizingOrientation];

    if (layerBottom) {
        CGLayerRelease(layerBottom);
        layerBottom = NULL;
    }
    
    [self calculateMinScale];
    scale = minScale;
    
    [self setDefaultPositionOfCorners];
}

- (CGRect)wholeImageRectInView
{
    // Calculate destination rectangle for drawing whole image
    CGSize imageSize = [self.image size];
    CGRect imageRect = CGRectMake(0, 0, scale*imageSize.width, scale*imageSize.height);
    //CGRect imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    
    if (imageRect.size.width < self.bounds.size.width) {
        imageRect.origin.x = (self.bounds.size.width - imageRect.size.width)/2.;
        
    }
    if (imageRect.size.height < self.bounds.size.height) {
        imageRect.origin.y = (self.bounds.size.height - imageRect.size.height)/2.;
        
    }
    
    return imageRect;
}

- (void)setDefaultPositionOfCorners
{
    CGPoint point [4];
    CGRect rcBounds;
    
    if (!image) {
        rcBounds = CGRectInset(self.bounds, GAP, GAP);
    } else {
        rcBounds = [self wholeImageRectInView];
    }
    
    point[0] = rcBounds.origin;
    point[1] = CGPointMake(rcBounds.origin.x + rcBounds.size.width, rcBounds.origin.y);
    point[2] = CGPointMake(rcBounds.origin.x, rcBounds.origin.y + rcBounds.size.height);
    point[3] = CGPointMake(rcBounds.origin.x + rcBounds.size.width, rcBounds.origin.y + rcBounds.size.height);
    

    
    [self setCorners:point coordinates:NO];
}

- (CornerView *)nearestCornerView:(CGPoint)point
{
    static const CGFloat distToSelect = 100. * 100.;
    
    CornerView *nearest = nil;
    CGFloat distMin = CGFLOAT_MAX;
    
    for (int i = 0; i < 4; i++) {
        CGPoint pt = corner[i].center;
        CGFloat dist = (pt.x - point.x)*(pt.x - point.x) + (pt.y - point.y)*(pt.y - point.y);
        if (dist < distMin) {
            distMin = dist;
            nearest = corner[i];
        }
    }
    
    return (distMin >= distToSelect) ? nil : nearest;
}

- (void)getCorners:(CGPoint[4])point coordinates:(BOOL)inImage;
{
    point [0] = corner [CornerTypeLeftTop].center;
    point [1] = corner [CornerTypeRightTop].center;
    point [2] = corner [CornerTypeLeftBottom].center;
    point [3] = corner [CornerTypeRightBottom].center;
    
    point [0].x -= corner[CornerTypeLeftTop].centerOffset.x;
    point [0].y -= corner[CornerTypeLeftTop].centerOffset.y;
    
    point [1].x -= corner[CornerTypeRightTop].centerOffset.x;
    point [1].y -= corner[CornerTypeRightTop].centerOffset.y;
    
    point [2].x -= corner[CornerTypeLeftBottom].centerOffset.x;
    point [2].y -= corner[CornerTypeLeftBottom].centerOffset.y;
    
    point [3].x -= corner[CornerTypeRightBottom].centerOffset.x;
    point [3].y -= corner[CornerTypeRightBottom].centerOffset.y;
    
    if (inImage) {
        point[0] = [self convertFromViewToImagePt:point[0]];
        point[1] = [self convertFromViewToImagePt:point[1]];
        point[2] = [self convertFromViewToImagePt:point[2]];
        point[3] = [self convertFromViewToImagePt:point[3]];
    }
}

- (void)setCorners:(const CGPoint[4])pt coordinates:(BOOL)inImage
{
    CGPoint point [4];

    point [0] = pt [0];
    point [1] = pt [1];
    point [2] = pt [2];
    point [3] = pt [3];
    
    if (inImage) {
        point[0] = [self convertFromImageToViewPt:point[0]];
        point[1] = [self convertFromImageToViewPt:point[1]];
        point[2] = [self convertFromImageToViewPt:point[2]];
        point[3] = [self convertFromImageToViewPt:point[3]];        
    }
    

    
    point [0].x += corner[CornerTypeLeftTop].centerOffset.x;
    point [0].y += corner[CornerTypeLeftTop].centerOffset.y;
    
    point [1].x += corner[CornerTypeRightTop].centerOffset.x;
    point [1].y += corner[CornerTypeRightTop].centerOffset.y;
    
    point [2].x += corner[CornerTypeLeftBottom].centerOffset.x;
    point [2].y += corner[CornerTypeLeftBottom].centerOffset.y;
    
    point [3].x += corner[CornerTypeRightBottom].centerOffset.x;
    point [3].y += corner[CornerTypeRightBottom].centerOffset.y;
    
    corner[CornerTypeLeftTop].center = point [0];
    corner[CornerTypeRightTop].center = point [1];
    corner[CornerTypeLeftBottom].center = point [2];
    corner[CornerTypeRightBottom].center = point [3];
    
    [self setNeedsDisplay];
}

- (CGPoint)getCornerPoint:(CornerView *)aCorner
{
    CGPoint point;
    point = aCorner.center;
    point.x -= corner[CornerTypeLeftTop].centerOffset.x;
    point.y -= corner[CornerTypeLeftTop].centerOffset.y;
    return point;
}

- (BOOL)correctCornerPosition:(CGPoint *)point corner:(CornerView *)aCorner
{
    CGRect rect = [self wholeImageRectInView];
    
    point->x -= aCorner.centerOffset.x;
    point->y -= aCorner.centerOffset.y;
    
    point->x = MAX(rect.origin.x, MIN(point->x, rect.origin.x + rect.size.width));
    point->y = MAX(rect.origin.y, MIN(point->y, rect.origin.y + rect.size.height));
    
    *point = [self convertFromViewToImagePt:*point];
    
    {
        CGPoint points [4];
        [self getCorners:points coordinates:YES];
        for (int i = 0; i < 4; i++)
            if (aCorner == corner[i]) {
                points [i] = *point;
                break;
            }
    }
    
    *point = [self convertFromImageToViewPt:*point];
    
    point->x += aCorner.centerOffset.x;
    point->y += aCorner.centerOffset.y;
    
    return YES;
}

// Calculate the offset for a scaled image to save the selected image point
// at the same place in the window
- (CGPoint)calculateTranslate:(CGPoint)point forScale:(CGFloat)aScale
{
    CGPoint offset;
    CGPoint ptCentre = self.center;
    CGRect toolbarHeight = [self.superview viewWithTag:kPageEditorNavBar].bounds;
    
    offset.x = (point.x - ptCentre.x) * aScale + ptCentre.x;
    offset.y = (point.y - ptCentre.y) * aScale + ptCentre.y;
    
    offset.x = point.x - offset.x;
    offset.y = point.y - offset.y - toolbarHeight.size.height;

    return offset;
}

- (CGPoint)convertFromViewToImagePt:(CGPoint)point
{
    CGRect rectWhole = [self wholeImageRectInView];
    
    CGPoint offset;
    
    offset.x = (self.bounds.size.width  - rectWhole.size.width ) / 2.;
    offset.y = (self.bounds.size.height - rectWhole.size.height) / 2.;
    
    // Convert to Image coordinates
    
    point.x = (point.x - offset.x) / scale;
    point.y = (point.y - offset.y) / scale;
    
    return point;
}

- (CGPoint)convertFromImageToViewPt:(CGPoint)pt
{
    CGRect rectWhole = [self wholeImageRectInView];

    CGPoint offset;
    
    offset.x = (self.bounds.size.width  - rectWhole.size.width ) / 2.;
    offset.y = (self.bounds.size.height - rectWhole.size.height) / 2.;
    
    CGPoint point;
    
    point.x = pt.x * scale + offset.x;
    point.y = pt.y * scale + offset.y;
    
    return point;
}

- (CGLayerRef)createBottomLayer:(CGContextRef)context image:(UIImage *)anImage
{
    CGLayerRef layer = CGLayerCreateWithContext (context, self.bounds.size, NULL);
    CGContextRef layerContext = CGLayerGetContext (layer);
        
    CGContextSetFillColorWithColor (layerContext, self.backgroundColor.CGColor);
    CGContextFillRect (layerContext, self.bounds);

	CGAffineTransform transform = CGAffineTransformMake (1, 0, 0, -1, 0, self.bounds.size.height);
    CGContextConcatCTM (layerContext, transform);
    
    CGContextDrawImage (layerContext, [self wholeImageRectInView], anImage.CGImage);

    return layer;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
  
    //-----------------------------------------------------------
    // Draw bottom layer containing image preview
    //-----------------------------------------------------------
    if (!layerBottom) {
        layerBottom = [self createBottomLayer:context image:image];
    }
    if (layerBottom) {
        CGContextDrawLayerAtPoint (context, CGPointMake(0, 0), layerBottom);
    }
    
    //-----------------------------------------------------------
    // Draw transparency layer containing edges around page area
    //-----------------------------------------------------------
    {
        CGPoint point [4];
        [self getCorners:point coordinates:NO];

        // Preserve the current drawing state
        CGContextSaveGState(context);
       
        CGContextBeginTransparencyLayer (context, NULL);
        
        CGContextSetLineWidth(context, 1.0);
        CGContextSetRGBStrokeColor(context, 0.0, 0.0, 1.0, 1.0);
       
        //-----------------------------------------------------------------
        // Create complex path as intersection of subpath 1 with subpath 2
        //-----------------------------------------------------------------
        
        // Create subpath 1 with the whole image size
        CGContextSetRGBFillColor (context, 0, 0, 0, 0.4);
        CGContextAddRect (context, self.bounds);
        // Create subpath 2 which cuts a page area from the subpath 1
        CGContextMoveToPoint(context, point[0].x, point[0].y);
        CGContextAddLineToPoint(context, point[1].x, point[1].y);
        CGContextAddLineToPoint(context, point[3].x, point[3].y);
        CGContextAddLineToPoint(context, point[2].x, point[2].y);
        CGContextAddLineToPoint(context, point[0].x, point[0].y);
        CGContextEOFillPath(context);

        //-----------------------------------------------------------------
        // Create a new path which draws edges around page area
        //-----------------------------------------------------------------
        
        // Draw edge around page
        CGContextSetRGBFillColor (context, 0, 0, 1, 1);
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, point[0].x, point[0].y);
        CGContextAddLineToPoint(context, point[1].x, point[1].y);
        CGContextAddLineToPoint(context, point[3].x, point[3].y);
        CGContextAddLineToPoint(context, point[2].x, point[2].y);
        CGContextAddLineToPoint(context, point[0].x, point[0].y);
        CGContextStrokePath(context);
              
        CGContextEndTransparencyLayer (context);
        
        // Restore the previous drawing state.
        CGContextRestoreGState(context);
    }
}

- (void)zoomInAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{

}

- (void)animateZoomInAtPoint:(CGPoint)touchPoint
{
#define GROW_ANIMATION_DURATION_SECONDS 0.15

	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:GROW_ANIMATION_DURATION_SECONDS];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(zoomInAnimationDidStop:finished:context:)];
    
    CGPoint translate = [self calculateTranslate:touchPoint forScale:SCALE];
	CGAffineTransform transform = CGAffineTransformMakeTranslation(translate.x, translate.y);
    transform = CGAffineTransformScale(transform, SCALE, SCALE);    
	self.transform = transform;

	[UIView commitAnimations];
}

- (void)zoomOutAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
#define MOVE_ANIMATION_DURATION_SECONDS 0.15
    [self.superview viewWithTag:kPageEditorNavBar].hidden = NO;    
    [self.superview viewWithTag:kPageEditorToolBar].hidden = NO;
}

- (void)animateZoomOutAtPoint
{
#define GROW_ANIMATION_DURATION_SECONDS 0.15
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:GROW_ANIMATION_DURATION_SECONDS];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(zoomOutAnimationDidStop:finished:context:)];    
	self.transform = CGAffineTransformMakeScale(1.f, 1.f);
	[UIView commitAnimations];
}

#pragma mark -
#pragma mark Touch handling

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	CGPoint pt = [[touches anyObject] locationInView:self];
	startLocation = pt;
	[[self superview] bringSubviewToFront:self];
    
    [self.superview viewWithTag:kPageEditorNavBar].hidden = YES;
    [self.superview viewWithTag:kPageEditorToolBar].hidden = YES;
    [self animateZoomInAtPoint:startLocation];
    
    corverDragged = [self nearestCornerView:startLocation];
    if (corverDragged) {
        corverDragged.pushCenter = corverDragged.center;
        corverDragged.selected = YES;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint pt = [[touches anyObject] locationInView:self];
    if (corverDragged) {
        CGFloat dx = pt.x - startLocation.x;
        CGFloat dy = pt.y - startLocation.y;
        CGPoint newcenter = CGPointMake(dx + corverDragged.pushCenter.x, dy + corverDragged.pushCenter.y);
        BOOL isValid = [self correctCornerPosition:&newcenter corner:corverDragged];
        if (isValid) {
            corverDragged.center = newcenter;
        }
        [self setNeedsDisplay];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self animateZoomOutAtPoint];
    if (corverDragged) {
        corverDragged.selected = NO;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
   
}

@end
