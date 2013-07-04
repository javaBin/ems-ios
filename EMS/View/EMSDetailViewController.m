//
//  EMSDetailViewController.m
//

#import <CommonCrypto/CommonDigest.h>
#import <EventKit/EventKit.h>
#import <Crashlytics/Crashlytics.h>

#import "EMSDetailViewController.h"

#import "EMSAppDelegate.h"

#import "EMSRetriever.h"

#import "EMSFeatureConfig.h"

#import "Session.h"
#import "Speaker.h"
#import "Keyword.h"
#import "Room.h"

#import "NHCalendarActivity.h"
#import "NHCalendarEvent.h"

#import "MMMarkdown.h"

@interface EMSDetailViewController ()

@end

@implementation EMSDetailViewController

- (void)setupViewWithSession:(Session *)session {
    self.session = session;

    NSDateFormatter *dateFormatterTime = [[NSDateFormatter alloc] init];

    [dateFormatterTime setDateFormat:@"HH:mm"];

    NSMutableString *title = [[NSMutableString alloc] init];
    
    if (session.slot) {
        [title appendString:[NSString stringWithFormat:@"%@ - %@",
                             [dateFormatterTime stringFromDate:session.slot.start],
                             [dateFormatterTime stringFromDate:session.slot.end]]];
    } else {
        [title appendString:session.slotName];
    }

    if (session.roomName != nil) {
        [title appendString:[NSString stringWithFormat:@" : %@", session.roomName]];
    }

    self.title = [NSString stringWithString:title];

    UIImage *normalImage = [UIImage imageNamed:@"28-star-grey"];
    UIImage *selectedImage = [UIImage imageNamed:@"28-star-yellow"];
    UIImage *highlightedImage = [UIImage imageNamed:@"28-star"];

    if ([session.format isEqualToString:@"lightning-talk"]) {
        normalImage = [UIImage imageNamed:@"64-zap-grey"];
        selectedImage = [UIImage imageNamed:@"64-zap-yellow"];
        highlightedImage = [UIImage imageNamed:@"64-zap"];
    }

    [self.button setImage:normalImage forState:UIControlStateNormal];
    [self.button setImage:selectedImage forState:UIControlStateSelected];
    [self.button setImage:highlightedImage forState:UIControlStateHighlighted];

    [self.button setSelected:[session.favourite boolValue]];

    self.titleLabel.text = session.title;

    NSMutableDictionary *speakerBios = [[NSMutableDictionary alloc] init];

    [session.speakers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        Speaker *speaker = (Speaker *)obj;

        if (speaker.bio != nil) {
            [speakerBios setObject:speaker.bio forKey:speaker.name];
        } else {
            [speakerBios setObject:@"" forKey:speaker.name];
        }
    }];

    self.cachedSpeakerBios = [NSDictionary dictionaryWithDictionary:speakerBios];

    self.previousSessionButton.enabled = ([self getSessionForDirection:-1] != nil);
    self.nextSessionButton.enabled = ([self getSessionForDirection:1] != nil);
    self.previousSectionButton.enabled = ([self getSectionForDirection:-1] != nil);
    self.nextSectionButton.enabled = ([self getSectionForDirection:1] != nil);

    [self buildPage];

    [self retrieve];

}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupViewWithSession:self.session];
}

- (void) viewDidAppear:(BOOL)animated {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendView:@"Detail Screen"];
}


- (IBAction)toggleFavourite:(id)sender {
    self.session = [[[EMSAppDelegate sharedAppDelegate] model] toggleFavourite:self.session];
    
    [self.button setSelected:[self.session.favourite boolValue]];
}

- (void) buildPage {
    NSString *path = [[NSBundle mainBundle] bundlePath];
	NSURL *baseURL = [NSURL fileURLWithPath:path];
    [self.webView loadHTMLString:[self buildPage:self.session] baseURL:baseURL];
}

- (void) retrieve {
    EMSRetriever *retriever = [[EMSRetriever alloc] init];
    
    retriever.delegate = self;
    
    CLS_LOG(@"Retrieving speakers for href %@", self.session.speakerCollection);

    [retriever refreshSpeakers:[NSURL URLWithString:self.session.speakerCollection]];
}

