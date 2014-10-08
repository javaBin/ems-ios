//
//  EMSMainViewController.m
//

#import "EMSMainViewController.h"

#import "EMSAppDelegate.h"

#import "EMSDetailViewController.h"
#import "EMSSearchViewController.h"

#import "EMSSessionCell.h"

#import "ConferenceKeyword.h"
#import "ConferenceLevel.h"
#import "ConferenceType.h"
#import "Speaker.h"
#import "Room.h"
#import "EMSTracking.h"
#import "EMSLocalNotificationManager.h"

@interface EMSMainViewController () <UISplitViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate, EMSSearchViewDelegate, UIDataSourceModelAssociation>

@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property(nonatomic, assign) BOOL filterFavourites;

@property(nonatomic, strong) EMSAdvancedSearch *advancedSearch;

@property(nonatomic, strong) IBOutlet UISearchBar *search;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *advancedSearchButton;

@property(nonatomic, strong) IBOutlet UIView *footer;
@property(nonatomic, strong) IBOutlet UILabel *footerLabel;

@property(weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (strong, nonatomic) EMSSessionCell *sizingCell;

@property(nonatomic) BOOL retrieveStartedByUser;

@property(nonatomic) BOOL shouldReloadOnScrollDidEnd;

- (IBAction)toggleFavourite:(id)sender;

- (IBAction)segmentChanged:(id)sender;

- (IBAction)scrollToNow:(id)sender;

- (IBAction)backToMainViewController:(UIStoryboardSegue *)segue;

@property BOOL observersInstalled;

@end

@implementation EMSMainViewController

#pragma mark - Convenience methods

- (NSAttributedString *)titleForRefreshControl {
    NSDate *lastUpdate = [[EMSRetriever sharedInstance] lastUpdatedActiveConference];
    if (lastUpdate != nil) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        dateFormatter.doesRelativeDateFormatting = YES;
        NSAttributedString *title = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Last updated: %@", @"Last updated: {last updated}"), [dateFormatter stringFromDate:lastUpdate]]];
        return title;
    } else {
        NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Refresh available sessions", @"Title for session list refresh control.")];
        return title;
    }
}

- (void)setUpRefreshControl {
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];

    refreshControl.tintColor = [UIColor grayColor];
    refreshControl.attributedTitle = [self titleForRefreshControl];
    refreshControl.backgroundColor = self.tableView.backgroundColor;
    [refreshControl addTarget:self action:@selector(refreshControlPulled:) forControlEvents:UIControlEventValueChanged];

    self.refreshControl = refreshControl;
}

- (void) refreshControlPulled:(id) sender {
    self.retrieveStartedByUser = YES;
    [self retrieve];
}

- (void)updateRefreshControl {
    UIRefreshControl *refreshControl = self.refreshControl;
    if ([EMSRetriever sharedInstance].refreshingSessions) {

        refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Refreshing sessions...", @"Refreshing available sessions")];
        [refreshControl beginRefreshing];
        
        if ([self.fetchedResultsController.fetchedObjects count] == 0 && !self.retrieveStartedByUser) {
            CGRect rect = [refreshControl convertRect:refreshControl.frame fromView:self.tableView];
            [self.tableView scrollRectToVisible:rect animated:YES];
        }
        
    } else {
        [refreshControl endRefreshing];
        refreshControl.attributedTitle = [self titleForRefreshControl];
    }
    
    self.retrieveStartedByUser = NO;

}

- (void)initializeFooter {
    if ([[self.fetchedResultsController sections] count] == 0) {
        self.footerLabel.text = NSLocalizedString(@"No sessions.", @"Message in main session list when no sessions is found for current search.");
        self.footer.hidden = NO;
    } else {
        self.footer.hidden = YES;
    }
}

