//
//  EMSDetailViewController.m
//

#import <CommonCrypto/CommonDigest.h>
#import <EventKit/EventKit.h>

#import "EMS-Swift.h"

#import "EMSDetailViewController.h"

#import "EMSAppDelegate.h"

#import "EMSRetriever.h"

#import "EMSDetailViewRow.h"

#import "NHCalendarActivity.h"

#import "EMSTopAlignCellTableViewCell.h"

#import "EMSTracking.h"

#import "EMSSessionTitleTableViewCell.h"
#import "EMSSpeakersRetriever.h"

#import "EMSFeatureConfig.h"
#import "EMSConfig.h"

#import "NSDate+EMSExtensions.h"

#import <SafariServices/SafariServices.h>

#import "EMS-Bridging-Header.h"

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@interface EMSDetailViewController () <EMSSpeakersRetrieverDelegate, UITableViewDataSource, UITableViewDelegate>

@property(nonatomic) NSArray *parts;

@property(nonatomic, strong) NSDictionary *cachedSpeakerBios;

@property(nonatomic, weak) IBOutlet UIBarButtonItem *shareButton;

@property(nonatomic, strong) EMSSpeakersRetriever *speakerRetriever;

@property(nonatomic) BOOL observersInstalled;

@property(nonatomic) BOOL shouldReloadOnScrollDidEnd;

@property(nonatomic) BOOL shouldRefreshThumbnail;

@property(nonatomic, copy) NSArray *keywords;

@property(nonatomic, copy) NSArray* actions;

- (IBAction)share:(id)sender;

@end

typedef NS_ENUM(NSUInteger, EMSDetailViewControllerSection) {
    EMSDetailViewControllerSectionInfo,
    EmsDetailViewControllerSectionCategories,
    EmsDetailViewControllerSectionDescription,
    EMSDetailViewControllerSectionLegacy,
    EmsDetailViewControllerSectionActions
};

@implementation EMSDetailViewController

#pragma mark - Initialization Convenience

- (void)setupWithSession:(Session *)session {
    if (session) {

        if (self.observersInstalled) {
            [self.session removeObserver:self forKeyPath:@"favourite"];
        }

        self.session = session;

        if (self.observersInstalled) {
            [self.session addObserver:self forKeyPath:@"favourite" options:0 context:nil];
        }

        [self initSpeakerCache:session];

        [self setupPartsWithThumbnailRefresh:YES];

        [self retrieve];

        self.shareButton.enabled = YES;

    }
}

+ (NSString *)createControllerTitle:(Session *)session {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];


    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];

    [timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [timeFormatter setTimeStyle:NSDateFormatterShortStyle];

    NSMutableString *title = [[NSMutableString alloc] init];

    if (session.slot) {
        [title appendString:[NSString stringWithFormat:@"%@ %@ - %@",
                                                       [dateFormatter stringFromDate:session.slot.start],
                                                       [timeFormatter stringFromDate:session.slot.start],
                                                       [timeFormatter stringFromDate:session.slot.end]]];
    } else {
        if (session.slotName != nil) {
            [title appendString:session.slotName];
        }
    }

    if (session.roomName != nil) {
        [title appendString:[NSString stringWithFormat:@" : %@", session.roomName]];
    }
    return [title copy];
}

+ (NSString *)createControllerAccessibilityTitle:(Session *)session {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];


    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];

    [timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [timeFormatter setTimeStyle:NSDateFormatterShortStyle];

    NSMutableString *title = [[NSMutableString alloc] init];

    if (session.slot) {
        [title appendString:[NSString stringWithFormat:NSLocalizedString(@"%@ at %@ to %@", @"{Session date} at {Session start time} to {Session end time}"),
                                                       [dateFormatter stringFromDate:session.slot.start],
                                                       [timeFormatter stringFromDate:session.slot.start],
                                                       [timeFormatter stringFromDate:session.slot.end]]];
    } else {
        if (session.slotName != nil) {
            [title appendString:session.slotName];
        }
    }

    if (session.roomName != nil) {
        [title appendString:[NSString stringWithFormat:NSLocalizedString(@" in %@", @" in {Room name}"), session.roomName]];
    }
    return [title copy];
}

