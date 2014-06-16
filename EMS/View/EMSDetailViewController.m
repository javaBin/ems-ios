//
//  EMSDetailViewController.m
//

#import <CommonCrypto/CommonDigest.h>
#import <EventKit/EventKit.h>

#import "EMSDetailViewController.h"

#import "EMSAppDelegate.h"

#import "EMSRetriever.h"

#import "EMSFeatureConfig.h"

#import "Speaker.h"
#import "Keyword.h"
#import "Room.h"

#import "EMSDetailViewRow.h"

#import "NHCalendarActivity.h"

@interface EMSDetailViewController () <UIPopoverControllerDelegate,EMSRetrieverDelegate, UITableViewDataSource, UITableViewDelegate>

@property(nonatomic) UIPopoverController *sharePopoverController;

@property(nonatomic) NSArray *parts;

@property(nonatomic, strong) NSDictionary *cachedSpeakerBios;

@property(nonatomic, strong) IBOutlet UILabel *titleLabel;

@property(nonatomic, strong) IBOutlet UIButton *favoriteButton;

@property(nonatomic, strong) IBOutlet UIBarButtonItem *shareButton;

- (IBAction)share:(id)sender;

- (IBAction)toggleFavourite:(id)sender;

@end

@implementation EMSDetailViewController

#pragma mark - Initialization Convenience

- (void)setupWithSession:(Session *)session {
    if (session) {
        self.title = [EMSDetailViewController createControllerTitle:session];
        
        self.titleLabel.text = session.title;
        
        [self initFavoriteButton:session];
        
        [self initSpeakerCache:session];
        
        [self setupParts];
        
        [self retrieve];
        
        self.shareButton.enabled = YES;
        
    } else {
        self.title = @"";
        self.titleLabel.text = @"";
        self.favoriteButton.hidden = YES;
        
        self.shareButton.enabled = false;
    }
    
}

