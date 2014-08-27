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
@property(nonatomic) NSOperationQueue *syncOperationQueue;



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
        
        _syncOperationQueue = [[NSOperationQueue alloc] init];
        
        
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
        
        if (!error) {
            [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];
        } else {
            EMS_LOG(@"Failed to sync conferences %@ - %@", error, [error userInfo]);
            
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
                [self.conferenceParseQueue cancelAllOperations];
            }];
        }
        
        self.refreshingConferences = NO;
        self.conferenceError = error;
    });

}

- (void)finishedSessionsWithError:(NSError *)error {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!error) {
            [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];
        } else {
            EMS_LOG(@"Failed to sync sessions %@ - %@", error, [error userInfo]);
            
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
                
                [self.sessionsParseQueue cancelAllOperations];
                [self.syncOperationQueue cancelAllOperations];
            }];
        }
        
        self.sessionError = error;
        
        self.refreshingSessions = NO;
        self.slotsDoneOperation = nil;
        self.roomsDoneOperation = nil;
    });
}

- (void)refreshRoot {
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
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", url, error, [error userInfo]);

            [self finishedConferencesWithError:error];
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
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", url, error, [error userInfo]);

            [self finishedConferencesWithError:error];
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
                NSArray *filteredConferences = [conferences filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                    EMSConference *emsConference = evaluatedObject;
                    return [emsConference.hintCount longValue] > 0;
                }]];
                
                NSArray *sortedConferences = [filteredConferences sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id obj1, id obj2) {
                    EMSConference *emsConference1 = obj1;
                    EMSConference *emsConference2 = obj2;
                    
                    return [emsConference1.start compare:emsConference2.start];
                }];
                
                EMSConference *latestConference = sortedConferences.lastObject;
                
                [EMSAppDelegate storeCurrentConference:latestConference.href];
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
    saveSlotsOperation.completionBlock = ^{
        [self.syncOperationQueue addOperation:self.slotsDoneOperation];
    };

    [self.syncOperationQueue addOperation:saveSlotsOperation];

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

    [saveSessionsOperation addDependency:self.slotsDoneOperation];
    [saveSessionsOperation addDependency:self.roomsDoneOperation];

    [self.syncOperationQueue addOperation:saveSessionsOperation];

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

    saveRoomsOperation.completionBlock = ^{
        [self.syncOperationQueue addOperation:self.roomsDoneOperation];
    };

    [self.syncOperationQueue addOperation:saveRoomsOperation];
}

- (void)refreshSlots:(NSURL *)url {
    NSAssert([NSThread isMainThread], @"Should be called from main thread.");

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    NSDate *timer = [NSDate date];

    [[self.sessionsURLSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", url, error, [error userInfo]);

            [self finishedSessionsWithError:error];
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
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", url, error, [error userInfo]);

            [self finishedSessionsWithError:error];
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
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", url, error, [error userInfo]);

            [self finishedSessionsWithError:error];
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

@end
