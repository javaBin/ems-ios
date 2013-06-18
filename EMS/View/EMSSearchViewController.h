//
//  EMSSearchViewController.h
//  EMS
//
//  Created by Chris Searle on 6/18/13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EMSSearchViewDelegate.h"

@interface EMSSearchViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (nonatomic, weak) id <EMSSearchViewDelegate> delegate;

@property (nonatomic, strong) NSString *currentSearch;
@property (nonatomic, strong) NSSet *currentLevels;
@property (nonatomic, strong) NSSet *currentKeywords;
@property (nonatomic, strong) IBOutlet UISearchBar *search;
@property (nonatomic, strong) NSArray *levels;
@property (nonatomic, strong) NSArray *keywords;

- (IBAction)clear:(id)sender;
- (IBAction)apply:(id)sender;

@end
