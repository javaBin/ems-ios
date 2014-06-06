//
//  EMSSettingsViewController.m
//

#import "EMSSettingsViewController.h"

#import "EMSRetriever.h"

#import "EMSAppDelegate.h"
#import "EMSConferenceDetailViewController.h"

@interface EMSSettingsViewController ()

@end

@implementation EMSSettingsViewController

- (void)setUpRefreshControl {
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];

    refreshControl.tintColor = [UIColor grayColor];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refresh available conferences"];
    refreshControl.backgroundColor = self.tableView.backgroundColor;
    [refreshControl addTarget:self action:@selector(retrieve) forControlEvents:UIControlEventValueChanged];

    self.refreshControl = refreshControl;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.justRetrieved = NO;
    self.emptyInitial = NO;

    [self setUpRefreshControl];

    NSError *error;

    if (![[self fetchedResultsController] performFetch:&error]) {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                initWithTitle:@"Unable to connect view to data store"
                      message:@"The data store did something unexpected and without it this application has no data to show. This is not an error we can recover from - please exit using the home button."
                     delegate:nil
            cancelButtonTitle:@"OK"
            otherButtonTitles:nil];
        [errorAlert show];

        CLS_LOG(@"Unresolved error %@, %@", error, [error userInfo]);
    }

    if (![[[EMSAppDelegate sharedAppDelegate] model] conferencesWithDataAvailable]) {
        self.emptyInitial = YES;

        [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
        [self.refreshControl beginRefreshing];
        [self retrieve];
    }
}

- (void)viewDidAppear:(BOOL)animated {
#ifndef DO_NOT_USE_GA
    id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Settings Screen"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
#endif
}

- (NSFetchedResultsController *)fetchedResultsController {

    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSManagedObjectContext *managedObjectContext = [[EMSAppDelegate sharedAppDelegate] uiManagedObjectContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
            entityForName:@"Conference" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];

    NSSortDescriptor *startSort = [[NSSortDescriptor alloc]
            initWithKey:@"start" ascending:NO];

    NSSortDescriptor *nameSort = [[NSSortDescriptor alloc]
            initWithKey:@"name" ascending:NO];

    [fetchRequest setSortDescriptors:@[startSort, nameSort]];

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

- (void)retrieve {

    EMSRetriever *retriever = [[EMSRetriever alloc] init];

    retriever.delegate = self;

    CLS_LOG(@"Retrieving conferences");

    [retriever refreshConferences];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    if (section == 0) {
        id sectionInfo = [_fetchedResultsController sections][(NSUInteger) section];

        rows = [sectionInfo numberOfObjects];
    } else if (section == 1) {
        rows = 1;
    }

    return rows;

}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Conference *conference = [_fetchedResultsController objectAtIndexPath:indexPath];

    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@",
                                                     conference.name,
                                                     conference.venue];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;

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
        cell.imageView.image = [UIImage imageNamed:@"258-checkmark-grey"];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"blank"];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;


    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ConferenceCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ConferenceCell"];
        }

        [self configureCell:cell atIndexPath:indexPath];
    } else if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"AboutCell"];
    }


    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = @"";
    if (section == 0) {
        title = @"Available Conferences";
    }
    return title;

}


- (void)selectConference:(Conference *)conference {
    [EMSAppDelegate storeCurrentConference:[NSURL URLWithString:conference.href]];

    [self.tableView reloadData];


#ifndef DO_NOT_USE_GA
    id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"settingsView"
                                                          action:@"selectConference"
                                                           label:@"conference.href"
                                                           value:nil] build]];
#endif
}

- (void)finishedConferences:(NSArray *)conferenceList forHref:(NSURL *)href {
    self.justRetrieved = YES;

    NSError *error = nil;

    EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

    if (![backgroundModel storeConferences:conferenceList error:&error]) {
        CLS_LOG(@"Failed to store conferences %@ - %@", error, [error userInfo]);
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];

        [self.refreshControl endRefreshing];
    });
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        [self selectConference:[_fetchedResultsController objectAtIndexPath:indexPath]];
    }
}


#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

    UITableView *tableView = self.tableView;

    switch (type) {

        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;

        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeUpdate:
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];

    if (self.justRetrieved && self.emptyInitial) {
        self.justRetrieved = NO;
        self.emptyInitial = NO;

        Conference *conference = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

        [self selectConference:conference];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showConferenceDetailsView"]) {

        EMSConferenceDetailViewController *destination = (EMSConferenceDetailViewController *) [segue destinationViewController];

        CLS_LOG(@"Preparing conference detail view");

        Conference *conference = [_fetchedResultsController objectAtIndexPath:[self.tableView indexPathForCell:sender]];

        destination.conference = conference;
    }
}


@end
