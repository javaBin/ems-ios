//
//  EMSDetailViewController.h
//

#import <UIKit/UIKit.h>
#import "EMSRetrieverDelegate.h"

#import "Session.h"

@interface EMSDetailViewController : UIViewController <EMSRetrieverDelegate>

@property (nonatomic, strong) Session *session;
@property (nonatomic, strong) IBOutlet UIWebView *webView;

@property (nonatomic, strong) IBOutlet UILabel *room;
@property (nonatomic, strong) IBOutlet UILabel *time;
@property (nonatomic, strong) IBOutlet UILabel *level;

@property (nonatomic, strong) IBOutlet UIButton *button;

- (IBAction)share:(id)sender;
- (IBAction)toggleFavourite:(id)sender;

@end
