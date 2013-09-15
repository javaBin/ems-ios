//
//  EMSMainViewController.h
//

#import <UIKit/UIKit.h>

#import "EMSRetrieverDelegate.h"
#import "EMSSearchViewDelegate.h"
#import "EMSRetriever.h"


#import "EMSAdvancedSearch.h"

#import "EMSModel.h"

@interface EMSMainViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, EMSRetrieverDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate, EMSSearchViewDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) EMSRetriever *retriever;

@property (nonatomic, assign) BOOL retrievingSlots;
@property (nonatomic, assign) BOOL retrievingRooms;

@property (nonatomic, assign) BOOL filterFavourites;
@property (nonatomic, assign) BOOL filterTime;

@property (nonatomic, strong) EMSAdvancedSearch *advancedSearch;

@property (nonatomic, strong) IBOutlet UISearchBar *search;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *advancedSearchButton;

@property (nonatomic, strong) IBOutlet UIView *footer;
@property (nonatomic, strong) IBOutlet UILabel *footerLabel;


- (IBAction)toggleFavourite:(id)sender;
- (IBAction)segmentChanged:(id)sender;

- (void)pushDetailViewForHref:(NSString *)href;
- (IBAction)back:(UIStoryboardSegue *)segue;

@end
