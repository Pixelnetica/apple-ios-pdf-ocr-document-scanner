//
//  PageEditorController.m
//  PhotoSlider
//
//  Created by Andrey Glushko on 4/7/13.
//  Copyright 2013 Pixelnetica. All rights reserved.
//

#import "PageEditorController.h"
#import "MyImageView.h"


@implementation PageEditorController

@synthesize delegate;
@synthesize image;
@synthesize imageView;
@synthesize processButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


+ (id)createWith:(UIImage *)img points:(CGPoint [4])points
{
    PageEditorController *pageEditor = [[PageEditorController alloc] init];
	pageEditor.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    pageEditor.image = img;
    [pageEditor setPoints:points];
    return pageEditor;
}

- (void)setPoints:(CGPoint [4])points
{
    for (int i = 0; i < 4; i++) {
        pt [i] = points [i];
    }
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    NSLog(@"%@", self.view);
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    imageView.image = self.image;
    [imageView setCorners:pt coordinates:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;;
    self.processButton = nil;
    self.imageView = nil;
    self.image = nil;
}

#pragma mark - Commands

- (IBAction)processAction:(id)sender
{
    // Save corners position to the page..
    CGPoint points [4];
    [imageView getCorners:points coordinates:YES];
    
    if ([delegate respondsToSelector:@selector(pageEditorController: didFinishedEditingPage:)]) {
        [delegate pageEditorController:self didFinishedEditingPage:points];
    }
}

- (IBAction)cancelAction:(id)sender
{
    // Save corners position to the page..
    CGPoint points [4];
    [imageView getCorners:points coordinates:YES];
    
    if ([delegate respondsToSelector:@selector(pageEditorControllerCancel:)]) {
        [delegate pageEditorControllerCancel:self];
    }
}

@end
