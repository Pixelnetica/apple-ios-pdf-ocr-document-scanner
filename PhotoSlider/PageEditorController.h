//
//  PageEditorController.h
//  PhotoSlider
//
//  Created by Andrey Glushko on 4/7/13.
//  Copyright 2013 Pixelnetica. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PageEditorControllerDelegate.h"

@class MyImageView;

@interface PageEditorController : UIViewController {
@private
    MyImageView *imageView;
    UIBarButtonItem *processButton;
    UIBarButtonItem *profileButton;
    id <PageEditorControllerDelegate> delegate;
    CGPoint pt [4];
}

@property (nonatomic, strong) id <PageEditorControllerDelegate> delegate;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) IBOutlet MyImageView *imageView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *processButton;


+ (id)createWith:(UIImage *)img points:(CGPoint [4])points;

- (void)setPoints:(CGPoint [4])points;

- (IBAction)processAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
