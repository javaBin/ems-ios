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

#import "EMSConference.h"
#import "EMSRootParser.h"
#import "EMSTracking.h"

@interface EMSRetriever () <EMSRootParserDelegate, EMSEventsParserDelegate, EMSRoomsParserDelegate, EMSSessionsParserDelegate, EMSSpeakersParserDelegate, EMSSlotsParserDelegate>

@property(readwrite) BOOL refreshingConferences;
@property(nonatomic) NSURLSession *conferenceURLSession;
@property(nonatomic) NSOperationQueue *conferenceParseQueue;


@property(readwrite) BOOL refreshingSessions;
@property(nonatomic) NSURLSession *sessionsURLSession;
@property(nonatomic) NSOperationQueue *sessionsParseQueue;

@property(nonatomic) NSOperation *slotsDoneOperation;
@property(nonatomic) NSOperation *roomsDoneOperation;
@property(nonatomic) NSOperationQueue *sessionSaveCoordinationOperationQueue;



@property(readwrite) BOOL refreshingSpeakers;
@property(nonatomic) NSURLSession *speakersURLSession;
@property(nonatomic) NSOperationQueue *speakersParseQueue;

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
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _sessionsURLSession = [NSURLSession sessionWithConfiguration:sessionConfiguration];
        _sessionsParseQueue = [[NSOperationQueue alloc] init];
        
        _sessionSaveCoordinationOperationQueue = [[NSOperationQueue alloc] init];
        
        
        _refreshingSpeakers =NO;
        NSURLSessionConfiguration *speakersConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _speakersURLSession = [NSURLSession sessionWithConfiguration:speakersConfiguration];
        _speakersParseQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (Conference *)conferenceForHref:(NSString *)href {
    EMS_LOG(@"Getting conference for %@", href);

    return [[[EMSAppDelegate sharedAppDelegate] model] conferenceForHref:href];
}

- (Conference *)activeConference {
    EMS_LOG(@"Getting current conference");

    NSString *activeConference = [[EMSAppDelegate currentConference] absoluteString];

    if (activeConference != nil) {
        return [self conferenceForHref:activeConference];
    }

    return nil;
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
            
            [self presentError:error];
           
        }
        
        self.refreshingConferences = NO;
        self.conferenceError = error;
    });

}

- (void) presentError:(NSError *) error {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download failed", @"Conference download failed error dialog title.") message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"Error dialog dismiss button.") otherButtonTitles:nil];
    [alertView show];
}

- (void)finishedSessionsWithError:(NSError *)error {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!self.refreshingSessions) {
            //Already reported an error.
            return;
        }
        
        if (!error) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[NSDate date] forKey:[NSString stringWithFormat:@"sessionsLastUpdate-%@", [[self activeConference] href]]];

            [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];
        } else {
            EMS_LOG(@"Failed to sync sessions %@ - %@", error, [error userInfo]);
            
            //Cancel all pending network tasks.
            [self.sessionsURLSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
                for (NSURLSessionTask *task in dataTasks) {
                    [task cancel];
                }
                for (NSURLSessionTask *task in downloadTasks) {
                    [task cancel];
                }
                for (NSURLSessionTask *task in uploadTasks) {
                    [task cancel];
                }
                
                //Cancel all pending parsing tasks.
                [self.sessionsParseQueue cancelAllOperations];
                
                //Do not enqueue more network tasks.
                [self.sessionSaveCoordinationOperationQueue cancelAllOperations];
                
                //TODO: Cancel changes to model object context
                
                
            }];
            
            
            [self presentError:error];
        }
        
        self.sessionError = error;
        
        self.refreshingSessions = NO;
        self.slotsDoneOperation = nil;
        self.roomsDoneOperation = nil;
    });
}

- (void)refreshAllConferences {
    NSAssert([NSThread isMainThread], @"Should be called on main thread.");

    if (self.refreshingConferences) {
        return;
    }

    self.refreshingConferences = YES;

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
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //TODO: Below is a dirty hack to auto select latest session.
                [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];

                Conference *latestConference = [backgroundModel mostRecentConference];

                [EMSAppDelegate storeCurrentConference:[NSURL URLWithString:latestConference.href]];
            });
        }
    }];
}

#pragma mark - retrieval

