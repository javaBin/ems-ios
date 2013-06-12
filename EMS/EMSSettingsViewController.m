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

#import "EMSConference.h"
#import "EMSSlot.h"

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
        EMSConference *c = [conferences objectAtIndex:indexPath.row];
        
        cell.textLabel.text = c.name;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@",
                                     [dateFormatter stringFromDate:c.start],
                                     [dateFormatter stringFromDate:c.end]];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *activeConference = [defaults objectForKey:@"activeConference"];
        
        if ([c.name isEqualToString:activeConference]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
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
- (void)finishedConferences:(NSArray *)conferenceList forHref:(NSURL *)href {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults removeObjectForKey:@"activeConference"];
    
    conferences = [NSArray arrayWithArray:conferenceList];
    
    [self.tableView reloadData];
    
    [self.refreshControl endRefreshing];
}

- (void)finishedSlots:(NSArray *)slotList forHref:(NSURL *)href {
    NSLog(@"Saw slots from %@", href);

    [slotList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        EMSSlot *slot = (EMSSlot *)obj;
        
        NSLog(@"Saw a slot %@ to %@", slot.start, slot.end);
    }];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    EMSConference *c = [conferences objectAtIndex:indexPath.row];
    
    [defaults setObject:c.name forKey:@"activeConference"];

    [self.tableView reloadData];
    
    EMSRetriever *retriever = [[EMSRetriever alloc] init];
    
    retriever.delegate = self;
    
    [retriever refreshSlots:c.slotCollection];
}

@end
