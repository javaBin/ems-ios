//
//  EMSConferenceDetailViewController.h
//

#import <UIKit/UIKit.h>
#import "Conference.h"

@interface EMSConferenceDetailViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property(nonatomic, strong) Conference *conference;

@end
