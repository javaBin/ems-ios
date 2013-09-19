//
//  EMSMainViewController.m
//

#import "EMSMainViewController.h"
#import "EMSModel.h"

#import "EMSSlot.h"

#import "EMSRetriever.h"

#import "EMSAppDelegate.h"

#import "EMSSettingsViewController.h"
#import "EMSDetailViewController.h"
#import "EMSSearchViewController.h"

#import "EMSSessionCell.h"

#import "Conference.h"
#import "ConferenceKeyword.h"
#import "ConferenceLevel.h"
#import "ConferenceType.h"
#import "Speaker.h"
#import "Room.h"
#import "Keyword.h"

@interface EMSMainViewController ()<UISplitViewControllerDelegate>

@end

@implementation EMSMainViewController

- (void) setUpRefreshControl {
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    
    refreshControl.tintColor = [UIColor grayColor];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refresh available sessions"];
    refreshControl.backgroundColor = self.tableView.backgroundColor;
    
    [refreshControl addTarget:self action:@selector(retrieve) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refreshControl;
}

- (Conference *)conferenceForHref:(NSString *)href {
    CLS_LOG(@"Getting conference for %@", href);
    
    return [[[EMSAppDelegate sharedAppDelegate] model] conferenceForHref:href];
}

- (Conference *)activeConference {
    CLS_LOG(@"Getting current conference");
    
    NSString *activeConference = [[EMSAppDelegate currentConference] absoluteString];
    
    if (activeConference != nil) {
        return [self conferenceForHref:activeConference];
    }
    
    return nil;
}

- (void)initializeFooter {
    if ([[self.fetchedResultsController sections] count] == 0) {
        NSMutableString *labelText = [[NSMutableString alloc] init];
        
        [labelText appendString:@"No rows found."];
        
        if ([[[EMSAppDelegate sharedAppDelegate] model] sessionsAvailableForConference:[[self activeConference] href]]) {
            [labelText appendString:@" Try"];
            
            if ([self.advancedSearch hasAdvancedSearch] || ![self.search.text isEqualToString:@""]) {
                [labelText appendString:@" a less restrictive search,"];
            }
            
            if (self.filterFavourites == YES || self.filterTime == YES) {
                [labelText appendString:@" switching back to the full list,"];
            }
            
            [labelText appendString:@" or you can refresh the session list with pull to refresh."];
        } else {
            [labelText appendString:@" Refreshing session list."];
        }
        
        self.footerLabel.text = [NSString stringWithString:labelText];
        
        self.footer.hidden = NO;
    } else {
        self.footer.hidden = YES;
    }
}

- (void)initializeFetchedResultsController {
    [self.fetchedResultsController.fetchRequest setPredicate:[self currentConferencePredicate]];

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

    [self initializeFooter];
    
    [self.tableView reloadData];

    Conference *activeConference = [self activeConference];

    if (![[[EMSAppDelegate sharedAppDelegate] model] sessionsAvailableForConference:activeConference.href]) {
        CLS_LOG(@"Checking for existing data found no data - forced refresh");

        [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
        [self.refreshControl beginRefreshing];
        [self retrieve];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Sessions";
    
    self.retrievingSlots = NO;
    self.retrievingRooms = NO;

    self.filterFavourites = NO;
    self.filterTime = NO;

    self.advancedSearch = [[EMSAdvancedSearch alloc] init];
    
    self.search.text = [self.advancedSearch search];
    
    self.retriever = [[EMSRetriever alloc] init];
    self.retriever.delegate = self;

    [self setUpRefreshControl];

    // All sections start with the same year name - so the index is meaningless.
    // Can't turn it off - so let's have it only if we have at least 500 sections :)
    // This is also set in the storyboard but appears not to work.
    self.tableView.sectionIndexMinimumDisplayRowCount = 500;
    
    Conference *conference = [self activeConference];
    
    if (conference == nil) {
        CLS_LOG(@"No conference - push to settings view");

        [self performSegueWithIdentifier:@"showSettingsView" sender:self];
    } else {
        CLS_LOG(@"Conference found - initialize");

        [self initializeFetchedResultsController];
    }
    
    
    if (self.splitViewController) {
        self.splitViewController.delegate = self;
    }
    
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
   /* if (!self.refreshControl.refreshing) {
        if ([self.search.text isEqualToString:@""]) {
            if (self.tableView.contentOffset.y < 44) {
                [self.tableView setContentOffset:CGPointMake(0, 44)];
            }
        }
    }*/
    
    if (self.splitViewController) {
        if ([self.tableView indexPathForSelectedRow] == nil) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
            [self performSegueWithIdentifier:@"showDetailsView" sender:self];
        }
    }
}

- (void) viewDidAppear:(BOOL)animated {
#ifndef DO_NOT_USE_GA
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendView:@"Main Screen"];
#endif
}

- (void)pushDetailViewForHref:(NSString *)href {
    [self performSegueWithIdentifier:@"showDetailsView" sender:href];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.search setShowsCancelButton:NO animated:YES];
    [self.search resignFirstResponder];

#ifndef DO_NOT_USE_GA
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
#endif
        
    if ([[segue identifier] isEqualToString:@"showDetailsView"]) {
        UIViewController *tmpDestination = [segue destinationViewController];
        if ([tmpDestination isKindOfClass:[UINavigationController class]]) {
            tmpDestination = tmpDestination.childViewControllers[0];
        }
        
        EMSDetailViewController *destination = (EMSDetailViewController *)tmpDestination;

        if ([sender isKindOfClass:[NSString class]]) {
            Session *session = [[[EMSAppDelegate sharedAppDelegate] model] sessionForHref:(NSString *)sender];
            
            CLS_LOG(@"Preparing detail view from passed href %@", session);
            
            destination.session = session;
            
#ifndef DO_NOT_USE_CRASHLYTICS
            [Crashlytics setObjectValue:session.href forKey:@"lastDetailSessionFromNotification"];
#endif
            
#ifndef DO_NOT_USE_GA
            [tracker trackEventWithCategory:@"listView"
                                 withAction:@"detailFromNotification"
                                  withLabel:session.href
                                  withValue:nil];
#endif
        } else {
            Session *session = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];

            CLS_LOG(@"Preparing detail view with %@", session);

            destination.session = session;

#ifndef DO_NOT_USE_CRASHLYTICS
            [Crashlytics setObjectValue:session.href forKey:@"lastDetailSession"];
#endif
            
#ifndef DO_NOT_USE_GA
            [tracker trackEventWithCategory:@"listView"
                                 withAction:@"detail"
                                  withLabel:session.href
                                  withValue:nil];
#endif
        }

        destination.fetchedResultsController = self.fetchedResultsController;
        destination.indexPath = [[self tableView] indexPathForSelectedRow];
    }
    
    if ([[segue identifier] isEqualToString:@"showSearchView"]) {
        UINavigationController *navigationController = [segue destinationViewController];
        EMSSearchViewController *destination = (EMSSearchViewController *) navigationController.childViewControllers[0];

        CLS_LOG(@"Preparing search view with %@ and conference %@", self.search.text, [self activeConference]);

        destination.advancedSearch = self.advancedSearch;
        
        Conference *conference = [self activeConference];

        NSMutableArray *levels = [[NSMutableArray alloc] init];

        [conference.conferenceLevels enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            ConferenceLevel *level = (ConferenceLevel *)obj;

            [levels addObject:level.name];
        }];

        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"EMS-Config" ofType:@"plist"];
        NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:filePath];
        NSDictionary *sort = [prefs objectForKey:@"level-sort"];
        
        destination.levels = [levels sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSNumber *firstKey = [sort valueForKey:obj1];
            NSNumber *secondKey = [sort valueForKey:obj2];
            
            if ([firstKey integerValue] > [secondKey integerValue]) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            
            if ([firstKey integerValue] < [secondKey integerValue]) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedSame;
        }];
        
        NSMutableArray *keywords = [[NSMutableArray alloc] init];

        [conference.conferenceKeywords enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            ConferenceKeyword *keyword = (ConferenceKeyword *)obj;

            [keywords addObject:keyword.name];
        }];

        destination.keywords = [keywords sortedArrayUsingSelector: @selector(compare:)];

        NSMutableArray *rooms = [[NSMutableArray alloc] init];
        
        [conference.rooms enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            Room *room = (Room *)obj;
            
            [rooms addObject:room.name];
        }];
        
        destination.rooms = [rooms sortedArrayUsingSelector: @selector(compare:)];
        
        NSMutableArray *types = [[NSMutableArray alloc] init];
        
        [conference.conferenceTypes enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            ConferenceType *type = (ConferenceType *)obj;
            
            [types addObject:type.name];
        }];

        destination.types = [types sortedArrayUsingSelector: @selector(compare:)];

        destination.delegate = self;

