//
//  EMSRetriever.m
//

#import "EMSRetriever.h"

#import "EMSEventsParser.h"
#import "EMSConfig.h"

#import "EMSAppDelegate.h"

#import "EMSRootParser.h"
#import "EMSTracking.h"
#import "EMSConferenceRetriever.h"

#import "NSURLResponse+EMSExtensions.h"

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@interface EMSRetriever () <EMSRootParserDelegate, EMSEventsParserDelegate, EMSConferenceRetrieverDelegate>

@property(readwrite) BOOL refreshingConferences;
@property(nonatomic) NSURLSession *conferenceURLSession;
@property(nonatomic) NSOperationQueue *conferenceParseQueue;

@property(nonatomic, strong) NSSet *seenConferences;

@property(nonatomic, strong) EMSConferenceRetriever *currentSessionsRetriever;

@property(nonatomic, readwrite) BOOL fullSync;
@property(nonatomic, readwrite) BOOL sessionSync;

@property(nonatomic) UIBackgroundTaskIdentifier refreshAllConferencesBackroundIdentifier;

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

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    
    if ([key isEqualToString:@"refreshingSessions"]) {
        NSArray *affectingKeys = @[@"fullSync", @"sessionSync"];
        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
    }
    return keyPaths;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _refreshingConferences = NO;

        NSURLSessionConfiguration *conferenceConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _conferenceURLSession = [NSURLSession sessionWithConfiguration:conferenceConfiguration];
        _conferenceParseQueue = [[NSOperationQueue alloc] init];
        
        _sessionSync = NO;
        _fullSync = NO;
    }
    return self;
}

- (BOOL)refreshingSessions {
    return _fullSync || _sessionSync;
}

- (Conference *)conferenceForHref:(NSString *)href {
    NSAssert([NSThread isMainThread], @"Can only be called on main thread.");

    DDLogVerbose(@"Getting conference for %@", href);

    return [[[EMSAppDelegate sharedAppDelegate] model] conferenceForHref:href];
}

- (Conference *)activeConference {
    NSAssert([NSThread isMainThread], @"Can only be called on main thread.");

    DDLogVerbose(@"Getting current conference");

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
        [[Crashlytics sharedInstance] setObjectValue:href forKey:@"lastRetrievedConference"];
    }
    
    return href;
}

- (void)storeCurrentConference:(NSURL *)href {
    NSAssert([NSThread isMainThread], @"Can only be called on main thread.");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setURL:href forKey:@"activeConference"];
    
    [defaults synchronize];
    
    if ([EMSFeatureConfig isCrashlyticsEnabled]) {
        [[Crashlytics sharedInstance] setObjectValue:href forKey:@"lastStoredConference"];
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
            
            if (self.fullSync) {
                
                [self refreshSessions];
            }
            
        } else {
            DDLogError(@"Failed to sync conferences %@ - %@", error, [error userInfo]);

            [self cancelConferenceRefresh];

            [self presentError:error];
            
            if (self.fullSync) {
                self.fullSync = NO;
            }
        }
        
        self.refreshingConferences = NO;

        
        [[UIApplication sharedApplication] endBackgroundTask:self.refreshAllConferencesBackroundIdentifier];
        
        self.refreshAllConferencesBackroundIdentifier = UIBackgroundTaskInvalid;
        
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
    
    self.refreshAllConferencesBackroundIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"Refreshing All Conferences" expirationHandler:^{
        
        [[UIApplication sharedApplication] endBackgroundTask:self.refreshAllConferencesBackroundIdentifier];
    }];

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
        } else if (![response ems_hasSuccessfulStatus]) {
            [self finishedConferencesWithError:[response ems_error]];
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
        DDLogError(@"Retrieved error for root %@ - %@", error, [error userInfo]);

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
        } else if (![response ems_hasSuccessfulStatus]) {
            [self finishedConferencesWithError:[response ems_error]];
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
        DDLogError(@"Retrieved error for events %@ - %@", error, [error userInfo]);

        [self finishedConferencesWithError:error];

        return;
    }

    EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

    [backgroundModel.managedObjectContext performBlock:^{
        NSError *saveError = nil;

        if (![backgroundModel storeConferences:conferences error:&saveError]) {
            [self finishedConferencesWithError:error];
        } else {
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
                
                [self finishedConferencesWithError:nil];
            });
        }
    }];
}

#pragma mark - retrieval

- (BOOL)shouldUpdateAllConferences {
    if (![self activeConference]) {
        return YES;
    }
    
    if (![self lastUpdatedAllConferences]) {
        return YES;
    }
    
    NSDate *now = [NSDate new];
    NSDate *yesterday = [NSDate dateWithTimeInterval:-24*3600 sinceDate:now];
    if ([[[self lastUpdatedAllConferences] earlierDate:yesterday] isEqual:now]) {
        return YES;
    }
    
    return NO;
}

- (void) refreshActiveConference {
    NSAssert([NSThread isMainThread], @"Should be called from main thread.");
    
    if ([self shouldUpdateAllConferences]) {
        self.fullSync = YES;
        if (!self.refreshingConferences) {
            [self refreshAllConferences];
        }
    } else {
        [self refreshSessions];
    }
}

- (void)refreshSessions {

    NSAssert([NSThread isMainThread], @"Should be called from main thread.");

    if (self.sessionSync) {
        
        [self.currentSessionsRetriever cancel];
        
        self.currentSessionsRetriever = nil;
    
    }

    self.sessionSync = YES;

    Conference *activeConference = [self activeConference];


    EMSConferenceRetriever *conferenceRetriever = [[EMSConferenceRetriever alloc] init];
    conferenceRetriever.conference = activeConference; //TODO: Might be smarter to send href only.
    conferenceRetriever.delegate = self;
    self.currentSessionsRetriever = conferenceRetriever;
    
    [conferenceRetriever refresh];
}

#pragma mark - EMSConferenceRetrieverDelegate

- (void)conferenceRetriever:(EMSConferenceRetriever *)conferenceRetriever finishedWithError:(NSError *)error {
    NSAssert([conferenceRetriever isEqual:self.currentSessionsRetriever], @"Got callback from conference retriever that is not current. This should not happen. Try cancelling the old before starting a new. ");
    if (error) {
        [self presentError:error];
    } else {
        [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];
    }
    
    self.fullSync = NO;
    
    self.sessionSync = NO;
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

@end
