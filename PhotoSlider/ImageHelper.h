//
//  ImageHelper.h
//
//  Created by Andrey Glushko on 4/7/13.
//  Copyright 2013 Pixelnetica. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface ImageHelper : NSObject

// Create a new UIImage as a copy of sourceImage applying UIImageOrientation flag
+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;

@end