#ifndef DO_NOT_USE_GA
        [tracker trackEventWithCategory:@"listView"
                             withAction:@"search"
                              withLabel:nil
                              withValue:nil];
#endif
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSPredicate *)currentConferencePredicate {
    Conference *activeConference = [self activeConference];
    
    if (activeConference != nil) {
        NSMutableArray *predicates = [[NSMutableArray alloc] init];
        
        [predicates
         addObject:[NSPredicate predicateWithFormat: @"((state == %@) AND (conference == %@))",
                    @"approved",
                    activeConference]];

        if (!([[self.advancedSearch search] isEqualToString:@""])) {
            [predicates
             addObject:[NSPredicate predicateWithFormat:@"(title CONTAINS[cd] %@ OR body CONTAINS[cd] %@ OR ANY speakers.name CONTAINS[cd] %@)",
                        [self.advancedSearch search],
                        [self.advancedSearch search],
                        [self.advancedSearch search]]];
        }

        if ([[self.advancedSearch fieldValuesForKey:emsLevel] count] > 0) {
            [predicates
             addObject:[NSPredicate predicateWithFormat:@"(level IN %@)",
                        [self.advancedSearch fieldValuesForKey:emsLevel]]];
        }

        if ([[self.advancedSearch fieldValuesForKey:emsType] count] > 0) {
            [predicates
             addObject:[NSPredicate predicateWithFormat:@"(format IN %@)",
                        [self.advancedSearch fieldValuesForKey:emsType]]];
        }

        if ([[self.advancedSearch fieldValuesForKey:emsRoom] count] > 0) {
            [predicates
             addObject:[NSPredicate predicateWithFormat:@"(room.name IN %@)",
                        [self.advancedSearch fieldValuesForKey:emsRoom]]];
        }
        
        if ([[self.advancedSearch fieldValuesForKey:emsKeyword] count] > 0) {
            NSMutableArray *keywordPredicates = [[NSMutableArray alloc] init];

            [[self.advancedSearch fieldValuesForKey:emsKeyword] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                NSString *keyword = (NSString *)obj;

                [keywordPredicates
                 addObject:[NSPredicate predicateWithFormat:@"(ANY keywords.name CONTAINS[cd] %@)",
                            keyword]];
            }];

            [predicates
             addObject:[NSCompoundPredicate orPredicateWithSubpredicates:keywordPredicates]];
        }

        if ([[self.advancedSearch fieldValuesForKey:emsLang] count] > 0) {
            NSSet *languages = [self.advancedSearch fieldValuesForKey:emsLang];
            
            NSMutableSet *langs = [[NSMutableSet alloc] init];
            
            [languages enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                NSString *language = (NSString *)obj;
                
                if ([language isEqualToString:@"English"]) {
                    [langs addObject:@"en"];
                }

                if ([language isEqualToString:@"Norwegian"]) {
                    [langs addObject:@"no"];
                }
            }];
            
            [predicates
             addObject:[NSPredicate predicateWithFormat:@"(language IN %@)",
                        [NSSet setWithSet:langs]]];
        }

        if (self.filterFavourites == YES) {
            [predicates
             addObject:[NSPredicate predicateWithFormat:@"favourite = %@", [NSNumber numberWithBool:YES]]];
        }

        if (self.filterTime == YES) {
            NSSet *slots = [[[EMSAppDelegate sharedAppDelegate] model] activeSlotNamesForConference:activeConference];

            [predicates
             addObject:[NSPredicate predicateWithFormat:@"slot IN %@", slots]];
        }

        NSPredicate *resultPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
        
