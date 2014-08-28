//
//  EMSRetriever.m
//

#import "EMSRetriever.h"

#import "EMSEventsParser.h"
#import "EMSSlotsParser.h"
#import "EMSSessionsParser.h"
#import "EMSRoomsParser.h"
#import "EMSSpeakersParser.h"
#import "EMSConfig.h"

#import "EMSAppDelegate.h"

#import "EMSRootParser.h"
#import "EMSTracking.h"
#import "EMSConferenceRetriever.h"

@interface EMSRetriever () <EMSRootParserDelegate, EMSEventsParserDelegate, EMSSpeakersParserDelegate, EMSConferenceRetrieverDelegate>

@property(readwrite) BOOL refreshingConferences;
@property(nonatomic) NSURLSession *conferenceURLSession;
@property(nonatomic) NSOperationQueue *conferenceParseQueue;


@property(readwrite) BOOL refreshingSpeakers;
@property(nonatomic) NSURLSession *speakersURLSession;
@property(nonatomic) NSOperationQueue *speakersParseQueue;


@property(nonatomic, strong) NSSet *seenConferences;

@property(nonatomic, strong) EMSConferenceRetriever *currentSessionsRetriever;
@property(readwrite) BOOL refreshingSessions;

@end

@implementation EMSRetriever

+ (instancetype)sharedInstance {
    static EMSRetriever *instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[EMSRetriever alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _refreshingConferences = NO;

        NSURLSessionConfiguration *conferenceConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _conferenceURLSession = [NSURLSession sessionWithConfiguration:conferenceConfiguration];
        _conferenceParseQueue = [[NSOperationQueue alloc] init];
        
        _refreshingSessions = NO;

        _refreshingSpeakers = NO;
        NSURLSessionConfiguration *speakersConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _speakersURLSession = [NSURLSession sessionWithConfiguration:speakersConfiguration];
        _speakersParseQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (Conference *)conferenceForHref:(NSString *)href {
    NSAssert([NSThread isMainThread], @"Can only be called on main thread.");
    
    EMS_LOG(@"Getting conference for %@", href);

    return [[[EMSAppDelegate sharedAppDelegate] model] conferenceForHref:href];
}

- (Conference *)activeConference {
    NSAssert([NSThread isMainThread], @"Can only be called on main thread.");
    
    EMS_LOG(@"Getting current conference");

    NSString *activeConference = [[self currentConference] absoluteString];

    if (activeConference != nil) {
        return [self conferenceForHref:activeConference];
    }

    return nil;
}

- (NSURL *)currentConference {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSURL *href = [defaults URLForKey:@"activeConference"];
    
    if ([EMSFeatureConfig isCrashlyticsEnabled]) {
        [Crashlytics setObjectValue:href forKey:@"lastRetrievedConference"];
    }
    
    return href;
}

- (void)storeCurrentConference:(NSURL *)href {
    NSAssert([NSThread isMainThread], @"Can only be called on main thread.");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setURL:href forKey:@"activeConference"];
    
    [defaults synchronize];
    
    
    
    // Refresh sessions for conference if neccesary.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (![self currentConference]) {
            return;
        }
    
        if (![[[EMSAppDelegate sharedAppDelegate] model] sessionsAvailableForConference:[[self currentConference] absoluteString]]) {
            EMS_LOG(@"Checking for existing data found no data - forced refresh");
            [self refreshActiveConference];
            
        }
    }];
    
    if ([EMSFeatureConfig isCrashlyticsEnabled]) {
        [Crashlytics setObjectValue:href forKey:@"lastStoredConference"];
    }
}

- (void)cancelConferenceRefresh {
    //Cancel all pending network tasks
    [self.conferenceURLSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for (NSURLSessionTask *task in dataTasks) {
            [task cancel];
        }
        for (NSURLSessionTask *task in downloadTasks) {
            [task cancel];
        }
        for (NSURLSessionTask *task in uploadTasks) {
            [task cancel];
        }
        
        //Cancel all pending parsing operations
        [self.conferenceParseQueue cancelAllOperations];
        
        //TODO: Cancel changes to model object context
    }];
}

- (void)finishedConferencesWithError:(NSError *)error {

    dispatch_async(dispatch_get_main_queue(), ^{

        if (!self.refreshingConferences) {
            //Already reported an error.
            return;
        }

        if (!error) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[NSDate date] forKey:@"conferencesLastUpdate"];

            [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];
        } else {
            EMS_LOG(@"Failed to sync conferences %@ - %@", error, [error userInfo]);

            [self cancelConferenceRefresh];

            [self presentError:error];

        }

        self.refreshingConferences = NO;
        self.conferenceError = error;
    });

}

