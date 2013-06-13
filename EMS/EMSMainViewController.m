//
//  EMSMainViewController.m
//  EMS
//
//  Created by Chris Searle on 14.06.13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import "EMSMainViewController.h"
#import "EMSModel.h"

#import "EMSSlot.h"

#import "EMSRetriever.h"

#import "EMSAppDelegate.h"

#import "EMSSettingsViewController.h"

@interface EMSMainViewController ()

@end

@implementation EMSMainViewController

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize retriever;
@synthesize retrievingRooms;
@synthesize retrievingSlots;

@synthesize model;

- (void) setUpRefreshControl {
    NSLog(@"Initializing refresh control");
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    
    refreshControl.tintColor = [UIColor grayColor];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refresh available sessions"];
    
    [refreshControl addTarget:self action:@selector(retrieve) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refreshControl;
}

- (NSManagedObject *)conferenceForHref:(NSString *)href {
    NSLog(@"Getting conference for %@", href);
    return [self.model conferenceForHref:href];
}

- (NSManagedObject *)activeConference {
    NSLog(@"Getting current conference");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *activeConference = [[defaults URLForKey:@"activeConference"] absoluteString];
    
    if (activeConference != nil) {
        return [self conferenceForHref:activeConference];
    }
    
    return nil;
}

- (void)initializeFetchedResultsController {
    NSLog(@"Init FRC");
    NSError *error;
    
    if (![[self fetchedResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // TODO alert
    }
    
    [self.tableView reloadData];
    
    if ([[_fetchedResultsController sections] count] == 0) {
        [self.refreshControl beginRefreshing];
        [self retrieve];
    }
}

- (void) conferenceChanged:(id)sender {
    NSLog(@"Conference changed");
    [self.fetchedResultsController.fetchRequest setPredicate:[self currentConferencePredicate]];
    [self initializeFetchedResultsController];
}

- (void)viewDidLoad
{
    NSLog(@"View loaded");
    [super viewDidLoad];
    
    self.model = [[EMSAppDelegate sharedAppDelegate] model];
    
    self.retrievingSlots = NO;
    self.retrievingRooms = NO;
    
    self.retriever = [[EMSRetriever alloc] init];
    self.retriever.delegate = self;

    [self setUpRefreshControl];

    // All sections start with the same year name - so the index is meaningless.
    // Can't turn it off - so let's have it only if we have at least 500 sections :)
    // This is also set in the storyboard but appears not to work.
    self.tableView.sectionIndexMinimumDisplayRowCount = 500;
    
    NSLog(@"Checking");

    NSManagedObject *conference = [self activeConference];
    
    if (conference == nil) {
        NSLog(@"No conference");
        [self performSegueWithIdentifier:@"showSettingsView" sender:self];
    } else {
        NSLog(@"Conference found");
        [self initializeFetchedResultsController];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"Preparing to load settings viww");
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"showSettingsView"])
    {
        EMSSettingsViewController *destination = [segue destinationViewController];

        destination.delegate = self;
    }
}

- (void)viewDidUnload
{
    NSLog(@"viewDidUnload");
    self.model = nil;
    self.fetchedResultsController = nil;
    self.retriever = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSPredicate *)currentConferencePredicate {
    NSLog(@"Get current conference predicate");

    NSManagedObject *activeConference = [self activeConference];
    
    if (activeConference != nil) {
        NSPredicate *conferencePredicate = [NSPredicate predicateWithFormat: @"(conference == %@)", activeConference];

        return conferencePredicate;
    }
    
    return nil;
}

- (NSFetchedResultsController *)fetchedResultsController {
    NSLog(@"Get FRC");
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSLog(@"Build FRC");

    NSManagedObjectContext *managedObjectContext = [[EMSAppDelegate sharedAppDelegate] managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Session" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortSlot = [[NSSortDescriptor alloc]
                                  initWithKey:@"slotName" ascending:YES];
    NSSortDescriptor *sortRoom = [[NSSortDescriptor alloc]
                                  initWithKey:@"room.name" ascending:YES];
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortSlot, sortRoom, nil]];
    [fetchRequest setFetchBatchSize:20];
    
    NSPredicate *conferencePredicate = [self currentConferencePredicate];
    
    if (conferencePredicate != nil) {
        NSLog(@"With predicate");

        [fetchRequest setPredicate:conferencePredicate];
    }
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:@"slotName"
                                                   cacheName:nil];
    
    self.fetchedResultsController = theFetchedResultsController;
    
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[_fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    
    return [sectionInfo numberOfObjects];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *session = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = [session valueForKey:@"title"];
    
    cell.detailTextLabel.text = [[session valueForKey:@"room"] valueForKey:@"name"];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SessionCell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SessionCell"];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [_fetchedResultsController sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [_fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

#pragma mark - retrieval

- (void) retrieve {
    NSManagedObject *conference = [self activeConference];

    NSLog(@"Starting retrieval");

    if (conference != nil) {
        NSLog(@"Starting retrieval - saw conf");

        if ([conference valueForKey:@"slotCollection"] != nil) {
            NSLog(@"Starting retrieval - saw slot collection");
            self.retrievingSlots = YES;
            [self.retriever refreshSlots:[NSURL URLWithString:[conference valueForKey:@"slotCollection"]]];
        }
        if ([conference valueForKey:@"roomCollection"] != nil) {
            NSLog(@"Starting retrieval - saw room collection");
            self.retrievingRooms = YES;
            [self.retriever refreshRooms:[NSURL URLWithString:[conference valueForKey:@"roomCollection"]]];
        }
    }
}

- (void) retrieveSessions {
    NSLog(@"Starting retrieval of sessions");
    // Fetch sessions once rooms and slots are done. Don't want to get into a state when trying to persist sessions that it refers to non-existing room or slot
    if (self.retrievingRooms == NO && self.retrievingSlots == NO) {
        NSLog(@"Starting retrieval of sessions - clear to go");
        [self.retriever refreshSessions:[NSURL URLWithString:[[self activeConference] valueForKey:@"sessionCollection"]]];
    }
}

- (void) finishedSlots:(NSArray *)slots forHref:(NSURL *)href {
    NSLog(@"Storing slots %d", [slots count]);
    
    [self.model storeSlots:slots forConference:[href absoluteString] error:nil];

    self.retrievingSlots = NO;
    
    [self retrieveSessions];
}

- (void) finishedSessions:(NSArray *)sessions forHref:(NSURL *)href {
    NSLog(@"Storing sessions %d", [sessions count]);

    [self.model storeSessions:sessions forConference:[href absoluteString] error:nil];
    
    [self.refreshControl endRefreshing];
}

- (void) finishedRooms:(NSArray *)rooms forHref:(NSURL *)href {
    NSLog(@"Storing rooms %d", [rooms count]);

    [self.model storeRooms:rooms forConference:[href absoluteString] error:nil];
    
    self.retrievingRooms = NO;
    
    [self retrieveSessions];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    NSLog(@"controller will change content %d", [[self.fetchedResultsController sections] count]);
    
    for(int i=0; i < [[self.fetchedResultsController sections] count]; i++) {
        NSLog(@"Section %d has %d rows", i, [[[self.fetchedResultsController sections] objectAtIndex:i] numberOfObjects]);
    }
    
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            NSLog(@"didChangeObject insert");
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            NSLog(@"didChangeObject delete");
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            NSLog(@"didChangeObject update");
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            NSLog(@"didChangeObject move");
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            NSLog(@"didChangeSection insert");
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            NSLog(@"didChangeSection delete");
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    NSLog(@"controller did change content %d", [[self.fetchedResultsController sections] count]);
    
    for(int i=0; i < [[self.fetchedResultsController sections] count]; i++) {
        NSLog(@"Section %d has %d rows", i, [[[self.fetchedResultsController sections] objectAtIndex:i] numberOfObjects]);
    }
    
    
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

@end
