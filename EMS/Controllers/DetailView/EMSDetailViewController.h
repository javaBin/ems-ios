//
//  EMSDetailViewController.h
//

#import <UIKit/UIKit.h>
#import "EMSSpeakersRetrieverDelegate.h"

@class Session;

@interface EMSDetailViewController : UITableViewController

@property(nonatomic, strong) Session *session;

@end
