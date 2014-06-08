//
//  EMSDetailViewController.h
//

#import <UIKit/UIKit.h>
#import "EMSRetrieverDelegate.h"

#import "Session.h"

@interface EMSDetailViewController : UIViewController 

@property(nonatomic, strong) Session *session;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, strong) NSIndexPath *indexPath;


- (void)refreshFavourite;

@end
