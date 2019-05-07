//
//  SettingsViewController.h
//  Example-ImageSDK-iOS
//
//  Created by Andrey Anisimov on 18.12.15.
//
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController
@property (nonatomic,readwrite,copy) void (^completion)(NSString *imagePath);
@end
