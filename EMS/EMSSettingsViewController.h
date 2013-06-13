//
//  EMSSettingsViewController.h
//

#import <UIKit/UIKit.h>

#import "EMSRetrieverDelegate.h"
#import "EMSConferenceChangedDelegate.h"
#import "EMSModel.h"

@interface EMSSettingsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, EMSRetrieverDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) id <EMSConferenceChangedDelegate> delegate;

@property (nonatomic, strong) EMSModel *model;

@end