- (void) finishedSpeakers:(NSArray *)speakers forHref:(NSURL *)href {
    CLS_LOG(@"Storing speakers %d for href %@", [speakers count], href);
    
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

            [self.cachedSpeakerBios enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSString *name = (NSString *)key;
                NSString *bio = (NSString *)obj;

                [self.session.speakers enumerateObjectsUsingBlock:^(id speakerObj, BOOL *stop) {
                    Speaker *speaker = (Speaker *)speakerObj;

                    if ([speaker.name isEqualToString:name]) {
                        if (![speaker.bio isEqualToString:bio]) {
                            if (speaker.bio != nil) {
                                [speakerBios setObject:speaker.bio forKey:speaker.name];
                                newBios = YES;
                            }
                        }
                    }
                }];
            }];

            if (newBios == YES) {
                CLS_LOG(@"Saw updated bios - updating screen");
                self.cachedSpeakerBios = [NSDictionary dictionaryWithDictionary:speakerBios];
                [self buildPage];
            }
        }
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)cleanString:(NSString *)value {
    if (value == nil) {
        return @"";
    }
    return [[value capitalizedString] stringByReplacingOccurrencesOfString:@"-" withString:@" "];
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
            Keyword *keyword = (Keyword *)obj;
                
            [listItems addObject:keyword.name];
        }];
            
        [result appendFormat:@"* %@\n\n", [[listItems sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@"\n* "]];
    }
    
    if ([self.session.speakers count] > 0) {
        [result appendString:@"\n\nSpeakers\n\n"];
        
        [self.session.speakers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            Speaker *speaker = (Speaker *)obj;
            
            [result appendString:speaker.name];

            NSString *bio = [self.cachedSpeakerBios objectForKey:speaker.name];
            if (![bio isEqualToString:@""]) {
                [result appendString:@"\n\n"];
                [result appendString:bio];
            }
            [result appendString:@"\n\n"];
        }];
    }
    
    return [NSString stringWithString:result];
}

- (NHCalendarEvent *)createCalendarEvent
{
    NHCalendarEvent *calendarEvent = [[NHCalendarEvent alloc] init];
    
    calendarEvent.title = [NSString stringWithFormat:@"%@ - %@", self.session.conference.name, self.session.title];
    calendarEvent.location = self.session.room.name;
    calendarEvent.notes = [self buildCalendarNotes];
    calendarEvent.startDate = [self dateForDate:self.session.slot.start];
    calendarEvent.endDate = [self dateForDate:self.session.slot.end];
    calendarEvent.allDay = NO;
    
    // Add alarm
    NSArray *alarms = @[[EKAlarm alarmWithRelativeOffset:- 60.0f * 5.0f]];
    
    calendarEvent.alarms = alarms;
    
    CLS_LOG(@"Created calendar event %@", calendarEvent);
    
    return calendarEvent;
}

- (void)share:(id)sender {
    [Crashlytics setObjectValue:self.session.href forKey:@"lastSharedSession"];
    
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

        if (completed) {
            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

            [tracker sendSocial:activityType
                     withAction:@"Share"
                     withTarget:[NSURL URLWithString:self.session.href]];
        }
    }];
    
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:activityViewController animated:YES completion:^{ activityViewController.excludedActivityTypes = nil; activityViewController = nil; }];
}

- (NSString *)buildPage:(Session *)session {
    
	NSString *page = [NSString stringWithFormat:@""
					  "<html>"
					  "<head>"
					  "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\"/>"
                      "<meta name='viewport' content='width=device-width; initial-scale=1.0; maximum-scale=1.0;'>"
					  "</head>"
					  "<body>"
					  "%@"
                      "%@"
					  "%@"
					  "%@"
					  "</body>"
					  "</html>",
					  [self paraContent:session.body],
                      [self levelContent:session.level],
					  [self keywordContent:session.keywords],
					  [self speakerContent:session.speakers]];

	return page;
}

- (NSString *)paraContent:(NSString *)text {
    if ([EMSFeatureConfig isFeatureEnabled:fMarkdown]) {
        NSError  *error = nil;
        
        NSString *htmlString = [MMMarkdown HTMLStringWithMarkdown:text error:&error];
        
        if (!htmlString) {
            CLS_LOG(@"Unable to convert markdown %@ - %@", error, [error userInfo]);
            
            return text;
        }
        
        return htmlString;
    } else {
        NSArray *lines = [text componentsSeparatedByString:@"\n"];
    
        return [NSString stringWithFormat:@"<p>%@</p>", [lines componentsJoinedByString:@"</p><p>"]];
    }
}

