//
//  WebViewDelegate+WebViewDelegate.h
//  Example-ImageSDK-iOS
//

#import "WebViewDelegate.h"

@implementation WebViewDelegate

- (BOOL) webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
	if( navigationType == UIWebViewNavigationTypeLinkClicked )
	{
		NSURL* url = request.URL;
		if( [[UIApplication sharedApplication] canOpenURL:url] )
			[[UIApplication sharedApplication] openURL:url];
		return NO;
	}

	return YES;
}

@end