#ifndef DO_NOT_USE_CRASHLYTICS
        [Crashlytics setObjectValue:resultPredicate forKey:@"activePredicate"];
#endif
        
        return resultPredicate;
    }

    return nil;
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSManagedObjectContext *managedObjectContext = [[EMSAppDelegate sharedAppDelegate] uiManagedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Session" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortSlot  = [[NSSortDescriptor alloc]
                                   initWithKey:@"slotName" ascending:YES];
    NSSortDescriptor *sortRoom  = [[NSSortDescriptor alloc]
                                   initWithKey:@"room.name" ascending:YES];
    NSSortDescriptor *sortTime  = [[NSSortDescriptor alloc]
                                   initWithKey:@"slot.start" ascending:YES];
    NSSortDescriptor *sortTitle = [[NSSortDescriptor alloc]
                                   initWithKey:@"title" ascending:YES];

    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortSlot, sortRoom, sortTime, sortTitle, nil]];
    [fetchRequest setFetchBatchSize:20];
    
    NSPredicate *conferencePredicate = [self currentConferencePredicate];
    
    if (conferencePredicate != nil) {
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

- (void)toggleFavourite:(id)sender {
    UIButton *button = (UIButton *)sender;
    
	UIView *view = [button superview];
	
	while (view != nil) {
		if ([view isKindOfClass:[EMSSessionCell class]]) {
			EMSSessionCell *cell = (EMSSessionCell *)view;
			
            Session *session = cell.session;
            
            [[[EMSAppDelegate sharedAppDelegate] model] toggleFavourite:session];

			break;
		}
        
		view = [view superview];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSUInteger count = [[_fetchedResultsController sections] count];
    
    CLS_LOG(@"numberOfSectionsInTableView: Found %d sections", count);
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];

    NSUInteger count = [sectionInfo numberOfObjects];

    CLS_LOG(@"tableView:numberOfRowsInSection: %d: Found %d rows", section, count);
    
    return count;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    CLS_LOG(@"configureCell:atIndexPath: asking for section %d and row %d", indexPath.section, indexPath.row);
    
    Session *session = [_fetchedResultsController objectAtIndexPath:indexPath];

    EMSSessionCell *sessionCell = (EMSSessionCell *)cell;
    
    UIButton *icon = sessionCell.icon;
    
    [icon setSelected:[session.favourite boolValue]];
    
    NSString *imageBaseName = [session.format isEqualToString:@"lightning-talk"] ? @"64-zap" : @"28-star";
    NSString *imageNameFormat = @"%@-%@";
    
    UIImage *normalImage = [UIImage imageNamed:[NSString stringWithFormat:imageNameFormat, imageBaseName, @"grey"]];
    UIImage *selectedImage = [UIImage imageNamed:[NSString stringWithFormat:imageNameFormat, imageBaseName, @"yellow"]];

    if ([UIImage instancesRespondToSelector:@selector(imageWithRenderingMode:)]) {
        normalImage = [normalImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        selectedImage = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        if (icon.selected) {
            icon.tintColor = nil;
        } else {
            icon.tintColor = [UIColor lightGrayColor];  
        }
    }
    
    [icon setImage:normalImage forState:UIControlStateNormal];
    [icon setImage:selectedImage forState:UIControlStateSelected];
    
    [sessionCell.icon addTarget:self action:@selector(toggleFavourite:) forControlEvents:UIControlEventTouchUpInside];

    UIImageView *level = sessionCell.level;
    
    [level setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@.png", session.level]]];
    
    UIImageView *video = sessionCell.video;
    
    if (session.videoLink) {
        [video setImage:[UIImage imageNamed:@"70-tv"]];
    } else {
        [video setImage:nil];
    }
    
    sessionCell.title.text = session.title;
    if (session.room) {
        sessionCell.room.text = session.room.name;
    } else {
        sessionCell.room.text = @"";
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        sessionCell.summary.text = session.summary;

        NSMutableArray *keywordNames = [[NSMutableArray alloc] init];

        [session.keywords enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            Keyword *keyword = (Keyword *)obj;

            [keywordNames addObject:keyword.name];
        }];

        NSArray *sortedKeywords = [keywordNames sortedArrayUsingSelector:@selector(compare:)];

        if (sortedKeywords.count > 4) {
            NSMutableArray *temp = [NSMutableArray arrayWithArray:[sortedKeywords subarrayWithRange:NSMakeRange(0, 3)]];

            [temp addObject:[NSString stringWithFormat:@"and %d more", sortedKeywords.count - 3]];

            sortedKeywords = [NSArray arrayWithArray:temp];
        }
        if (sortedKeywords.count > 0) {
            sessionCell.keywords.text = [NSString stringWithFormat:@"\u2022 %@\n", [sortedKeywords componentsJoinedByString:@"\n\u2022 "]];
        } else {
            sessionCell.keywords.text = @"";
        }
    }

    NSMutableArray *speakerNames = [[NSMutableArray alloc] init];

    [session.speakers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        Speaker *speaker = (Speaker *)obj;
        
        [speakerNames addObject:speaker.name];
    }];

    sessionCell.speaker.text = [speakerNames componentsJoinedByString:@", "];
    
    sessionCell.session = session;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLS_LOG(@"tableView:cellForRowAtIndexPath: asking for section %d and row %d", indexPath.section, indexPath.row);

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SessionCell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SessionCell"];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
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
    Conference *activeConference = [self activeConference];

    CLS_LOG(@"Starting retrieval");

    if (activeConference != nil) {
        CLS_LOG(@"Starting retrieval - saw conf");

        if (activeConference.slotCollection != nil) {
            CLS_LOG(@"Starting retrieval - saw slot collection");
            self.retrievingSlots = YES;
            [self.retriever refreshSlots:[NSURL URLWithString:activeConference.slotCollection]];
        }
        if (activeConference.roomCollection != nil) {
            CLS_LOG(@"Starting retrieval - saw room collection");
            self.retrievingRooms = YES;
            [self.retriever refreshRooms:[NSURL URLWithString:activeConference.roomCollection]];
        }
    }
}

- (void) retrieveSessions {
    CLS_LOG(@"Starting retrieval of sessions");
    // Fetch sessions once rooms and slots are done. Don't want to get into a state when trying to persist sessions that it refers to non-existing room or slot
    if (self.retrievingRooms == NO && self.retrievingSlots == NO) {
        CLS_LOG(@"Starting retrieval of sessions - clear to go");
        Conference *activeConference = [self activeConference];
        [self.retriever refreshSessions:[NSURL URLWithString:activeConference.sessionCollection]];
    }
}

- (void) finishedSlots:(NSArray *)slots forHref:(NSURL *)href {
    CLS_LOG(@"Storing slots %d", [slots count]);
    
    NSError *error = nil;

    EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

    if (![backgroundModel storeSlots:slots forHref:[href absoluteString] error:&error]) {
        CLS_LOG(@"Failed to store slots %@ - %@", error, [error userInfo]);
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        self.retrievingSlots = NO;

        [self retrieveSessions];
    });
}

