//
//  EMSSearchViewController.h
//

#import <UIKit/UIKit.h>

#import "EMSSearchViewDelegate.h"

@interface EMSSearchViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (nonatomic, weak) id <EMSSearchViewDelegate> delegate;

@property (nonatomic, strong) NSString *currentSearch;
@property (nonatomic, strong) NSSet *currentLevels;
@property (nonatomic, strong) NSSet *currentKeywords;
@property (nonatomic, strong) NSSet *currentTypes;
@property (nonatomic, strong) NSSet *currentRooms;
@property (nonatomic, strong) IBOutlet UISearchBar *search;
@property (nonatomic, strong) NSArray *levels;
@property (nonatomic, strong) NSArray *keywords;
@property (nonatomic, strong) NSArray *types;
@property (nonatomic, strong) NSArray *rooms;

- (IBAction)clear:(id)sender;
- (IBAction)apply:(id)sender;

@end
