//
//  EMSSettingsViewController.h
//

#import <UIKit/UIKit.h>

#import "EMSSpeakersRetrieverDelegate.h"
#import "EMSModel.h"

@interface EMSSettingsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end