+ (NSString *) createControllerTitle: (Session *)session {
    NSDateFormatter *dateFormatterTime = [[NSDateFormatter alloc] init];
    
    [dateFormatterTime setDateStyle:NSDateFormatterNoStyle];
    [dateFormatterTime setTimeStyle:NSDateFormatterShortStyle];
    
    NSMutableString *title = [[NSMutableString alloc] init];
    
    if (session.slot) {
        [title appendString:[NSString stringWithFormat:@"%@ - %@",
                             [dateFormatterTime stringFromDate:session.slot.start],
                             [dateFormatterTime stringFromDate:session.slot.end]]];
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

- (void)initFavoriteButton:(Session *)session {
    NSString *imageBaseName = [session.format isEqualToString:@"lightning-talk"] ? @"64-zap" : @"28-star";
    NSString *imageNameFormat = @"%@-%@";
    
    UIImage *normalImage = [UIImage imageNamed:[NSString stringWithFormat:imageNameFormat, imageBaseName, @"grey"]];
    UIImage *selectedImage = [UIImage imageNamed:[NSString stringWithFormat:imageNameFormat, imageBaseName, @"yellow"]];
    
    if ([UIImage instancesRespondToSelector:@selector(imageWithRenderingMode:)]) {
        normalImage = [normalImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        selectedImage = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    [self.favoriteButton setImage:normalImage forState:UIControlStateNormal];
    [self.favoriteButton setImage:selectedImage forState:UIControlStateSelected];
    
    [self refreshFavourite];
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

- (void)setupParts {
    NSMutableArray *p = [[NSMutableArray alloc] init];

    if ([EMSFeatureConfig isFeatureEnabled:fLinks]) {
        if (self.session.videoLink) {
            [p addObject:[[EMSDetailViewRow alloc] initWithContent:@"Video" image:[UIImage imageNamed:@"70-tv"] link:[NSURL URLWithString:self.session.videoLink]]];
        }
    }

    [p addObject:[[EMSDetailViewRow alloc] initWithContent:self.session.body]];

    if (self.session.level != nil) {
        NSString *levelPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@-o", self.session.level] ofType:@"png"];
        UIImage *img = [UIImage imageWithContentsOfFile:levelPath];

        [p addObject:[[EMSDetailViewRow alloc] initWithContent:[self cleanString:self.session.level] image:img]];
    }

    NSArray *sortedKeywords = [self.session.keywords.allObjects sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSString *first = [(Keyword *) a name];
        NSString *second = [(Keyword *) b name];

        return [first compare:second];
    }];

    [sortedKeywords enumerateObjectsUsingBlock:^(id obj, NSUInteger x, BOOL *stop) {
        Keyword *keyword = (Keyword *) obj;

        [p addObject:[[EMSDetailViewRow alloc] initWithContent:keyword.name image:[UIImage imageNamed:@"14-tag"]]];
    }];

    [self.session.speakers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        Speaker *speaker = (Speaker *) obj;

        EMSDetailViewRow *row = [[EMSDetailViewRow alloc] initWithContent:speaker.name];

        if ([EMSFeatureConfig isFeatureEnabled:fBioPics]) {
            if (speaker.thumbnailUrl != nil) {
                CLS_LOG(@"Speaker has available thumbnail %@", speaker.thumbnailUrl);

                NSString *pngFilePath = [self pathForCachedThumbnail:speaker];

                UIImage *img = [UIImage imageWithContentsOfFile:pngFilePath];

                row.image = img;

                [self checkForNewThumbnailForSpeaker:speaker withFilename:pngFilePath withSessionHref:self.session.href];
            }
        }

        NSString *bio = self.cachedSpeakerBios[speaker.name];

        if (bio && ![bio isEqualToString:@""]) {
            row.body = bio;
        }

        [p addObject:row];
    }];

    self.parts = [NSArray arrayWithArray:p];

    [self.tableView reloadData];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    //We do not do fullscreen layout on iOS 7+ right now.
    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    
    [self setupWithSession:self.session];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
#ifndef DO_NOT_USE_GA
    id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Detail Screen"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
#endif

    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    if (popoverController == self.sharePopoverController) {
        self.sharePopoverController = nil;
    }

    self.shareButton.enabled = YES;
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
    
    CLS_LOG(@"Created calendar event %@", calendarEvent);
    
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
    unsigned char digest[16];
    CC_MD5(cStr, strlen(cStr), digest); // This is the md5 call
    
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
#ifdef USE_TEST_DATE
    CLS_LOG(@"WARNING - RUNNING IN USE_TEST_DATE mode");
    
    // In debug mode we will use the current day but always the start time of the slot. Otherwise we couldn't test until JZ started ;)
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *timeComp = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:date];
    NSDateComponents *dateComp = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[[NSDate alloc] init]];
    
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    [inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZ"];
    [inputFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    return [inputFormatter dateFromString:[NSString stringWithFormat:@"%04ld-%02ld-%02ld %02ld:%02ld:00 +0200", (long) [dateComp year], (long) [dateComp month], (long) [dateComp day], (long) [timeComp hour], (long) [timeComp minute]]];
#else
    return date;
#endif
}

#pragma mark - Actions

- (void)refreshFavourite {
    [self.favoriteButton setSelected:[self.session.favourite boolValue]];

    if (self.favoriteButton.selected) {
        self.favoriteButton.tintColor = nil;
    } else {
        self.favoriteButton.tintColor = [UIColor lightGrayColor];
    }

}

- (IBAction)toggleFavourite:(id)sender {
    self.session = [[[EMSAppDelegate sharedAppDelegate] model] toggleFavourite:self.session];
    
    [self.favoriteButton setSelected:[self.session.favourite boolValue]];
    
    if ([UIImage instancesRespondToSelector:@selector(imageWithRenderingMode:)]) {
        if (self.favoriteButton.selected) {
            self.favoriteButton.tintColor = nil;
        } else {
            self.favoriteButton.tintColor = [UIColor lightGrayColor];
        }
    }
}

- (void)share:(id)sender {
    self.shareButton.enabled = NO;
    
#ifndef DO_NOT_USE_CRASHLYTICS
    [Crashlytics setObjectValue:self.session.href forKey:@"lastSharedSession"];
#endif
    
    NSString *shareString = [NSString stringWithFormat:@"%@ - %@", self.session.conference.name, self.session.title];
    
    CLS_LOG(@"About to share for %@", shareString);
    
    // TODO - web URL?
    // NSURL *shareUrl = [NSURL URLWithString:@"http://www.java.no"];
    
    NSMutableArray *shareItems = [[NSMutableArray alloc] init];
    NSMutableArray *shareActivities = [[NSMutableArray alloc] init];
    
    [shareItems addObject:shareString];
    
    if (self.session.slot) {
        [shareItems addObject:[self createCalendarEvent]];
        [shareActivities addObject:[[NHCalendarActivity alloc] init]];
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
    
    [activityViewController setCompletionHandler:^(NSString *activityType, BOOL completed) {
        CLS_LOG(@"Sharing of %@ via %@ - completed %d", shareString, activityType, completed);
        
        
        self.shareButton.enabled = YES;
        if (completed) {
#ifndef DO_NOT_USE_GA
            id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
            
            [tracker send:[[GAIDictionaryBuilder createSocialWithNetwork:activityType
                                                                  action:@"Share"
                                                                  target:self.session.href] build]];
#endif
        }
    }];
    
    
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        
        popup.delegate = self;
        [popup presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
        self.sharePopoverController = popup;
    } else {
        [self presentViewController:activityViewController animated:YES completion:^{
            activityViewController.excludedActivityTypes = nil;
            activityViewController = nil;
        }];
    }
    
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.parts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EMSDetailViewRow *row = self.parts[(NSUInteger) indexPath.row];

    UITableViewCell *cell = [self tableView:tableView buildCellForRow:row];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    EMSDetailViewRow *row = self.parts[(NSUInteger) indexPath.row];

    UITableViewCell *cell = [self tableView:tableView buildCellForRow:row];

    int padding = 20;

    // Make sure the user can hit the row
    if (row.link) {
        padding = 30;
    }
    
    return cell.textLabel.frame.size.height + padding;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EMSDetailViewRow *row = self.parts[(NSUInteger) indexPath.row];

    if (row.link) {
        return indexPath;
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EMSDetailViewRow *row = self.parts[(NSUInteger) indexPath.row];

    if (row.link) {
#ifndef DO_NOT_USE_GA
        id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"web"
                                                              action:@"open link"
                                                               label:[row.link absoluteString]
                                                               value:nil] build]];
#endif

        [[UIApplication sharedApplication] openURL:row.link];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:false];
}

- (UITableViewCell *)tableView:(UITableView *)tableView buildCellForRow:(EMSDetailViewRow *)row {
    NSString *identifier = @"DetailBodyCell";
    
    if (row.link) {
        identifier = @"DetailLinkCell";
    } else if (row.body) {
        identifier = @"DetailTopAlignCell";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    if (row.body) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@\n\n%@", row.content, row.body];
    } else {
        cell.textLabel.text = row.content;
    }
    
    if (row.image) {
        UIImageView *image = [cell imageView];
        
        image.image = row.image;
        
        if (row.body) {
            CGSize itemSize = CGSizeMake(50, 50);
            UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
            [cell.imageView.image drawInRect:imageRect];
            [cell.imageView.layer setCornerRadius:8.0f];
            [cell.imageView.layer setMasksToBounds:YES];
            cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
        }
    }
    
    cell.textLabel.numberOfLines = 0;
    [cell.textLabel sizeToFit];
    
    return cell;
}

#pragma mark - Load Speakers

- (void)retrieve {
    EMSRetriever *retriever = [[EMSRetriever alloc] init];
    
    retriever.delegate = self;
    
    CLS_LOG(@"Retrieving speakers for href %@", self.session.speakerCollection);
    
    [retriever refreshSpeakers:[NSURL URLWithString:self.session.speakerCollection]];
}

- (void)finishedSpeakers:(NSArray *)speakers forHref:(NSURL *)href {
    CLS_LOG(@"Storing speakers %lu for href %@", (unsigned long) [speakers count], href);
    
    NSError *error = nil;
    
    EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];
    
    if (![backgroundModel storeSpeakers:speakers forHref:[href absoluteString] error:&error]) {
        CLS_LOG(@"Failed to store speakers %@ - %@", error, [error userInfo]);
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];
        
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
                CLS_LOG(@"Saw updated bios - updating screen");
                self.cachedSpeakerBios = [NSDictionary dictionaryWithDictionary:speakerBios];
                [self setupParts];
            }
        }
    });
}

