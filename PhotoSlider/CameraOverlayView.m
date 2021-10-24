//
//  OverlayView.m
//  Example-ImageSDK-iOS
//
//  Created by Andrey Anisimov on 24.12.15.
//
//

#import "CameraOverlayView.h"
#import <QuartzCore/QuartzCore.h>

@interface CameraOverlayView()
@property (nonatomic, strong) CAShapeLayer *topLayer;
@property (nonatomic, strong) CAShapeLayer *bottomLayer;
@property (nonatomic, strong) CAShapeLayer *leftLayer;
@property (nonatomic, strong) CAShapeLayer *rightLayer;
@property (nonatomic, assign) CGPathRef savedPath;
@property (nonatomic, assign) BOOL isWasCleared;
@property (nonatomic, strong) UIColor *savedColor;
@property(nonatomic,assign) BOOL clearMode;
@end

@implementation CameraOverlayView //CAShapeLayer *blueCircleLayer
CGPoint pts_[4];


- (void) setCornersTopLeft:(CGPoint) topLeft andTopRight:(CGPoint) topRight andBottomLeft:(CGPoint) bottomLeft andBottomRight:(CGPoint) bottomRight andColor:(UIColor *)color{
    
    [self.topLayer removeFromSuperlayer];
    
    self.savedColor = color;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:topLeft];
    [path addLineToPoint:topRight];
    [path addLineToPoint:bottomRight];
    [path addLineToPoint:bottomLeft];
    [path addLineToPoint:topLeft];
    
    self.topLayer = [CAShapeLayer layer];
    self.topLayer.strokeColor = color.CGColor;
    self.topLayer.fillColor = [UIColor clearColor].CGColor;
    self.topLayer.lineWidth = 4.0;
    [self.layer addSublayer:self.topLayer];
    
    if (!self.isWasCleared) {
        
        CABasicAnimation *moveAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        moveAnimation.duration = 0.3f;
        moveAnimation.fromValue = (id) self.savedPath;
        moveAnimation.toValue = (id) path.CGPath;
        [self.topLayer addAnimation:moveAnimation forKey:@"path"];
        
    }
    self.topLayer.path = path.CGPath;
    self.savedPath = self.topLayer.path;
    self.isWasCleared = NO;
}

- (void) clearView {
    
    CABasicAnimation *moveAnimation = [CABasicAnimation animationWithKeyPath:@"strokeColor"];
    moveAnimation.duration = 0.3f;
    moveAnimation.fromValue = (id) self.savedColor;
    moveAnimation.toValue = (id) [UIColor clearColor].CGColor;
    [self.topLayer addAnimation:moveAnimation forKey:@"strokeColor"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.topLayer removeFromSuperlayer];
        self.isWasCleared = YES;
    });
}

- (void)display
{
    CALayer *layer = self.layer;
    [layer setNeedsDisplay];
    [layer displayIfNeeded];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    UIGraphicsPushContext(context);
    [self internalDrawWithRect:self.bounds];
    UIGraphicsPopContext();
}

/// For compatibility, if something besides our display method asks for draw.
- (void)drawRect:(CGRect)rect
{
    [self internalDrawWithRect:rect];
}

/// Internal drawing method; naming's up to you.
- (void)internalDrawWithRect:(CGRect)rect
{
    // @fillin: draw draw draw
}


@end