- (void) finishedSessions:(NSArray *)sessions forHref:(NSURL *)href {
    CLS_LOG(@"Storing sessions %d", [sessions count]);

    NSError *error = nil;

    EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

    if (![backgroundModel storeSessions:sessions forHref:[href absoluteString] error:&error]) {
        CLS_LOG(@"Failed to store sessions %@ - %@", error, [error userInfo]);
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];
        [self.refreshControl endRefreshing];
        [self initializeFooter];
    });
}

- (void) finishedRooms:(NSArray *)rooms forHref:(NSURL *)href {
    CLS_LOG(@"Storing rooms %d", [rooms count]);

    NSError *error = nil;
    
    EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

    if (![backgroundModel  storeRooms:rooms forHref:[href absoluteString] error:&error]) {
        CLS_LOG(@"Failed to store rooms %@ - %@", error, [error userInfo]);
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        self.retrievingRooms = NO;

        [self retrieveSessions];
    });
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
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	if ([searchText length] == 0) {
        [self performSelector:@selector(hideKeyboardWithSearchBar:) withObject:searchBar afterDelay:0];
	}
    
    [self storeSearchPrefs];

    [self initializeFetchedResultsController];
}

- (void)hideKeyboardWithSearchBar:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    
    [self storeSearchPrefs];

    [self initializeFetchedResultsController];

    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self storeSearchPrefs];

    [self initializeFetchedResultsController];
	
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

