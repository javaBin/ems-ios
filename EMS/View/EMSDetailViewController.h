//
//  EMSDetailViewController.h
//

#import <UIKit/UIKit.h>
#import "EMSRetrieverDelegate.h"

#import "Session.h"

@interface EMSDetailViewController : UIViewController <EMSRetrieverDelegate>

@property (nonatomic, strong) Session *session;
@property (nonatomic, strong) IBOutlet UIWebView *webView;

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;

@property (nonatomic, strong) IBOutlet UIButton *button;

@property (nonatomic, strong) NSDictionary *cachedSpeakerBios;

- (IBAction)share:(id)sender;
- (IBAction)toggleFavourite:(id)sender;
- (IBAction)clearImageCache:(id)sender;

@end
