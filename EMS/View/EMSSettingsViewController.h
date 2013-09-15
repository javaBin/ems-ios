//
//  EMSSettingsViewController.h
//

#import <UIKit/UIKit.h>

#import "EMSRetrieverDelegate.h"
#import "EMSModel.h"

@interface EMSSettingsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, EMSRetrieverDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, assign) BOOL justRetrieved;
@property (nonatomic, assign) BOOL emptyInitial;

@end
