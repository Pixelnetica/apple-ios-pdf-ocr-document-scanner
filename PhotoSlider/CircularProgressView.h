//
//  CircularProgressView.h
//  SharpScan
//
//  Created by Andrey Anisimov on 15.07.16.
//
//

#import <UIKit/UIKit.h>

@protocol CircularProgressViewProtocol;

@interface CircularProgressView : UIView
@property(nonatomic, weak) id<CircularProgressViewProtocol> delegate;
/** starts animation from 0
 @param time to max time */
-(void)startWithMaxTime:(CGFloat)time;
/** stops animation and returns progress bar to 100% */
-(void)stop;
- (void) setupCircleView;
@end
/** delegate protocol for managing callback */
@protocol CircularProgressViewProtocol <NSObject>
-(void)CircularProgressViewAnimationFinished;
@end;
