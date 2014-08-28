//
//  EMSDetailViewController.h
//

#import <UIKit/UIKit.h>
#import "EMSSpeakersRetrieverDelegate.h"

#import "Session.h"

@interface EMSDetailViewController : UITableViewController

@property(nonatomic, strong) Session *session;

@end
