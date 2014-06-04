//
//  EMSMainViewController.h
//

#import <UIKit/UIKit.h>

#import "EMSRetrieverDelegate.h"
#import "EMSSearchViewDelegate.h"
#import "EMSRetriever.h"

#import "EMSAdvancedSearch.h"

#import "EMSModel.h"

@interface EMSMainViewController : UITableViewController

- (void)pushDetailViewForHref:(NSString *)href;

@end
