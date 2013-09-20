//
//  EMSDetailViewController.h
//

#import <UIKit/UIKit.h>
#import "EMSRetrieverDelegate.h"

#import "Session.h"

@interface EMSDetailViewController : UIViewController <EMSRetrieverDelegate, UIWebViewDelegate>

@property (nonatomic, strong) Session *session;
@property (nonatomic, strong) IBOutlet UIWebView *webView;

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;

@property (nonatomic, strong) IBOutlet UIButton *button;

@property (nonatomic, strong) NSDictionary *cachedSpeakerBios;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *previousSectionButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *nextSectionButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *previousSessionButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *nextSessionButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *shareButton;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSIndexPath *indexPath;

- (IBAction)share:(id)sender;
- (IBAction)toggleFavourite:(id)sender;
- (IBAction)clearImageCache:(id)sender;

@end