- (void)initializeFetchedResultsController {
    [self setDefaultTypeSearch];

    [self.fetchedResultsController.fetchRequest setPredicate:[self currentConferencePredicate]];

    NSError *error;

    if (![[self fetchedResultsController] performFetch:&error]) {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                initWithTitle:NSLocalizedString(@"Unable to connect view to data store", @"Error dialog connection to database - Title")
                      message:NSLocalizedString(@"The data store did something unexpected and without it this application has no data to show. This is not an error we can recover from - please exit using the home button.", @"Error dialog connecting to database - Description")
                     delegate:nil
            cancelButtonTitle:NSLocalizedString(@"OK", @"Error dialog dismiss button.")
            otherButtonTitles:nil];
        [errorAlert show];

        DDLogError(@"Unresolved error %@, %@", error, [error userInfo]);
    }

    [self initializeFooter];
    [self.tableView reloadData];
}

- (NSPredicate *)currentConferencePredicate {
    Conference *activeConference = [[EMSRetriever sharedInstance] activeConference];

    if (activeConference != nil) {
        NSMutableArray *predicates = [[NSMutableArray alloc] init];

        [predicates
                addObject:[NSPredicate predicateWithFormat:@"((state == %@) AND (conference == %@))",
                                                           @"approved",
                                                           activeConference]];

        if (!([[self.advancedSearch search] isEqualToString:@""])) {
            [predicates
                    addObject:[NSPredicate predicateWithFormat:@"(title CONTAINS[cd] %@ OR body CONTAINS[cd] %@ OR summary CONTAINS[cd] %@ OR ANY speakers.name CONTAINS[cd] %@)",
                                                               [self.advancedSearch search],
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
                NSString *keyword = (NSString *) obj;

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
                NSString *language = (NSString *) obj;

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

        if (self.filterFavourites) {
            [predicates
                    addObject:[NSPredicate predicateWithFormat:@"favourite = %@", @YES]];
        }


        NSPredicate *resultPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];

        if ([EMSFeatureConfig isCrashlyticsEnabled]) {
            [Crashlytics setObjectValue:resultPredicate forKey:@"activePredicate"];
        }

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

    NSSortDescriptor *sortSlot = [[NSSortDescriptor alloc]
            initWithKey:@"slotName" ascending:YES];
    NSSortDescriptor *sortRoom = [[NSSortDescriptor alloc]
            initWithKey:@"room.name" ascending:YES];
    NSSortDescriptor *sortTime = [[NSSortDescriptor alloc]
            initWithKey:@"slot.start" ascending:YES];
    NSSortDescriptor *sortTitle = [[NSSortDescriptor alloc]
            initWithKey:@"title" ascending:YES];

    [fetchRequest setSortDescriptors:@[sortSlot, sortRoom, sortTime, sortTitle]];
    [fetchRequest setFetchBatchSize:20];

    NSFetchedResultsController *theFetchedResultsController =
            [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                managedObjectContext:managedObjectContext sectionNameKeyPath:@"sectionTitle"
                                                           cacheName:nil];

    self.fetchedResultsController = theFetchedResultsController;

    _fetchedResultsController.delegate = self;

    return _fetchedResultsController;
}

- (void)setDefaultTypeSearch {
    Conference *conference = [[EMSRetriever sharedInstance] activeConference];

    if (conference) {
        if ([[self.advancedSearch fieldValuesForKey:emsType] count] == 0) {
            NSArray *types = [self typesForConference:conference];

            NSMutableSet *typeNames = [[NSMutableSet alloc] init];

            [types enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSString *type = (NSString *) obj;

                if (![type isEqualToString:@"workshop"]) {
                    [typeNames addObject:type];
                }
            }];

            [self.advancedSearch setFieldValues:typeNames forKey:emsType];
        }
    }
}

#pragma  mark - Lifecycle Events

- (void)awakeFromNib {
    [super awakeFromNib];
    if (self.splitViewController) {
        self.splitViewController.delegate = self;
        self.clearsSelectionOnViewWillAppear = NO;
    }
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Sessions", @"Session list title");

    self.settingsButton.accessibilityLabel = NSLocalizedString(@"Settings", @"Accessibility label for settings button");

    self.filterFavourites = NO;

    self.advancedSearch = [[EMSAdvancedSearch alloc] init];

    self.search.text = [self.advancedSearch search];

    self.retrieveStartedByUser = NO;
    
    [self setUpRefreshControl];

    // All sections start with the same year name - so the index is meaningless.
    // Can't turn it off - so let's have it only if we have at least 500 sections :)
    // This is also set in the storyboard but appears not to work.
    self.tableView.sectionIndexMinimumDisplayRowCount = 500;

    self.observersInstalled = NO;
    
    [self updateTableViewRowHeight];
    

    Conference *conference = [[EMSRetriever sharedInstance] activeConference];
    
    if (conference) {
        DDLogVerbose(@"Conference found - initialize");
        
        [self initializeFetchedResultsController];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRequested:) name:EMSUserRequestedSessionNotification object:[EMSLocalNotificationManager sharedInstance]];
    
    if ([[self.fetchedResultsController fetchedObjects] count] == 0) {
        [self retrieve];
    }

}

static void *kRefreshActiveConferenceContext = &kRefreshActiveConferenceContext;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (!self.splitViewController) {
       [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow]  animated:YES];
    }
    
    [self addObservers];
    
    
}


- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    [EMSTracking trackScreen:@"Main Screen"];

    [self updateRefreshControl];

    [self initializeFooter];
    
    // In case text size was changed while we were gone. 
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self removeObservers];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Key Value Observing

- (void)addObservers {
    if (!self.observersInstalled) {
        [[EMSRetriever sharedInstance] addObserver:self forKeyPath:NSStringFromSelector(@selector(refreshingSessions)) options:0 context:kRefreshActiveConferenceContext];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableViewRowHeightReload) name:UIContentSizeCategoryDidChangeNotification object:nil];
       
        [self updateTableViewRowHeight];

        self.observersInstalled = YES;
    }
}

- (void)removeObservers {
    if (self.observersInstalled) {
        [[EMSRetriever sharedInstance] removeObserver:self forKeyPath:NSStringFromSelector(@selector(refreshingSessions))];

        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
        self.observersInstalled = NO;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == kRefreshActiveConferenceContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateRefreshControl];

            if (![EMSRetriever sharedInstance].refreshingSessions) {
                if ([[EMSRetriever sharedInstance] activeConference]) {
                    
                    if (!self.tableView.isDragging && !self.tableView.isDecelerating) {
                        [self initializeFetchedResultsController];
                    } else {
                        self.shouldReloadOnScrollDidEnd = YES;
                    }
                }
            }
        });
    }
}


#pragma mark - Storyboard Segues

