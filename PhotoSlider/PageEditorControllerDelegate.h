//
//  PageEditorControllerDelegate.h
//  PhotoSlider
//
//  Created by Andrey Glushko on 4/7/13.
//  Copyright 2013 Pixelnetica. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PageEditorController;

@protocol PageEditorControllerDelegate <NSObject>
@optional

-(void)pageEditorController:(PageEditorController *)editor didFinishedEditingPage:(CGPoint [4])points;
-(void)pageEditorControllerCancel:(PageEditorController *)editor;

@end