- (void)initSpeakerCache:(Session *)session {
    NSMutableDictionary *speakerBios = [[NSMutableDictionary alloc] init];

    for (Speaker *speaker in session.speakers) {
        if (speaker.bio != nil) {
            speakerBios[speaker.name] = speaker.bio;
        } else {
            speakerBios[speaker.name] = @"";
        }
    }

    self.cachedSpeakerBios = [NSDictionary dictionaryWithDictionary:speakerBios];
}

- (void)setupPartsWithThumbnailRefresh:(BOOL) thumbnailRefresh {

    NSMutableArray *mutableActions = [NSMutableArray array];
    if ([EMSFeatureConfig isFeatureEnabled:fLinks]) {
        if (self.session.videoLink) {
            typeof(self) __weak weakSelf = self;
            ActionTableViewCellAction *rowAction = [[ActionTableViewCellAction alloc] initWithTitle:NSLocalizedString(@"Video", @"Title for video button in detail view") handler:^() {
                
                typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }
                
                [EMSTracking trackEventWithCategory:@"web" action:@"open link" label:strongSelf.session.videoLink];
                
                NSURL *videoURL = [NSURL URLWithString:strongSelf.session.videoLink];
                SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:videoURL];

                safariViewController.view.tintColor = strongSelf.tableView.tintColor;
                
                [strongSelf presentViewController:safariViewController animated:YES completion:nil];
            }];
        
            [mutableActions addObject:rowAction];
        }
    }
    
    if (EMSFeatureConfig.isRatingEnabled && [self ratingAvailableForDate:self.session.slot.end]) {
        typeof(self) __weak weakSelf = self;
        ActionTableViewCellAction *ratingAction = [[ActionTableViewCellAction alloc] initWithTitle:NSLocalizedString(@"Leave feedback", @"Title for rate session action in detail view") handler:^{
            typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf performSegueWithIdentifier:@"PresentRatingSegue" sender:strongSelf];
        }];
        
        [mutableActions addObject:ratingAction];
    }
    
    self.actions = mutableActions;

    NSArray *sortedKeywords = [self.session.keywords.allObjects sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSString *first = [(Keyword *) a name];
        NSString *second = [(Keyword *) b name];

        return [first compare:second];
    }];
    
    self.keywords = [sortedKeywords mutableCopy];
    
    
    NSMutableArray *p = [[NSMutableArray alloc] init];

    [self.session.speakers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        Speaker *speaker = (Speaker *) obj;

        EMSDetailViewRow *row = [[EMSDetailViewRow alloc] initWithContent:speaker.name];

        if ([EMSFeatureConfig isFeatureEnabled:fBioPics]) {
            if (speaker.thumbnailUrl != nil) {
                DDLogVerbose(@"Speaker has available thumbnail %@", speaker.thumbnailUrl);

                NSString *pngFilePath = [self pathForCachedThumbnail:speaker];

                UIImage *img = [UIImage imageWithContentsOfFile:pngFilePath];

                row.image = img;

                if (thumbnailRefresh) {
                    [self checkForNewThumbnailForSpeaker:speaker withFilename:pngFilePath forSessionHref:self.session.href];
                }
            }
        }

        NSString *bio = self.cachedSpeakerBios[speaker.name];

        //if (bio && ![bio isEqualToString:@""]) {
            row.body = bio;
        //}

        [p addObject:row];
    }];

    self.parts = [NSArray arrayWithArray:p];

    [self.tableView reloadData];
}

#pragma mark - Lifecycle

- (void)addObservers {
    if (!self.observersInstalled) {
        [self.session addObserver:self forKeyPath:@"favourite" options:0 context:NULL];

        self.observersInstalled = YES;
    }
}

- (void)removeObservers {
    if (self.observersInstalled) {
        [self.session removeObserver:self forKeyPath:@"favourite"];

        self.observersInstalled = NO;
    }

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.session] && [keyPath isEqual:@"favourite"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}

- (void)viewDidLoad {
    //self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 100;
   
   


    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    self.observersInstalled = NO;

    [self setupWithSession:self.session];
    
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self addObservers];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    

    [EMSTracking trackScreen:@"Detail Screen"];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PresentRatingSegue"]) {
        Rating *rating = [[[EMSAppDelegate sharedAppDelegate] model] ratingForSession:self.session];
        
        RatingViewController *destination = (RatingViewController *)((UINavigationController *)segue.destinationViewController).topViewController;
        
        destination.rating = rating;
    }
}