- (NSArray *)typesForConference:(Conference *)conference {
    NSMutableArray *types = [[NSMutableArray alloc] init];

    [conference.conferenceTypes enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        ConferenceType *type = (ConferenceType *) obj;

        [types addObject:type.name];
    }];

    return [NSArray arrayWithArray:types];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [self.search setShowsCancelButton:NO animated:YES];
    [self.search resignFirstResponder];

    if ([[segue identifier] isEqualToString:@"showDetailsView"]) {
        UIViewController *tmpDestination = [segue destinationViewController];
        if ([tmpDestination isKindOfClass:[UINavigationController class]]) {
            tmpDestination = tmpDestination.childViewControllers[0];
        }

        EMSDetailViewController *destination = (EMSDetailViewController *) tmpDestination;
        
        Session *session = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];

        DDLogVerbose(@"Preparing detail view with %@", session);
        
        destination.session = session;
        
        if ([EMSFeatureConfig isCrashlyticsEnabled]) {
            [Crashlytics setObjectValue:session.href forKey:@"lastDetailSession"];
        }
        
        [EMSTracking trackEventWithCategory:@"listView" action:@"detail" label:session.href];
        
    }

    if ([[segue identifier] isEqualToString:@"showSearchView"]) {
        UINavigationController *navigationController = [segue destinationViewController];
        EMSSearchViewController *destination = (EMSSearchViewController *) navigationController.childViewControllers[0];

        Conference *conference = [[EMSRetriever sharedInstance] activeConference];
        DDLogVerbose(@"Preparing search view with %@ and conference %@", self.search.text, conference);

        destination.advancedSearch = self.advancedSearch;

        NSMutableArray *levels = [[NSMutableArray alloc] init];

        [conference.conferenceLevels enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            ConferenceLevel *level = (ConferenceLevel *) obj;

            [levels addObject:level.name];
        }];

        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"EMS-Config" ofType:@"plist"];
        NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:filePath];
        NSDictionary *sort = prefs[@"level-sort"];

        destination.levels = [levels sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSNumber *firstKey = [sort valueForKey:obj1];
            NSNumber *secondKey = [sort valueForKey:obj2];

            if ([firstKey integerValue] > [secondKey integerValue]) {
                return (NSComparisonResult) NSOrderedDescending;
            }

            if ([firstKey integerValue] < [secondKey integerValue]) {
                return (NSComparisonResult) NSOrderedAscending;
            }
            return (NSComparisonResult) NSOrderedSame;
        }];

        NSMutableArray *keywords = [[NSMutableArray alloc] init];

        [conference.conferenceKeywords enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            ConferenceKeyword *keyword = (ConferenceKeyword *) obj;

            [keywords addObject:keyword.name];
        }];

        destination.keywords = [keywords sortedArrayUsingSelector:@selector(compare:)];

        NSMutableArray *rooms = [[NSMutableArray alloc] init];

        [conference.rooms enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            Room *room = (Room *) obj;

            [rooms addObject:room.name];
        }];

        destination.rooms = [rooms sortedArrayUsingSelector:@selector(compare:)];

        NSArray *types = [self typesForConference:conference];

        destination.types = [types sortedArrayUsingSelector:@selector(compare:)];

        destination.delegate = self;

        [EMSTracking trackEventWithCategory:@"listView" action:@"search" label:nil];
    }
}


- (IBAction)backToMainViewController:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"unwindSettingsSegue"]) {
        self.advancedSearch = [[EMSAdvancedSearch alloc] init];

        self.search.text = [self.advancedSearch search];

        [self initializeFetchedResultsController];
        [self dismissViewControllerAnimated:YES completion:^{            
            if ([[self.fetchedResultsController fetchedObjects] count] == 0) {
                [self retrieve];
            }
        }];
        
        
    }
}


#pragma mark - Table view data source


- (void)updateTableViewRowHeightReload {
    [self updateTableViewRowHeight];
    
    [self.tableView reloadData];

}