- (void)refreshActiveConference {

    NSAssert([NSThread isMainThread], @"Should be called from main thread.");

    if (self.refreshingSessions) {
        return;
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


    NSOperation *slotsDoneOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"Slots is done saving");
    }];
    self.slotsDoneOperation = slotsDoneOperation;

    NSOperation *roomsDoneOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"Rooms is done saving");
    }];
    self.roomsDoneOperation = roomsDoneOperation;

    EMS_LOG(@"Starting retrieval");

    if (activeConference != nil) {
        EMS_LOG(@"Starting retrieval - saw conf");

        //TODO: Check this logic?
        if (activeConference.slotCollection != nil) {
            EMS_LOG(@"Starting retrieval - saw slot collection");
            [self refreshSlots:[NSURL URLWithString:activeConference.slotCollection]];
        }

        if (activeConference.roomCollection != nil) {
            EMS_LOG(@"Starting retrieval - saw room collection");
            [self refreshRooms:[NSURL URLWithString:activeConference.roomCollection]];
        }

        if (activeConference.sessionCollection != nil) {
            EMS_LOG(@"Starting retrieval - saw session collection");
            [self refreshSessions:[NSURL URLWithString:activeConference.sessionCollection]];
        }

    }
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

- (void)finishedSlots:(NSArray *)slots forHref:(NSURL *)href error:(NSError *)error {
    if (error != nil) {
        EMS_LOG(@"Retrieved error for slots %@ - %@", error, [error userInfo]);

        [self finishedSessionsWithError:error];

        return;
    }

    NSOperation *saveSlotsOperation = [NSBlockOperation blockOperationWithBlock:^{
        EMS_LOG(@"Storing slots %lu", (unsigned long) [slots count]);
        EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];
        [backgroundModel.managedObjectContext performBlock:^{
            NSError *saveError = nil;

            if (![backgroundModel storeSlots:slots forHref:[href absoluteString] error:&saveError]) {
                EMS_LOG(@"Failed to store slots %@ - %@", saveError, [saveError userInfo]);

                [self finishedSessionsWithError:saveError];
            }
        }];
    }];
    
    __weak NSOperation *weakSaveSlot = saveSlotsOperation;
    saveSlotsOperation.completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![weakSaveSlot isCancelled] && self.slotsDoneOperation) {
                [self.sessionSaveCoordinationOperationQueue addOperation:self.slotsDoneOperation];
            }
        });
    };

    [self.sessionSaveCoordinationOperationQueue addOperation:saveSlotsOperation];

}

- (void)finishedSessions:(NSArray *)sessions forHref:(NSURL *)href error:(NSError *)error {
    if (error != nil) {
        EMS_LOG(@"Retrieved error for sessions %@ - %@", error, [error userInfo]);

        [self finishedSessionsWithError:error];

        return;
    }

    EMS_LOG(@"Storing sessions %lu", (unsigned long) [sessions count]);

    NSOperation *saveSessionsOperation = [NSBlockOperation blockOperationWithBlock:^{
        EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

        [backgroundModel.managedObjectContext performBlock:^{
            NSError *saveError = nil;

            if (![backgroundModel storeSessions:sessions forHref:[href absoluteString] error:&saveError]) {
                [self finishedSessionsWithError:saveError];
            } else {
                [self finishedSessionsWithError:nil];
                
            }
        }];
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.slotsDoneOperation && self.roomsDoneOperation) {
            //If slotsDoneOperation or roomsDoneOperation is not set we are likely cancelled,
            //so don´t try to save sessions either.
            [saveSessionsOperation addDependency:self.slotsDoneOperation];
            [saveSessionsOperation addDependency:self.roomsDoneOperation];
            
            [self.sessionSaveCoordinationOperationQueue addOperation:saveSessionsOperation];
        }
    });

}