- (NSString *)levelContent:(NSString *)level {
	NSMutableString *result = [[NSMutableString alloc] init];
    
    if (level != nil) {
        [result appendString:@"<h2>Level</h2>"];
        
        [result appendString:@"<p>"];

        NSString *levelPath = [[NSBundle mainBundle] pathForResource:level ofType:@"png"];
        NSURL *levelUrl = [NSURL fileURLWithPath:levelPath];

        [result appendFormat:@"<img src='%@' /> %@", levelUrl, [self cleanString:level]];
        
        [result appendString:@"</p>"];
    }
    
    return [NSString stringWithString:result];
}

- (NSString *)keywordContent:(NSSet *)keywords {
	NSMutableString *result = [[NSMutableString alloc] init];

    if (keywords != nil && [keywords count] > 0) {
        [result appendString:@"<h2>Keywords</h2>"];

        [result appendString:@"<ul>"];

        NSMutableArray *listItems = [[NSMutableArray alloc] init];

        [keywords enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            Keyword *keyword = (Keyword *)obj;

            [listItems addObject:keyword.name];
        }];

        [result appendFormat:@"<li>%@</li>", [[listItems sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@"</li><li>"]];

        [result appendString:@"</ul>"];
    }

    return [NSString stringWithString:result];
}

- (NSString *)speakerContent:(NSSet *)speakers {
	NSMutableString *result = [[NSMutableString alloc] init];

    if (speakers != nil && [speakers count] > 0) {
        [result appendString:@"<h2>Speakers</h2>"];

        [speakers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            Speaker *speaker = (Speaker *)obj;
            
            if (speaker.name != nil) {
                [result appendString:[NSString stringWithFormat:@"<h3>%@</h3>", speaker.name]];
            }

            if ([EMSFeatureConfig isFeatureEnabled:fBioPics]) {
                if (speaker.thumbnailUrl != nil) {
                    CLS_LOG(@"Speaker has available thumbnail %@", speaker.thumbnailUrl);

                    NSString *pngFilePath = [self pathForCachedThumbnail:speaker];

                    NSFileManager *fileManager = [NSFileManager defaultManager];

                    NSData *thumbData = nil;

                    if ([fileManager fileExistsAtPath:pngFilePath]) {
                        CLS_LOG(@"Speaker has cached thumbnail %@", speaker.thumbnailUrl);

                        NSError *fileError = nil;
                
                        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:pngFilePath error:&fileError];
                
                        if (fileError != nil) {
                            CLS_LOG(@"Got a file error reading file attributes for file %@", pngFilePath);
                        } else {
                            if ([fileAttributes fileSize] > 0) {
                                thumbData = [NSData dataWithContentsOfFile:pngFilePath];

                                [result appendString:[NSString stringWithFormat:@"<img src='file://%@' width='50px' style='float: left; margin-right: 3px; margin-bottom: 3px'/>", pngFilePath]];
                            } else {
                                CLS_LOG(@"Empty bioPic %@", pngFilePath);
                            }
                        }
                    }

                    [self checkForNewThumbnailForSpeaker:speaker compareWith:thumbData withFilename:pngFilePath withSessionHref:self.session.href];
                }
            }

            NSString *bio = [self.cachedSpeakerBios objectForKey:speaker.name];
            if (![bio isEqualToString:@""]) {
                [result appendString:[self paraContent:bio]];
            }
        }];
        
	}
    
	return [NSString stringWithString:result];
}

- (void) checkForNewThumbnailForSpeaker:(Speaker *)speaker compareWith:(NSData *)thumbData withFilename:(NSString *) pngFilePath withSessionHref:(NSString *)href {
    CLS_LOG(@"Checking for updated thumbnail %@", speaker.thumbnailUrl);

    dispatch_queue_t queue = dispatch_queue_create("thumbnail_queue", DISPATCH_QUEUE_CONCURRENT);

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    dispatch_async(queue, ^{
        NSError *thumbnailError = nil;

        NSURL *url = [NSURL URLWithString:speaker.thumbnailUrl];

        NSData* data = [NSData dataWithContentsOfURL:url
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

            if (needToSave == YES) {
                CLS_LOG(@"Saving image file");

                [newThumbData writeToFile:pngFilePath atomically:YES];
            }

            [[EMSAppDelegate sharedAppDelegate] stopNetwork];

            [[GAI sharedInstance] dispatch];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (needToSave == YES) {
                    if ([self.session.href isEqualToString:href]) {
                        [self buildPage];
                    }
                }
            });
        }
    });
}