- (void)updateTableViewRowHeight {
    if (!self.sizingCell) {
        self.sizingCell = [self.tableView dequeueReusableCellWithIdentifier:@"SessionCell"];
    }
    EMSSessionCell *sessionCell = self.sizingCell;

    sessionCell.title.text = @"We want it to always be the size of two lines, so we put in a really long title before we calculate size.";
    sessionCell.room.text = @"Room";
    sessionCell.speaker.text = @"Speakers";

    sessionCell.title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    sessionCell.room.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    sessionCell.speaker.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];


    sessionCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(sessionCell.bounds));

    [sessionCell setNeedsLayout];
    [sessionCell layoutIfNeeded];


    CGFloat height = [sessionCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;

    self.tableView.rowHeight = height + 1;

    
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger count = [[_fetchedResultsController sections] count];

    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id sectionInfo = [_fetchedResultsController sections][(NSUInteger) section];

    NSUInteger count = [sectionInfo numberOfObjects];

    return count;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Session *session = [_fetchedResultsController objectAtIndexPath:indexPath];

    EMSSessionCell *sessionCell = (EMSSessionCell *) cell;

    sessionCell.title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    sessionCell.room.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    sessionCell.speaker.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    [sessionCell setNeedsLayout];
    [sessionCell layoutIfNeeded];

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

    [level setImage:[UIImage imageNamed:session.level]];

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

    NSMutableArray *speakerNames = [[NSMutableArray alloc] init];

    [session.speakers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        Speaker *speaker = (Speaker *) obj;

        [speakerNames addObject:speaker.name];
    }];

    sessionCell.speaker.text = [speakerNames componentsJoinedByString:@", "];


    sessionCell.title.accessibilityLanguage = session.language;

    sessionCell.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"%@, Location: %@, Speakers: %@", @"{Session title}, Location: {Session Location}, Speakers: {Session speakers}"),
                                                                sessionCell.title.text, sessionCell.room.text, sessionCell.speaker.text];
    sessionCell.accessibilityLanguage = session.language;

    sessionCell.session = session;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SessionCell" forIndexPath:indexPath];

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [_fetchedResultsController sections][(NSUInteger) section];
    return [sectionInfo name];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [_fetchedResultsController sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [_fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

#pragma mark - UITableViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate && self.shouldReloadOnScrollDidEnd) {
        [self initializeFetchedResultsController];
        self.shouldReloadOnScrollDidEnd = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.shouldReloadOnScrollDidEnd) {
        [self initializeFetchedResultsController];
        self.shouldReloadOnScrollDidEnd = NO;
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
    [self initializeFooter];
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}


#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText length] == 0) {
        [self performSelector:@selector(hideKeyboardWithSearchBar:) withObject:searchBar afterDelay:0];
    }

    [self storeSearchPrefs];

    [self initializeFetchedResultsController];
}

- (void)hideKeyboardWithSearchBar:(UISearchBar *)searchBar {
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


#pragma mark - EMSSearchViewDelegate

- (void)advancedSearchUpdated {
    // Need to reload
    self.advancedSearch = [[EMSAdvancedSearch alloc] init];

    self.search.text = [self.advancedSearch search];

    [self initializeFetchedResultsController];

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Actions

- (void)storeSearchPrefs {
    [self.advancedSearch setSearch:self.search.text];
}

- (void)retrieve {    
    [[EMSRetriever sharedInstance] refreshActiveConference];
}

- (void)toggleFavourite:(id)sender {
    UIButton *button = (UIButton *) sender;

    UIView *view = [button superview];

    while (view != nil) {
        if ([view isKindOfClass:[EMSSessionCell class]]) {
            EMSSessionCell *cell = (EMSSessionCell *) view;

            Session *session = cell.session;

            [[[EMSAppDelegate sharedAppDelegate] model] toggleFavourite:session];

            break;
        }

        view = [view superview];
    }
}

- (void)segmentChanged:(id)sender {
    

    UISegmentedControl *segment = (UISegmentedControl *) sender;

    switch ([segment selectedSegmentIndex]) {
        case 0: {
            // All
            [EMSTracking trackEventWithCategory:@"listView" action:@"all" label:nil];
            self.filterFavourites = NO;
            break;
        }
        case 1: {
            // My
            [EMSTracking trackEventWithCategory:@"listView" action:@"favourites" label:nil];
            self.filterFavourites = YES;
            break;
        }

        default:
            break;
    }

    [self initializeFetchedResultsController];
}

- (IBAction)scrollToNow:(id)sender {

    Conference *conference = [[EMSRetriever sharedInstance] activeConference];
    if (!conference) {
        return;
    }

    NSArray *sections = [self.fetchedResultsController sections];

    if ([sections count] == 0) {
        return;
    }

    NSMutableArray *mappedObjects = [NSMutableArray array];

    for (id <NSFetchedResultsSectionInfo> sectionInfo in sections) {
        if ([sectionInfo numberOfObjects] > 0) {
            Session *session = [sectionInfo objects].firstObject;
            if (session != nil && session.slot != nil) {
                [mappedObjects addObject:session.slot.end];
            } else {
                [mappedObjects addObject:[NSDate distantFuture]];
            }
        }
    }

    NSDate *now = [[[EMSAppDelegate sharedAppDelegate] model] dateForConference:conference andDate:[NSDate date]];

    if (now != nil) {
        NSInteger index = [self getIndexForDate:now inListOfDates:mappedObjects];

        if (index != NSNotFound) {
            if (index >= [sections count]) {//scroll to end
                index = [sections count] - 1;
            }

            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:index];

            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];

        }
    }
}

