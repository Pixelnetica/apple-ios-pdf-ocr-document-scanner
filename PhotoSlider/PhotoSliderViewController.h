//
//  PhotoSliderViewController.h
//  PhotoSlider
//
//  Created by Andrey Glushko on 4/7/13.
//  Copyright 2013 Pixelnetica. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PageEditorControllerDelegate.h"

@class PxMetaImage;

@interface PhotoSliderViewController : UIViewController <UINavigationControllerDelegate,
                                                         UIImagePickerControllerDelegate,
														 UIDocumentInteractionControllerDelegate,
                                                         PageEditorControllerDelegate>
@property (readonly) BOOL isModified;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *loadButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *saveButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *settingsButton;
@property (nonatomic, weak) IBOutlet UIButton *rotateLeft;
@property (nonatomic, weak) IBOutlet UIButton *rotateRight;
@property (nonatomic, strong) PxMetaImage* inpImage;
@property (nonatomic, strong) PxMetaImage* outImage;

- (IBAction)loadAction:(id)sender;
- (IBAction)saveAction:(id)sender;

@end