- (IBAction)unwindToDetailViewController:(UIStoryboardSegue *)unwindSegue {
    RatingViewController *ratingController = unwindSegue.sourceViewController;
    
    if ([unwindSegue.identifier isEqualToString:@"SaveRatingSegue"]) {
        [[[EMSAppDelegate sharedAppDelegate] model] setRatingOverall:[(NSNumber *)ratingController.sections[0][@"rating"] intValue]
                                                             content:[(NSNumber *)ratingController.sections[2][@"rating"] intValue]
                                                             quality:[(NSNumber *)ratingController.sections[3][@"rating"] intValue]
                                                           relevance:[(NSNumber *)ratingController.sections[1][@"rating"] intValue]
                                                            comments:ratingController.comments
                                                          forSession:self.session
                                                               error:nil];
        
        RatingApi *api = [[RatingApi alloc] initWithServer:[[EMSConfig ratingUrl] absoluteString]];
        [api postRating:self.session rating:[[[EMSAppDelegate sharedAppDelegate] model] ratingForSession:self.session]];
    }
}

#pragma mark - Calendar

- (NHCalendarEvent *)createCalendarEvent {
    NHCalendarEvent *calendarEvent = [[NHCalendarEvent alloc] init];

    calendarEvent.title = [NSString stringWithFormat:@"%@ - %@", self.session.conference.name, self.session.title];
    calendarEvent.location = self.session.room.name;
    calendarEvent.notes = [self buildCalendarNotes];
    calendarEvent.startDate = [self dateForDate:self.session.slot.start];
    calendarEvent.endDate = [self dateForDate:self.session.slot.end];
    calendarEvent.allDay = NO;

    // Add alarm
    NSArray *alarms = @[[EKAlarm alarmWithRelativeOffset:-60.0f * 5.0f]];

    calendarEvent.alarms = alarms;

    DDLogVerbose(@"Created calendar event %@", calendarEvent);

    return calendarEvent;
}

- (NSString *)buildCalendarNotes {
    NSMutableString *result = [[NSMutableString alloc] init];

    [result appendString:@"Details\n\n"];
    [result appendString:self.session.body];

    [result appendString:@"\n\nInformation\n\n"];
    [result appendFormat:@"* %@\n\n", [[@[[self cleanString:self.session.level]] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@"\n* "]];

    if (self.session.keywords != nil && [self.session.keywords count] > 0) {
        [result appendString:@"\n\nKeywords\n\n"];

        NSMutableArray *listItems = [[NSMutableArray alloc] init];

        [self.session.keywords enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            Keyword *keyword = (Keyword *) obj;

            [listItems addObject:keyword.name];
        }];

        [result appendFormat:@"* %@\n\n", [[listItems sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@"\n* "]];
    }

    if ([self.session.speakers count] > 0) {
        [result appendString:@"\n\nSpeakers\n\n"];

        [self.session.speakers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            Speaker *speaker = (Speaker *) obj;

            if (speaker.name != nil) {
                [result appendString:speaker.name];
            }

            NSString *bio = self.cachedSpeakerBios[speaker.name];
            if (bio && ![bio isEqualToString:@""]) {
                [result appendString:@"\n\n"];
                [result appendString:bio];
            }
            [result appendString:@"\n\n"];
        }];
    }

    return [NSString stringWithString:result];
}


#pragma mark - Convenience

- (NSString *)md5:(NSString *)input {
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG) strlen(cStr), digest); // This is the md5 call

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];

    return output;
}

- (NSString *)cleanString:(NSString *)value {
    if (value == nil) {
        return @"";
    }
    return [[value capitalizedString] stringByReplacingOccurrencesOfString:@"-" withString:@" "];
}

- (NSDate *)dateForDate:(NSDate *)date {
    return [NSDate dateForDate:date fromDate:[[NSDate alloc] init]];
}

#pragma mark - Actions

- (IBAction)toggleFavourite:(id)sender {
    [[[EMSAppDelegate sharedAppDelegate] model] toggleFavourite:self.session];
}

