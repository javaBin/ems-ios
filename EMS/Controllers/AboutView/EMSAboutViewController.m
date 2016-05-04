//
//  EMSAboutViewController.m
//

#import "EMS-Swift.h"

#import "EMSAboutViewController.h"

@interface EMSAboutViewController ()

@end

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation EMSAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];

    NSURL *docURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"]];

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *version = infoDictionary[@"CFBundleShortVersionString"];
    NSString *build = infoDictionary[@"CFBundleVersion"];

    NSError *error = nil;

    NSString *content = [NSString stringWithContentsOfURL:docURL encoding:NSUTF8StringEncoding error:&error];

    if (!content) {
        DDLogError(@"Unable to get about content %@ %@", error, [error userInfo]);

        return;
    }

    content = [content stringByReplacingOccurrencesOfString:@"VERSION" withString:version];
    content = [content stringByReplacingOccurrencesOfString:@"BUILD" withString:build];

    [self.web loadHTMLString:content baseURL:baseURL];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        // http:// -> safari, rest (file:// etc) opens in webview
        if ([[request.URL scheme] hasPrefix:@"http"]) {
            [[UIApplication sharedApplication] openURL:request.URL];
            return NO;
        }
    }

    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
