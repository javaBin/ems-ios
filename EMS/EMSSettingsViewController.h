//
//  EMSSettingsViewController.h
//  EMS
//
//  Created by Chris Searle on 12.06.13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import <UIKit/UIKit.h>

// TODO - Temp - get conferences directly - needs to move to model
#import "EMSRetrieverDelegate.h"

@interface EMSSettingsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, EMSRetrieverDelegate>

@property (strong, nonatomic) NSArray *conferences;

@end

// TODO - look at NSFetchedResultsController