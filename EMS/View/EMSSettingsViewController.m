//
//  EMSSettingsViewController.m
//

#import "EMSSettingsViewController.h"

#import "EMSRetriever.h"

#import "EMSConference.h"
#import "EMSSlot.h"

#import "EMSAppDelegate.h"
#import "EMSFeatureConfig.h"

#import "EMSMainViewController.h"

#import "EMSModel.h"

@interface EMSSettingsViewController ()

@end

@implementation EMSSettingsViewController

- (void) setUpRefreshControl {
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    
    refreshControl.tintColor = [UIColor grayColor];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refresh available conferences"];
    
    [refreshControl addTarget:self action:@selector(retrieve) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refreshControl;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.justRetrieved = NO;
    self.emptyInitial = NO;
    
    [self setUpRefreshControl];

#ifndef DEBUG
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem.enabled = NO;
#else
    if (![EMSFeatureConfig isFeatureEnabled:fLocalNotifications]) {
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
#endif

    NSError *error;

	if (![[self fetchedResultsController] performFetch:&error]) {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle: @"Unable to connect view to data store"
                                   message: @"The data store did something unexpected and without it this application has no data to show. This is not an error we can recover from - please exit using the home button."
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        [errorAlert show];
        
        CLS_LOG(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    if (![[[EMSAppDelegate sharedAppDelegate] model] conferencesWithDataAvailable]) {
        self.emptyInitial = YES;

        [self.tableView setContentOffset:CGPointMake(0, -100) animated:YES];
        [self.refreshControl beginRefreshing];
        [self retrieve];
    }
}

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSManagedObjectContext *managedObjectContext = [[EMSAppDelegate sharedAppDelegate] managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Conference" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];

    NSSortDescriptor *startSort = [[NSSortDescriptor alloc]
                                  initWithKey:@"start" ascending:NO];
    
    NSSortDescriptor *nameSort = [[NSSortDescriptor alloc]
                              initWithKey:@"name" ascending:NO];
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:startSort, nameSort, nil]];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSPredicate *countPredicate = [NSPredicate predicateWithFormat:@"hintCount > 0"];
    
    [fetchRequest setPredicate:countPredicate];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:@"Conferences"];
    self.fetchedResultsController = theFetchedResultsController;

    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

- (void) retrieve {
    EMSRetriever *retriever = [[EMSRetriever alloc] init];
    
    retriever.delegate = self;
    
    CLS_LOG(@"Retrieving conferences");
    
    [retriever refreshConferences];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];

    return [sectionInfo numberOfObjects];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Conference *conference = [_fetchedResultsController objectAtIndexPath:indexPath];
        
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@",
                           conference.name,
                           conference.venue];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    NSMutableArray *dates = [[NSMutableArray alloc] init];

    if (conference.start != nil) {
        [dates addObject:[dateFormatter stringFromDate:conference.start]];
    }

    if (conference.end != nil) {
        [dates addObject:[dateFormatter stringFromDate:conference.end]];
    }

    cell.detailTextLabel.text = [dates componentsJoinedByString:@" - "];

    NSString *activeConference = [[EMSAppDelegate currentConference] absoluteString];

    if ([conference.href isEqualToString:activeConference]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConferenceCell"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ConferenceCell"];
    }

    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Available Conferences";
}


- (void) selectConference:(Conference *)conference {
    [EMSAppDelegate storeCurrentConference:[NSURL URLWithString: conference.href]];
    
    [self.tableView reloadData];
    
    [self.delegate conferenceChanged:self];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)finishedConferences:(NSArray *)conferenceList forHref:(NSURL *)href {
    self.justRetrieved = YES;

    NSError *error = nil;
    
    if (![[[EMSAppDelegate sharedAppDelegate] model] storeConferences:conferenceList error:&error]) {
        CLS_LOG(@"Failed to store conferences %@ - %@", error, [error userInfo]);
    }

    [self.refreshControl endRefreshing];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self selectConference:[_fetchedResultsController objectAtIndexPath:indexPath]];
}


#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
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
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    
    if (self.justRetrieved == YES && self.emptyInitial == YES) {
        self.justRetrieved = NO;
        self.emptyInitial = NO;
        
        Conference *conference = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        
        [self selectConference:conference];
    }
}

@end