- (void) storeSearchPrefs {
    [self.advancedSearch setSearch:self.search.text];
}

- (void) advancedSearchUpdated {
    // Need to reload
    self.advancedSearch = [[EMSAdvancedSearch alloc] init];

    self.search.text = [self.advancedSearch search];

    [self initializeFetchedResultsController];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) segmentChanged:(id)sender {
    self.filterFavourites = NO;
    self.filterTime = NO;

#ifndef DO_NOT_USE_GA
    UISegmentedControl *segment = (UISegmentedControl *)sender;

    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    switch ([segment selectedSegmentIndex]) {
        case 0:
        {
            // All
            [tracker trackEventWithCategory:@"listView"
                                 withAction:@"all"
                                  withLabel:nil
                                  withValue:nil];
            break;
        }
        case 1:
        {
            // My
            [tracker trackEventWithCategory:@"listView"
                                 withAction:@"favourites"
                                  withLabel:nil
                                  withValue:nil];


            self.filterFavourites = YES;
            break;
        }
        case 2:
        {
            // Now / Next
            [tracker trackEventWithCategory:@"listView"
                                 withAction:@"now/next"
                                  withLabel:nil
                                  withValue:nil];

            self.filterTime = YES;
            break;
        }

        default:
            break;
    }
#endif
    
    [self initializeFetchedResultsController];
}

- (IBAction)back:(UIStoryboardSegue *)segue {
    if ([[self.fetchedResultsController sections] count] > 0) {
        if ([segue.identifier isEqualToString:@"popDetailSegue"]) {
            EMSDetailViewController *detail = (EMSDetailViewController *)segue.sourceViewController;
            [self.tableView scrollToRowAtIndexPath:detail.indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }
    
    if ([segue.identifier isEqualToString:@"unwindSettingsSegue"]) {
        [self initializeFetchedResultsController];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation {
    return NO;
}

@end