- (void)share:(id)sender {
    self.shareButton.enabled = NO;

    if ([EMSFeatureConfig isCrashlyticsEnabled]) {
        [[Crashlytics sharedInstance] setObjectValue:self.session.href forKey:@"lastSharedSession"];
    }

    NSString *shareString = [NSString stringWithFormat:@"%@ - %@", self.session.conference.name, self.session.title];
    DDLogVerbose(@"About to share for %@", shareString);

    NSMutableArray *shareItems = [[NSMutableArray alloc] init];
    NSMutableArray *shareActivities = [[NSMutableArray alloc] init];

    [shareItems addObject:shareString];

    if (self.session.slot) {
        [shareItems addObject:[self createCalendarEvent]];
        [shareActivities addObject:[[NHCalendarActivity alloc] init]];
    }

    if (self.session.link) {
        [shareItems addObject:self.session.link];
    }
    
    if (self.session.videoLink) {
        [shareItems addObject:self.session.videoLink];
    }

    NSArray *activityItems = [NSArray arrayWithArray:shareItems];
    NSArray *activities = [NSArray arrayWithArray:shareActivities];

    __block UIActivityViewController *activityViewController = [[UIActivityViewController alloc]
            initWithActivityItems:activityItems
            applicationActivities:activities];

    activityViewController.excludedActivityTypes = @[UIActivityTypePrint,
            UIActivityTypeCopyToPasteboard,
            UIActivityTypeAssignToContact,
            UIActivityTypeSaveToCameraRoll];
    
    
    activityViewController.popoverPresentationController.barButtonItem = self.shareButton;
    
    [activityViewController setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        DDLogVerbose(@"Sharing of %@ via %@ - completed %d", shareString, activityType, completed);

        self.shareButton.enabled = YES;
        
        if (completed) {
            [EMSTracking trackSocialWithNetwork:activityType action:@"Share" target:self.session.href];
        }

        if (activityError != nil) {
            [EMSTracking trackException:[NSString stringWithFormat:@"Unable to share with Code: %ld, Domain: %@, Info: %@", (long)activityError.code, activityError.domain, activityError.userInfo]];
        }
    }];

    [self presentViewController:activityViewController animated:YES completion:nil];

}

- (BOOL)ratingAvailableForDate:(NSDate *)date {
    
    if (date == nil) {
        return NO;
    }
    
    // checkDate is 5 min before end of session
    NSDate *checkDate = [[self dateForDate:date] dateByAddingTimeInterval:(-5 * 60)];
    
    if ([[NSDate date] compare:checkDate] == NSOrderedDescending) {
        return YES;
    }
    
    return NO;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;

    if (section == EMSDetailViewControllerSectionInfo) {
        rows = 1;
    } else if (section == EmsDetailViewControllerSectionCategories) {
        rows = 1;
    } else if (section == EmsDetailViewControllerSectionDescription) {
        rows = 1;
    } else if (section == EMSDetailViewControllerSectionLegacy) {
        rows = [self.parts count];
    } else if (section == EmsDetailViewControllerSectionActions) {
        rows = [self.actions count];
    }

    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = nil;

    if (indexPath.section == EMSDetailViewControllerSectionInfo) {
        EMSSessionTitleTableViewCell *titleCell = [self.tableView dequeueReusableCellWithIdentifier:@"SessionTitleTableViewCell" forIndexPath:indexPath];
        cell = [self configureTitleCell:titleCell forIndexPath:indexPath];
    } else if (indexPath.section == EmsDetailViewControllerSectionCategories) {
        CategoriesTableViewCell *categoriesCell = [self.tableView dequeueReusableCellWithIdentifier:@"CategoriesCell"];
        categoriesCell.categories = self.keywords;
        categoriesCell.level = self.session.level;
        cell= categoriesCell;
    } else if (indexPath.section == EmsDetailViewControllerSectionDescription) {
        EmsDescriptionTableViewCell *descriptionCell = [self.tableView dequeueReusableCellWithIdentifier:@"DescriptionCell" forIndexPath:indexPath];
        descriptionCell.session = self.session;
        cell = descriptionCell;
    } else if (indexPath.section == EMSDetailViewControllerSectionLegacy) {
        EMSDetailViewRow *row = self.parts[(NSUInteger) indexPath.row];

        EMSTopAlignCellTableViewCell *speakerCell = [self.tableView dequeueReusableCellWithIdentifier:@"SpeakerCell" forIndexPath:indexPath];
        cell = [self configureSpeakerCell:speakerCell forRow:row forIndexPath:indexPath];
    } else if (indexPath.section == EmsDetailViewControllerSectionActions) {
        ActionTableViewCell *actionCell = [self.tableView dequeueReusableCellWithIdentifier:@"RatingCell" forIndexPath:indexPath];
        
        ActionTableViewCellAction *action = self.actions[indexPath.row];
        actionCell.rowAction = action;
        cell = actionCell;
    }

    return cell;

}