- (NSInteger)getIndexForDate:(NSDate *)now inListOfDates:(NSArray *)dates {
    NSRange range = NSMakeRange(0, [dates count]);

    NSArray *sortedDates = [dates sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];

    NSInteger index = [sortedDates indexOfObject:now inSortedRange:range options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];

    return index;
}


#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation {
    return NO;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[EMSDetailViewController class]] && ([(EMSDetailViewController *)[(UINavigationController *)secondaryViewController topViewController] session] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Responding to user opening sessions from notifications


- (void) sessionRequested:(NSNotification *) notification {
    NSDictionary *userInfo = [notification userInfo];

    DDLogVerbose(@"Starting with a notification with userInfo %@", userInfo);
    
    NSString *sessionUrl = userInfo[EMSUserRequestedSessionNotificationSessionKey];
    
    if (sessionUrl) {
        
        if ([EMSFeatureConfig isCrashlyticsEnabled]) {
            [Crashlytics setObjectValue:sessionUrl forKey:@"lastDetailSessionFromNotification"];
        }
        
        
        [EMSTracking trackEventWithCategory:@"listView" action:@"detailFromNotification" label:sessionUrl];
        
        
        Session *session = [[[EMSAppDelegate sharedAppDelegate] model] sessionForHref:sessionUrl];
        
        if (session) {//If we don´t find session, assume database have been deleted together with favorite, so don´t show alert.

            DDLogVerbose(@"Preparing detail view from passed href %@", session);

            EMSDetailViewController *detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EMSDetailViewController"];
            
            detailViewController.session = session;
            
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
            navController.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
            
            detailViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissModalDetailView:)];
            
            if (self.splitViewController) {
                navController.modalPresentationStyle = UIModalPresentationFormSheet;
            }
            
            if (self.presentedViewController) {
                [self dismissViewControllerAnimated:YES completion:^{
                    [self presentViewController:navController animated:YES completion:nil];
                }];
            } else {
                [self presentViewController:navController animated:YES completion:nil];
            }
            
        }
        
    }
}

- (void) dismissModalDetailView:(id) sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - State restoration

static NSString *const EMSMainViewControllerRestorationIdentifierSegmentControlIndex = @"EMSMainViewControllerRestorationIdentifierSegmentControlIndex";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeInteger:self.segmentedControl.selectedSegmentIndex forKey:EMSMainViewControllerRestorationIdentifierSegmentControlIndex];
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    NSInteger selectedIndex = [coder decodeIntegerForKey:EMSMainViewControllerRestorationIdentifierSegmentControlIndex];
    
    self.segmentedControl.selectedSegmentIndex = selectedIndex;
    
    if (selectedIndex == 1) {
        self.filterFavourites = YES;
    }
    
    [self initializeFetchedResultsController];
    
}

#pragma mark - UIDataSourceModelAssociation

-(NSString *)modelIdentifierForElementAtIndexPath:(NSIndexPath *)idx inView:(UIView *)view {
    NSString *sessionHref = nil;
    if ([view isEqual:self.tableView]) {
        
        Session *session = [self.fetchedResultsController objectAtIndexPath:idx];
        sessionHref =  session.href;
    }
    return sessionHref;
}

-(NSIndexPath *)indexPathForElementWithModelIdentifier:(NSString *)identifier inView:(UIView *)view {
    NSIndexPath *indexPath = nil;
    if ([view isEqual:self.tableView]) {
        Session *session = [[[EMSAppDelegate sharedAppDelegate] model] sessionForHref:identifier];
        if (session) {
            indexPath = [self.fetchedResultsController indexPathForObject:session];
        }
    }
    return indexPath;
}

@end