- (void)presentError:(NSError *)error {
    NSAssert([NSThread isMainThread], @"Can only be called on main thread.");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download failed", @"Conference download failed error dialog title.") message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"Error dialog dismiss button.") otherButtonTitles:nil];
    [alertView show];
}


- (void)refreshAllConferences {
    NSAssert([NSThread isMainThread], @"Should be called on main thread.");

    if (self.refreshingConferences) {
        return;
    }

    self.refreshingConferences = YES;

    NSArray *activeConferences = [[[EMSAppDelegate sharedAppDelegate] model] activeConferences];

    NSMutableSet *activeUrls = [[NSMutableSet alloc] init];

    for (Conference *c in activeConferences) {
        [activeUrls addObject:c.href];
    }

    self.seenConferences = [NSSet setWithSet:activeUrls];

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    NSURL *url = [EMSConfig emsRootUrl];

    NSDate *timer = [NSDate date];

    [[self.conferenceURLSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            [self finishedConferencesWithError:error];
        } else if (![self hasSuccessfulStatus:response]) {
            [self finishedConferencesWithError:[self errorForStatus:response]];
        } else {
            EMSRootParser *parser = [[EMSRootParser alloc] init];

            parser.delegate = self;

            [EMSTracking trackTimingWithCategory:@"retrieval" interval:@([[NSDate date] timeIntervalSinceDate:timer]) name:@"root"];
            [EMSTracking dispatch];

            [self.conferenceParseQueue addOperationWithBlock:^{
                [parser parseData:data forHref:url];
            }];
        }

        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];
}

- (void)finishedRoot:(NSDictionary *)links
             forHref:(NSURL *)href
               error:(NSError *)error {

    if (error != nil) {
        EMS_LOG(@"Retrieved error for root %@ - %@", error, [error userInfo]);

        [self finishedConferencesWithError:error];

        return;
    }

    if (links[@"event collection"]) {
        [self refreshConferencesForHref:links[@"event collection"]];
    }
}


- (void)refreshConferencesForHref:(NSURL *)url {
    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    NSDate *timer = [NSDate date];

    [[self.conferenceURLSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            [self finishedConferencesWithError:error];
        } else if (![self hasSuccessfulStatus:response]) {
            [self finishedConferencesWithError:[self errorForStatus:response]];
        } else {
            EMSEventsParser *parser = [[EMSEventsParser alloc] init];

            parser.delegate = self;

            [EMSTracking trackTimingWithCategory:@"retrieval" interval:@([[NSDate date] timeIntervalSinceDate:timer]) name:@"conferences"];
            [EMSTracking dispatch];

            [self.conferenceParseQueue addOperationWithBlock:^{
                [parser parseData:data forHref:url];
            }];
        }

        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];
}

- (void)finishedEvents:(NSArray *)conferences forHref:(NSURL *)href error:(NSError *)error {

    if (error != nil) {
        EMS_LOG(@"Retrieved error for events %@ - %@", error, [error userInfo]);

        [self finishedConferencesWithError:error];

        return;
    }

    EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

    [backgroundModel.managedObjectContext performBlock:^{
        NSError *saveError = nil;

        if (![backgroundModel storeConferences:conferences error:&saveError]) {
            [self finishedConferencesWithError:error];
        } else {
            [self finishedConferencesWithError:nil];

            NSArray *activeConferences = [backgroundModel activeConferences];

            NSMutableSet *activeUrls = [[NSMutableSet alloc] init];

            for (Conference *c in activeConferences) {
                [activeUrls addObject:c.href];
            }

            NSURL *currentConference;

            if (![self currentConference]) {
                currentConference = [NSURL URLWithString:[[backgroundModel mostRecentConference] href]];
            } else {
                [activeUrls minusSet:self.seenConferences];

                if (activeUrls.count > 0) {
                    NSMutableArray *newConferences = [[NSMutableArray alloc] init];

                    for (Conference *c in activeConferences) {
                        if ([activeUrls containsObject:c.href]) {
                            [newConferences addObject:c];
                        }
                    }

                    [newConferences sortUsingDescriptors:[EMSModel conferenceListSortDescriptors]];

                    Conference *latestConference = [newConferences firstObject];

                    currentConference = [NSURL URLWithString:latestConference.href];
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];

                if (currentConference) {
                    [self storeCurrentConference:currentConference];
                }
            });
        }
    }];
}

#pragma mark - retrieval