- (EMSSessionTitleTableViewCell *) configureTitleCell:(EMSSessionTitleTableViewCell *)titleCell forIndexPath:(NSIndexPath *) indexPath {
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    titleCell.titleLabel.font = font;
    
    titleCell.titleLabel.text = self.session.title;
    titleCell.titleLabel.accessibilityLanguage = self.session.language;
    
    titleCell.timeAndRoomLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];;
    titleCell.timeAndRoomLabel.text = [EMSDetailViewController createControllerTitle:self.session];
    titleCell.timeAndRoomLabel.accessibilityLabel = [EMSDetailViewController createControllerAccessibilityTitle:self.session];
    
    [titleCell.favoriteButton setImage:[self.session.format isEqualToString:@"lightning-talk"] ? @"64-zap" : @"28-star"];

    [titleCell.favoriteButton setSelected:[self.session.favourite boolValue]];
    
    return titleCell;
}

- (UITableViewCell *) configureSpeakerCell:(EMSTopAlignCellTableViewCell *) cell forRow:(EMSDetailViewRow *)row forIndexPath:(NSIndexPath *) indexPath {
    
    cell.nameLabel.text = row.content;
    cell.nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    cell.nameLabel.accessibilityLanguage = self.session.language;
    
    cell.descriptionLabel.text = row.body;
    cell.descriptionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.descriptionLabel.accessibilityLanguage = self.session.language;
    
    cell.thumbnailView.image = row.image;
    cell.thumbnailView.layer.borderWidth = 1.0f;
    cell.thumbnailView.layer.borderColor = [UIColor grayColor].CGColor;
    cell.thumbnailView.layer.masksToBounds = NO;
    cell.thumbnailView.clipsToBounds = YES;
    cell.thumbnailView.layer.cornerRadius = CGRectGetWidth(cell.thumbnailView.frame)/2;
    
    return cell;
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == EmsDetailViewControllerSectionActions) {
        return indexPath;
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == EmsDetailViewControllerSectionActions) {
        ActionTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        ActionTableViewCellAction *rowAction = cell.rowAction;
        rowAction.handler();
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - UITableViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate && self.shouldReloadOnScrollDidEnd) {
        [self setupPartsWithThumbnailRefresh:self.shouldRefreshThumbnail];
        self.shouldReloadOnScrollDidEnd = NO;
        self.shouldRefreshThumbnail = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.shouldReloadOnScrollDidEnd) {
        [self setupPartsWithThumbnailRefresh:self.shouldRefreshThumbnail];
        self.shouldReloadOnScrollDidEnd = NO;
        self.shouldRefreshThumbnail = NO;
    }
}

#pragma mark - Load Speakers

- (void)retrieve {

    if (!self.speakerRetriever) {
        self.speakerRetriever = [[EMSSpeakersRetriever alloc] init];

        self.speakerRetriever.delegate = self;
    }


    DDLogVerbose(@"Retrieving speakers for href %@", self.session.speakerCollection);

    [self.speakerRetriever refreshSpeakers:[NSURL URLWithString:self.session.speakerCollection]];
}

- (void)finishedSpeakers:(NSArray *)speakers forHref:(NSURL *)href error:(NSError **)error {
    // Check we haven't navigated to a new session
    if ([[href absoluteString] isEqualToString:self.session.speakerCollection]) {
        __block BOOL newBios = NO;
        
        NSMutableDictionary *speakerBios = [NSMutableDictionary dictionaryWithDictionary:self.cachedSpeakerBios];
        
        [self.cachedSpeakerBios enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stopCached) {
            NSString *name = (NSString *) key;
            NSString *bio = (NSString *) obj;
            
            for (Speaker *speaker in self.session.speakers) {
                if ([speaker.name isEqualToString:name]) {
                    if (![speaker.bio isEqualToString:bio]) {
                        if (speaker.bio != nil) {
                            speakerBios[speaker.name] = speaker.bio;
                            newBios = YES;
                        }
                    }
                }
            }
        }];
        
        if (newBios) {
            DDLogVerbose(@"Saw updated bios - updating screen");
            self.cachedSpeakerBios = [NSDictionary dictionaryWithDictionary:speakerBios];
            
            if (!self.tableView.isDragging && !self.tableView.isDecelerating) {
                [self setupPartsWithThumbnailRefresh:YES];
            } else {
                self.shouldReloadOnScrollDidEnd = YES;
                self.shouldRefreshThumbnail = YES;
            }
        }
    }
}

