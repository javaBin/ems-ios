//
//  EMSSettingsViewController.m
//  EMS
//
//  Created by Chris Searle on 12.06.13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import "EMSSettingsViewController.h"

// TODO - Temp - get conferences directly - needs to move to model
#import "EMSRetriever.h"

@interface EMSSettingsViewController ()

@end

@implementation EMSSettingsViewController

@synthesize conferences;

// TODO - populate conferences from model

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];

    refreshControl.tintColor = [UIColor magentaColor];
    
    [refreshControl addTarget:self action:@selector(retrieve) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refreshControl;
    
    conferences = [[NSArray alloc] init];
}

- (void) retrieve {
    EMSRetriever *retriever = [[EMSRetriever alloc] init];
    
    retriever.delegate = self;
    
    [retriever refreshConferences];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (conferences.count > 0) {
        return conferences.count;
    }

    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConferenceCell"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ConferenceCell"];
    }

    if (conferences.count > 0) {
        cell.textLabel.text = [[conferences objectAtIndex:indexPath.row] name];
        cell.detailTextLabel.text = @"TODO - show dates";
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
    } else {
        cell.textLabel.text = @"No conferences retrieved";
        cell.detailTextLabel.text = @"Pull to refresh";
        cell.textLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Available Conferences";
}


// TODO - Temp - get conferences directly - needs to move to model
- (void)finishedConferences:(NSArray *)conferenceList {
    conferences = [NSArray arrayWithArray:conferenceList];
    
    [self.tableView reloadData];
    
    [self.refreshControl endRefreshing];
}

@end
