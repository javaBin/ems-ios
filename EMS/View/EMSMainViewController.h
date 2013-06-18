//
//  EMSMainViewController.h
//  EMS
//
//  Created by Chris Searle on 14.06.13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EMSRetrieverDelegate.h"
#import "EMSConferenceChangedDelegate.h"
#import "EMSRetriever.h"

#import "EMSModel.h"

@interface EMSMainViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, EMSRetrieverDelegate, EMSConferenceChangedDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) EMSRetriever *retriever;

@property (nonatomic, assign) BOOL retrievingSlots;
@property (nonatomic, assign) BOOL retrievingRooms;

@property (nonatomic, strong) NSString *currentSearch;

- (IBAction)toggleFavourite:(id)sender;

@end
