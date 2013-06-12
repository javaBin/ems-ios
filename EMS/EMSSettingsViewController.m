//
//  EMSSettingsViewController.m
//  EMS
//
//  Created by Chris Searle on 12.06.13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import "EMSSettingsViewController.h"

@interface EMSSettingsViewController ()

@end

@implementation EMSSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];

    refreshControl.tintColor = [UIColor magentaColor];
    
    [refreshControl addTarget:self action:@selector(retrieve) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refreshControl;
}

- (void) retrieve {
    [self.refreshControl endRefreshing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConferenceCell"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ConferenceCell"];
    }
    
    cell.textLabel.text = @"No conferences retrieved";
    cell.textLabel.textColor = [UIColor grayColor];
    cell.detailTextLabel.text = @"Pull to refresh";
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Available Conferences";
}

@end