- (void)finishedRooms:(NSArray *)rooms forHref:(NSURL *)href error:(NSError *)error {
    if (error != nil) {
        EMS_LOG(@"Retrieved error for rooms %@ - %@", error, [error userInfo]);

        [self finishedSessionsWithError:error];

        return;
    }

    EMS_LOG(@"Storing rooms %lu", (unsigned long) [rooms count]);

    NSOperation *saveRoomsOperation = [NSBlockOperation blockOperationWithBlock:^{
        EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

        [backgroundModel.managedObjectContext performBlock:^{
            NSError *saveError = nil;

            if (![backgroundModel storeRooms:rooms forHref:[href absoluteString] error:&saveError]) {
                EMS_LOG(@"Failed to store rooms %@ - %@", saveError, [saveError userInfo]);

                [self finishedSessionsWithError:error];
            }
        }];
    }];

    __weak NSOperation *weakSaveOperation = saveRoomsOperation;
    saveRoomsOperation.completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![weakSaveOperation isCancelled] && self.roomsDoneOperation) {
                [self.sessionSaveCoordinationOperationQueue addOperation:self.roomsDoneOperation];
            }            
        });
    };

    [self.sessionSaveCoordinationOperationQueue addOperation:saveRoomsOperation];
}

- (void)refreshSlots:(NSURL *)url {
    NSAssert([NSThread isMainThread], @"Should be called from main thread.");

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    NSDate *timer = [NSDate date];

    [[self.sessionsURLSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            [self finishedSessionsWithError:error];
        } else if (![self hasSuccessfulStatus:response]) {
            [self finishedSessionsWithError:[self errorForStatus:response]];
        } else {
            EMSSlotsParser *parser = [[EMSSlotsParser alloc] init];

            parser.delegate = self;

            [EMSTracking trackTimingWithCategory:@"retrieval" interval:@([[NSDate date] timeIntervalSinceDate:timer]) name:@"slots"];
            [EMSTracking dispatch];

            [self.sessionsParseQueue addOperationWithBlock:^{
                [parser parseData:data forHref:url];
            }];
        }

        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];
}

- (void)refreshSessions:(NSURL *)url {
    NSAssert([NSThread isMainThread], @"Should be called from main thread.");

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    NSDate *timer = [NSDate date];

    [[self.sessionsURLSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            [self finishedSessionsWithError:error];
        } else if (![self hasSuccessfulStatus:response]) {
            [self finishedSessionsWithError:[self errorForStatus:response]];
        } else {
            EMSSessionsParser *parser = [[EMSSessionsParser alloc] init];

            parser.delegate = self;

            [EMSTracking trackTimingWithCategory:@"retrieval" interval:@([[NSDate date] timeIntervalSinceDate:timer]) name:@"sessions"];
            [EMSTracking dispatch];

            
            [self.sessionsParseQueue addOperationWithBlock:^{
                [parser parseData:data forHref:url];
            }];
        }

        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];

}

- (void)refreshRooms:(NSURL *)url {
    NSAssert([NSThread isMainThread], @"Should be called from main thread.");

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    NSDate *timer = [NSDate date];

    [[self.sessionsURLSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            [self finishedSessionsWithError:error];
        } else if (![self hasSuccessfulStatus:response]) {
            [self finishedSessionsWithError:[self errorForStatus:response]];
        } else {
            EMSRoomsParser *parser = [[EMSRoomsParser alloc] init];

            parser.delegate = self;

            [EMSTracking trackTimingWithCategory:@"retrieval" interval:@([[NSDate date] timeIntervalSinceDate:timer]) name:@"rooms"];
            [EMSTracking dispatch];

            [self.sessionsParseQueue addOperationWithBlock:^{
                [parser parseData:data forHref:url];
            }];
            
        }

        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];


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

- (NSDate *)lastUpdatedAllConferences {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    return [defaults objectForKey:@"conferencesLastUpdate"];
}

- (NSDate *)lastUpdatedActiveConference {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    return [defaults objectForKey:[NSString stringWithFormat:@"sessionsLastUpdate-%@", [[self activeConference] href]]];
}

- (NSError *)errorForStatus:(NSURLResponse *) response {
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];

    [errorDetail setValue:NSLocalizedString(@"Refresh failed", @"Error message when an HTTP error occured when refreshing.") forKey:NSLocalizedDescriptionKey];

    return [NSError errorWithDomain:@"EMSRetriever" code:[self statusCodeForResponse:response] userInfo:errorDetail];
}

- (BOOL)hasSuccessfulStatus:(NSURLResponse *) response {
    NSInteger status = [self statusCodeForResponse:response];

    return status >= 200 && status < 300;
}

- (NSInteger)statusCodeForResponse:(NSURLResponse *) response {
    NSHTTPURLResponse *httpUrlResponse = (NSHTTPURLResponse *)response;

    return httpUrlResponse.statusCode;
}
@end
