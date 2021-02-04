#import "AboutViewController.h"
#import "WebViewDelegate.h"

@interface AboutViewController ()

@property (nonatomic, weak) IBOutlet UIWebView *webView;

@end

@implementation AboutViewController
{
	WebViewDelegate* webDelegate;
}

- (AboutViewController*) init
{
	webDelegate = [WebViewDelegate new];

	return [self initWithNibName:@"AboutViewController" bundle:nil];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

	NSString* plist_path = [NSBundle.mainBundle pathForResource:@"Info.plist" ofType:nil];

	NSDictionary* dict = [NSFileManager.defaultManager attributesOfItemAtPath:plist_path error:nil];

	NSDate* buildDate = (NSDate*)[dict objectForKey:@"NSFileCreationDate"];

	NSDateComponents* components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:buildDate];

	int bulidYear = (int)components.year;

	dict = [[NSBundle mainBundle] infoDictionary];

//    NSString* version = [dict objectForKey:@"CFBundleShortVersionString"];
    
//    NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString * version = [NSString stringWithFormat:@"%@ (%@)", appVersionString, appBuildString];



	NSString* html =
	[NSString stringWithFormat:
	 @"<!DOCTYPE html>"
	 @"<html>"
	 @"<head>"
	 @"<style>"
	 @"*{"
	 @"overflow:hidden;"
	 @"}"
	 @"body{"
	 @"line-height:1;"
	 @"text-align:center;"
	 @"font-family: sans-serif;"
	 @"}"
	 @"div{"
	 @"background-color:rgb(235,235,235);"
//	 @"height:100% !important;"
	 @"padding:0.3em;"
	 @"border-radius:1em;"
	 @"-webkit-border-radius:1em;"
	 @"}"
	 @"p{"
	 @"margin-top:0.8em !important;"
	 @"margin-bottom:0 !important;"
	 @"}"
	 @"</style>"
	 @"</head>"
	 @"<body>"
	 @"<div>"
	 @"<p>Pixelnetica Document Scanning SDK"
	 @"<p>Version %@"
	 @"<p>For more information, visit"
	 @"<p><a target=\"_blank\" href=\"https://www.pixelnetica.com/products/document-scanning-sdk/document-scanner-sdk.html?utm_source=EasyScan&utm_medium=app-ios&utm_campaign=scr-about&utm_content=dssdk-overview\">Document Scanning SDK page</a>"
	 @"<p>© Pixelnetica %d"
	 @"<p>"
	 @"</div>"
	 @"</body>"
	 @"</html>",
	 version,
	 bulidYear
	 ];

	UIWebView* webView = self.webView;

	[webView loadHTMLString:html baseURL:nil];

	webView.delegate = webDelegate;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) closeView:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
