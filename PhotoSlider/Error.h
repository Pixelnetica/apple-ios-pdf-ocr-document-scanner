//
//  Error.h
//  Example-ImageSDK-iOS
//

#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Error : NSObject

+ (void) Alert:(UIViewController*)view_ctrl title:(NSString*)title message:(NSString*)message, ...;

@end