- (void)checkForNewThumbnailForSpeaker:(Speaker *)speaker withFilename:(NSString *)pngFilePath withSessionHref:(NSString *)href {
    CLS_LOG(@"Checking for updated thumbnail %@", speaker.thumbnailUrl);
    
    NSData *thumbData = [NSData dataWithContentsOfFile:pngFilePath];
    
    dispatch_queue_t queue = dispatch_queue_create("thumbnail_queue", DISPATCH_QUEUE_CONCURRENT);
    
    [[EMSAppDelegate sharedAppDelegate] startNetwork];
    
    dispatch_async(queue, ^{
        NSError *thumbnailError = nil;
        
        NSURL *url = [NSURL URLWithString:speaker.thumbnailUrl];
        
        NSData *data = [NSData dataWithContentsOfURL:url
                                             options:NSDataReadingMappedIfSafe
                                               error:&thumbnailError];
        
        if (data == nil) {
            CLS_LOG(@"Failed to retrieve thumbnail %@ - %@ - %@", url, thumbnailError, [thumbnailError userInfo]);
            
            [[EMSAppDelegate sharedAppDelegate] stopNetwork];
        } else {
            UIImage *image = [UIImage imageWithData:data];
            
            NSData *newThumbData = [NSData dataWithData:UIImagePNGRepresentation(image)];
            
            __block BOOL needToSave = NO;
            
            if (thumbData == nil) {
                CLS_LOG(@"No existing bioPic - need to save");
                needToSave = YES;
            } else if (![thumbData isEqualToData:newThumbData]) {
                CLS_LOG(@"Thumbnail data didn't match - update");
                needToSave = YES;
            }
            
            if (needToSave) {
                CLS_LOG(@"Saving image file");
                
                [newThumbData writeToFile:pngFilePath atomically:YES];
            }
            
            [[EMSAppDelegate sharedAppDelegate] stopNetwork];
            
#ifndef DO_NOT_USE_GA
            [[GAI sharedInstance] dispatch];
#endif
            dispatch_async(dispatch_get_main_queue(), ^{
                if (needToSave) {
                    if ([self.session.href isEqualToString:href]) {
                        [self setupParts];
                    }
                }
            });
        }
    });
}

- (NSString *)pathForCachedThumbnail:(Speaker *)speaker {
    NSString *safeFilename = [self md5:speaker.thumbnailUrl];
    
    return [[[[EMSAppDelegate sharedAppDelegate] applicationCacheDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", safeFilename]] path];
}



@end