- (void)refreshActiveConference {

    NSAssert([NSThread isMainThread], @"Should be called from main thread.");

    if (self.refreshingSessions) {
        
        [self.currentSessionsRetriever cancel];
        
        self.currentSessionsRetriever = nil;
    
    }

    //Trigger a refresh of all conferences in the rare case a user has no selected conference and tries
    //to refresh by pulling down the session list.
    //This relies in the fact that refreshConferences will automatically select latest conference when done syncing.
    if (![self activeConference]) {


        [self refreshAllConferences];

        //Set to NO to trigger KVO so that the observers can stop
        //any progress indicators. This is a workaround on the fact that
        //a UIRefreshControl will start spinning automatically, so a call to this method must always trigger a KVO. If we did not do this the UIRefreshControl listening for changes to refreshingSessions would never stop spinning in the case that the above refreshAllConferences call fails.
        //I understand this is a code smell, so will revisit this...
        self.refreshingSessions = NO;
        return;
    }

    self.refreshingSessions = YES;

    Conference *activeConference = [self activeConference];


    EMSConferenceRetriever *conferenceRetriever = [[EMSConferenceRetriever alloc] init];
    conferenceRetriever.conference = activeConference; //TODO: Might be smarter to send href only.
    conferenceRetriever.delegate = self;
    self.currentSessionsRetriever = conferenceRetriever;
    
    [conferenceRetriever refresh];
}

- (void)finishedSpeakers:(NSArray *)speakers forHref:(NSURL *)href error:(NSError *)error {
    if (error != nil) {
        EMS_LOG(@"Retrieved error for speakers %@ - %@", error, [error userInfo]);

        return;
    }

    EMS_LOG(@"Storing speakers %lu for href %@", (unsigned long) [speakers count], href);

    EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

    [backgroundModel.managedObjectContext performBlock:^{
        NSError *saveError = nil;

        if (![backgroundModel storeSpeakers:speakers forHref:[href absoluteString] error:&saveError]) {
            EMS_LOG(@"Failed to store speakers %@ - %@", saveError, [saveError userInfo]);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];
            self.refreshingSpeakers = NO;

            if ([self.delegate respondsToSelector:@selector(finishedSpeakers:forHref:error:)]) {
                [self.delegate finishedSpeakers:speakers forHref:href error:NULL];
            }
        });
    }];
}

- (void)refreshSpeakers:(NSURL *)url {
    NSAssert([NSThread isMainThread], @"Should be called from main thread.");

    if (self.refreshingSpeakers) {
        return;
    }

    self.refreshingSpeakers = YES;

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    NSDate *timer = [NSDate date];

    [[self.speakersURLSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", url, error, [error userInfo]);
        }

        EMSSpeakersParser *parser = [[EMSSpeakersParser alloc] init];

        parser.delegate = self;

        [EMSTracking trackTimingWithCategory:@"retrieval" interval:@([[NSDate date] timeIntervalSinceDate:timer]) name:@"speakers"];
        [EMSTracking dispatch];

        [self.speakersParseQueue addOperationWithBlock:^{
            [parser parseData:data forHref:url];
        }];

        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];

}

#pragma mark - EMSConferenceRetrieverDelegate

- (void)conferenceRetriever:(EMSConferenceRetriever *)conferenceRetriever finishedWithError:(NSError *)error {
    NSAssert([conferenceRetriever isEqual:self.currentSessionsRetriever], @"Got callback from conference retriever that is not current. This should not happen. Try cancelling the old before starting a new. ");
    if (error) {
        [self presentError:error];
    } else {
        [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];
    }
    
    self.refreshingSessions = NO;
}

#pragma mark - Utilities

- (NSDate *)lastUpdatedAllConferences {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    return [defaults objectForKey:@"conferencesLastUpdate"];
}

- (NSDate *)lastUpdatedActiveConference {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    return [defaults objectForKey:[NSString stringWithFormat:@"sessionsLastUpdate-%@", [[self activeConference] href]]];
}

- (NSError *)errorForStatus:(NSURLResponse *)response {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];

    [errorDetail setValue:NSLocalizedString(@"Refresh failed", @"Error message when an HTTP error occured when refreshing.") forKey:NSLocalizedDescriptionKey];

    return [NSError errorWithDomain:@"EMSRetriever" code:[self statusCodeForResponse:response] userInfo:errorDetail];
}

- (BOOL)hasSuccessfulStatus:(NSURLResponse *)response {
    NSInteger status = [self statusCodeForResponse:response];

    return status >= 200 && status < 300;
}

- (NSInteger)statusCodeForResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpUrlResponse = (NSHTTPURLResponse *) response;

    return httpUrlResponse.statusCode;
}
@end
