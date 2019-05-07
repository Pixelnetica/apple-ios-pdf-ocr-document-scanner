//
//  CircularProgressView.m
//  SharpScan
//
//  Created by Andrey Anisimov on 15.02.16.
//
//

#import "CircularProgressView.h"

//@implementation CircularProgressView
#define HMPROGRESS_VIEW_LINE_WIDTH 10

@implementation CircularProgressView
{
    CAShapeLayer *_circlePathLayer;
    CABasicAnimation *_pathAnimation;
}
-(CircularProgressView *)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.backgroundColor = [UIColor clearColor];
    _circlePathLayer = [[CAShapeLayer alloc] init];
    CGFloat circleRadius = self.frame.size.width/2-HMPROGRESS_VIEW_LINE_WIDTH;
    _circlePathLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.width);
    _circlePathLayer.lineWidth = HMPROGRESS_VIEW_LINE_WIDTH;
    _circlePathLayer.fillColor = [UIColor clearColor].CGColor;
    _circlePathLayer.strokeColor = [UIColor colorWithRed:255.0/255.0 green:204.0/255.0 blue:0 alpha:1.0 ].CGColor;
    CGRect circleFrame = CGRectMake(0, 0, 2*circleRadius, 2*circleRadius);
    circleFrame.origin.x = CGRectGetMidX(_circlePathLayer.bounds) - CGRectGetMidX(circleFrame);
    circleFrame.origin.y = CGRectGetMidY(_circlePathLayer.bounds) - CGRectGetMidY(circleFrame);
    CGPoint center = CGPointMake(circleFrame.origin.x+circleRadius, circleFrame.origin.y+circleRadius);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center
                                                        radius:circleRadius
                                                    startAngle:M_PI_2
                                                      endAngle:M_PI_2-0.0001
                                                     clockwise:YES];
    _circlePathLayer.path = path.CGPath;
    [self.layer addSublayer:_circlePathLayer];
    return self;
}

- (void) setupCircleView {
    self.backgroundColor = [UIColor clearColor];
    _circlePathLayer = [[CAShapeLayer alloc] init];
    CGFloat circleRadius = self.frame.size.width/2-HMPROGRESS_VIEW_LINE_WIDTH;
    _circlePathLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.width);
    _circlePathLayer.lineWidth = HMPROGRESS_VIEW_LINE_WIDTH;
    _circlePathLayer.fillColor = [UIColor clearColor].CGColor;
    _circlePathLayer.strokeColor = [UIColor colorWithRed:255.0/255.0 green:204.0/255.0 blue:0 alpha:1.0 ].CGColor;
    CGRect circleFrame = CGRectMake(0, 0, 2*circleRadius, 2*circleRadius);
    circleFrame.origin.x = CGRectGetMidX(_circlePathLayer.bounds) - CGRectGetMidX(circleFrame);
    circleFrame.origin.y = CGRectGetMidY(_circlePathLayer.bounds) - CGRectGetMidY(circleFrame);
    CGPoint center = CGPointMake(circleFrame.origin.x+circleRadius, circleFrame.origin.y+circleRadius);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center
                                                        radius:circleRadius
                                                    startAngle:M_PI_2
                                                      endAngle:M_PI_2-0.0001
                                                     clockwise:YES];
    _circlePathLayer.path = path.CGPath;
    [self.layer addSublayer:_circlePathLayer];
}

-(void)startWithMaxTime:(CGFloat)time
{
    [_circlePathLayer removeAllAnimations];
    _pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    _pathAnimation.duration = time;
    _pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    _pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
    _pathAnimation.delegate = self;
    [_circlePathLayer addAnimation:_pathAnimation forKey:@"strokeEnd"];
}
-(void)stop
{
    [_circlePathLayer removeAllAnimations];
}
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    if (flag)
        [self.delegate CircularProgressViewAnimationFinished];
}
@end



