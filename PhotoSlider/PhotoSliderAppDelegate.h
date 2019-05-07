//
//  PhotoSliderAppDelegate.h
//  PhotoSlider
//
//  Created by Andrey Glushko on 4/7/13.
//  Copyright 2013 Pixelnetica. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhotoSliderViewController;

@interface PhotoSliderAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, strong) IBOutlet UIWindow *window;

@property (nonatomic, strong) IBOutlet PhotoSliderViewController *viewController;

@end
