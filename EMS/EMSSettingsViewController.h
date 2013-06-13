//
//  EMSSettingsViewController.h
//

#import <UIKit/UIKit.h>

// TODO - Temp - get conferences directly - needs to move to model
#import "EMSRetrieverDelegate.h"

@interface EMSSettingsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, EMSRetrieverDelegate>

@property (strong, nonatomic) NSArray *conferences;

@end

// TODO - look at NSFetchedResultsController