- (void)checkForNewThumbnailForSpeaker:(Speaker *)speaker withFilename:(NSString *)pngFilePath forSessionHref:(NSString *)href {
    DDLogVerbose(@"Checking for updated thumbnail %@", speaker.thumbnailUrl);

    static NSDateFormatter *httpDateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        httpDateFormatter = [[NSDateFormatter alloc] init];
        httpDateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        httpDateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss 'GMT'";
    });

    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [sessionConfiguration setAllowsCellularAccess:YES];

    NSDate *lastModified = [[[EMSAppDelegate sharedAppDelegate] model] dateForSpeakerPic:speaker.thumbnailUrl];

    if (lastModified) {
        DDLogVerbose(@"Setting last modified to %@", lastModified);

        NSString *httpFormattedDate = [httpDateFormatter stringFromDate:lastModified];
        sessionConfiguration.HTTPAdditionalHeaders = @{@"If-Modified-Since" : httpFormattedDate};
        sessionConfiguration.URLCache = nil;
    }

    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    [[session downloadTaskWithURL:[NSURL URLWithString:speaker.thumbnailUrl] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            DDLogError(@"Failed to retrieve thumbnail %@ - %@ - %@", speaker.thumbnailUrl, error, [error userInfo]);
        } else {
            // Network is likely still up
            [EMSTracking dispatch];

            // Cast to http - safe as long as we've made a web call
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

            if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {

                NSFileManager *fileManager = [NSFileManager defaultManager];

                if ([fileManager isReadableFileAtPath:[location path]]) {
                    NSError *fileError;

                    if ([fileManager isDeletableFileAtPath:pngFilePath]) {
                        [fileManager removeItemAtPath:pngFilePath error:&fileError];

                        if (fileError != nil) {
                            DDLogError(@"Failed to delete old thumbnail %@ - %@ - %@", pngFilePath, fileError, [fileError userInfo]);

                            fileError = nil;
                        }
                    }

                    [fileManager moveItemAtPath:[location path] toPath:pngFilePath error:&fileError];

                    if (fileError != nil) {
                        DDLogError(@"Failed to copy thumbnail %@ - %@ - %@", location, fileError, [fileError userInfo]);
                    } else {
                        NSString *lastModifiedHeader = [httpResponse allHeaderFields][@"Last-Modified"];

                        if (lastModifiedHeader) {
                            __block NSDate *lastModifiedDate = [httpDateFormatter dateFromString:lastModifiedHeader];

                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[[EMSAppDelegate sharedAppDelegate] model] setDate:lastModifiedDate ForSpeakerPic:speaker.thumbnailUrl];
                            });
                        }

                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([self.session.href isEqualToString:href]) {
                                
                                if (!self.tableView.dragging && !self.tableView.decelerating) {
                                    [self setupPartsWithThumbnailRefresh:NO];
                                    
                                } else {
                                    self.shouldRefreshThumbnail = NO;
                                    self.shouldReloadOnScrollDidEnd = YES;
                                }
                            }
                        });
                    }
                }
            }
        }

        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];
}

- (NSString *)pathForCachedThumbnail:(Speaker *)speaker {
    NSString *safeFilename = [self md5:speaker.thumbnailUrl];

    return [[[[EMSAppDelegate sharedAppDelegate] applicationCacheDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", safeFilename]] path];
}

#pragma mark - State restoration

static NSString *const EMSDetailViewControllerRestorationIdentifierSessionHref = @"EMSDetailViewControllerRestorationIdentifierSessionHref";

- (void)applicationFinishedRestoringState {
    [self setupWithSession:self.session];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];

    [coder encodeObject:self.session.href forKey:EMSDetailViewControllerRestorationIdentifierSessionHref];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];


    NSString *sessionHref = [coder decodeObjectForKey:EMSDetailViewControllerRestorationIdentifierSessionHref];

    if (sessionHref) {
        Session *session = [[[EMSAppDelegate sharedAppDelegate] model] sessionForHref:sessionHref];
        
        self.session = session;
    }

}

@end
