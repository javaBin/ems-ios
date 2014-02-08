//
//  EMSSearchViewController.h
//

#import <UIKit/UIKit.h>

#import "EMSSearchViewDelegate.h"
#import "EMSAdvancedSearch.h"

@interface EMSSearchViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property(nonatomic, weak) id <EMSSearchViewDelegate> delegate;

@property(nonatomic, strong) EMSAdvancedSearch *advancedSearch;
@property(nonatomic, strong) IBOutlet UISearchBar *search;
@property(nonatomic, strong) NSArray *levels;
@property(nonatomic, strong) NSArray *keywords;
@property(nonatomic, strong) NSArray *types;
@property(nonatomic, strong) NSArray *rooms;

- (IBAction)clear:(id)sender;

- (IBAction)apply:(id)sender;

@end