- (NSString *)pathForCachedThumbnail:(Speaker *)speaker {
    NSString *safeFilename = [self md5:speaker.thumbnailUrl];

    return [[[[EMSAppDelegate sharedAppDelegate] applicationCacheDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",safeFilename]] path];
}

- (NSString *) md5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

- (NSDate *)dateForDate:(NSDate *)date {
#ifdef USE_TEST_DATE
    CLS_LOG(@"WARNING - RUNNING IN USE_TEST_DATE mode");
    
	// In debug mode we will use the current day but always the start time of the slot. Otherwise we couldn't test until JZ started ;)
	NSCalendar *calendar = [NSCalendar currentCalendar];
    
	NSDateComponents *timeComp = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:date];
	NSDateComponents *dateComp = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[[NSDate alloc] init]];
    
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    [inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZ"];
    [inputFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
	return [inputFormatter dateFromString:[NSString stringWithFormat:@"%04d-%02d-%02d %02d:%02d:00 +0200", [dateComp year], [dateComp month], [dateComp day], [timeComp hour], [timeComp minute]]];
#else
    return date;
#endif
}

- (IBAction)clearImageCache:(id)sender {
    if (![EMSFeatureConfig isFeatureEnabled:fBioPics]) {
        return;
    }

    CLS_LOG(@"Clearing image cache");

    __block BOOL removedAFile = NO;

    [self.session.speakers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        Speaker *speaker = (Speaker *)obj;

        if (speaker.thumbnailUrl != nil) {
            CLS_LOG(@"Speaker has available thumbnail %@", speaker.thumbnailUrl);

            removedAFile = [self removedCachedFileForSpeaker:speaker];
        }
    }];

    if (removedAFile == YES) {
        [self buildPage];
    }
}

- (BOOL)removedCachedFileForSpeaker:(Speaker *)speaker {
    NSString *pngFilePath = [self pathForCachedThumbnail:speaker];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:pngFilePath]) {
        CLS_LOG(@"Speaker has cached thumbnail to delete %@", pngFilePath);

        NSError *fileError = nil;

        [fileManager removeItemAtPath:pngFilePath error:&fileError];

        if (fileError != nil) {
            CLS_LOG(@"Got a file error deleting file %@", pngFilePath);
        } else {
            CLS_LOG(@"File deleted %@", pngFilePath);

            return YES;
        }
    }

    return NO;
}

- (NSIndexPath *)getSectionForDirection:(int)direction {
    NSArray *sections = [self.fetchedResultsController sections];

   return [self indexPathForSection:self.indexPath moving:direction fromSections:sections];
}

- (NSIndexPath *)getSessionForDirection:(int)direction {
    NSArray *sections = [self.fetchedResultsController sections];

    int rowCount = [[sections objectAtIndex:self.indexPath.section] numberOfObjects];

    return [self indexPathForRow:self.indexPath moving:direction withRows:rowCount];
}

- (void)updateWithIndexPath:(NSIndexPath *)path {
    if (path != nil) {
        self.indexPath = path;
        [self setupViewWithSession:[self.fetchedResultsController objectAtIndexPath:self.indexPath]];
    }
}

- (IBAction)movePreviousSection:(id)sender {
    [self updateWithIndexPath:[self getSectionForDirection:-1]];
}

- (IBAction)moveNextSection:(id)sender {
    [self updateWithIndexPath:[self getSectionForDirection:1]];
}

- (IBAction)movePreviousSession:(id)sender {
    [self updateWithIndexPath:[self getSessionForDirection:-1]];
}

- (IBAction)moveNextSession:(id)sender {
    [self updateWithIndexPath:[self getSessionForDirection:1]];
}

- (NSIndexPath *)indexPathForSection:(NSIndexPath *)current moving:(int)direction fromSections:(NSArray *)sections {
    int section = current.section + (1 * direction);

    if (section < 0) {
        return nil;
    }
    if (section >= sections.count) {
        return nil;
    }

    int row = current.row;

    int rowMax = ([[sections objectAtIndex:section] numberOfObjects] - 1);

    if (rowMax < row) {
        row = rowMax;
    }

    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (NSIndexPath *)indexPathForRow:(NSIndexPath *)current moving:(int)direction withRows:(int)rows {
    int section = current.section;

    int row = current.row + (1 * direction);

    if (row < 0) {
        return nil;
    }
    if (row >= rows) {
        return nil;
    }

    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        // http:// -> safari, rest (file:// etc) opens in webview
        if ([[request.URL scheme] hasPrefix:@"http"]) {
            [[UIApplication sharedApplication] openURL:request.URL];
            return NO;
        }
    }
    
    return YES;
}

@end
