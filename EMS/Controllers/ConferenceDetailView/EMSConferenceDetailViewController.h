//
//  EMSConferenceDetailViewController.h
//

#import <UIKit/UIKit.h>

@class Conference;

@interface EMSConferenceDetailViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property(nonatomic, strong) Conference *conference;

@end
