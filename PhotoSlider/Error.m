//
//  Error.m
//  Example-ImageSDK-iOS
//

#import "Error.h"

@implementation Error

+ (void) Alert:(UIViewController*)view_ctrl title:(NSString*)title message:(NSString*)message, ...
{
	va_list vl;
	va_start( vl, message );

	NSString* s = [[NSString alloc] initWithFormat:message arguments:vl];

	va_end( vl );

	NSLog( @"%@", s );

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:s preferredStyle:1];

	UIAlertAction* action = [UIAlertAction actionWithTitle:@"OK" style:0 handler:nil];

	[alert addAction:action];

	[view_ctrl presentViewController:alert animated:YES completion:nil];
}

@end
