//
//  EMSActiveConferenceRetriever.m
//  EMS
//
//  Created by Jobb on 28.08.14.
//  Copyright (c) 2014 Chris Searle. All rights reserved.
//

#import "EMSConferenceRetriever.h"
#import "Conference.h"
#import "EMSRetriever.h"
#import "EMSAppDelegate.h"
#import "EMSSessionsParser.h"
#import "EMSRoomsParser.h"
#import "EMSSlotsParser.h"
#import "EMSTracking.h"

@interface EMSConferenceRetriever ()<EMSSlotsParserDelegate, EMSRoomsParserDelegate, EMSSessionsParserDelegate>

@property(nonatomic) NSURLSession *sessionsURLSession;
@property(nonatomic) NSOperationQueue *sessionsParseQueue;

@property(nonatomic) NSOperation *slotsDoneOperation;
@property(nonatomic) NSOperation *roomsDoneOperation;
@property(nonatomic) NSOperationQueue *sessionSaveCoordinationOperationQueue;

@property(nonatomic) BOOL cancelled;

@property(nonatomic) BOOL refreshingSessions;

@property(nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end

@implementation EMSConferenceRetriever

#pragma mark - Public API

- (instancetype)init {
    self = [super init];
    if (self) {
        _refreshingSessions = NO;
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _sessionsURLSession = [NSURLSession sessionWithConfiguration:sessionConfiguration];
        _sessionsParseQueue = [[NSOperationQueue alloc] init];
    
        _sessionSaveCoordinationOperationQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)cancel {
    self.cancelled = YES;
    
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    [self cancelSessionRefresh];
}

- (void)refresh {
    
    NSAssert([NSThread isMainThread], @"Should be called from main thread.");
    NSAssert(!self.refreshingSessions, @"Already refreshing!!!!");
  
    
    self.backgroundTaskIdentifier =  [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"Sync Conference" expirationHandler:^{
        
        [self cancel];
        
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
    }];

    self.refreshingSessions = YES;
    
    
    NSOperation *slotsDoneOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"Slots is done saving");
    }];
    self.slotsDoneOperation = slotsDoneOperation;
    
    NSOperation *roomsDoneOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"Rooms is done saving");
    }];
    self.roomsDoneOperation = roomsDoneOperation;
    
    EMS_LOG(@"Starting retrieval");
    
    
    Conference *conference = self.conference;
    if (conference != nil) {
        EMS_LOG(@"Starting retrieval - saw conf");
        
        //TODO: Check this logic?
        if (conference.slotCollection != nil) {
            EMS_LOG(@"Starting retrieval - saw slot collection");
            [self refreshSlots:[NSURL URLWithString:conference.slotCollection]];
        }
        
        if (conference.roomCollection != nil) {
            EMS_LOG(@"Starting retrieval - saw room collection");
            [self refreshRooms:[NSURL URLWithString:conference.roomCollection]];
        }
        
        if (conference.sessionCollection != nil) {
            EMS_LOG(@"Starting retrieval - saw session collection");
            [self refreshSessions:[NSURL URLWithString:conference.sessionCollection]];
        }
        
    }
}

#pragma mark - Private API

- (void)cancelSessionRefresh {
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
}

- (void)finishedSessionsWithError:(NSError *)error {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.cancelled) {
            //Should not report anything.
            return;
        }
        
        if (!self.refreshingSessions) {
            //Already reported an error.
            return;
        }
        
        if (error) {
            EMS_LOG(@"Failed to sync sessions %@ - %@", error, [error userInfo]);
            [self cancelSessionRefresh];
        } else {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[NSDate date] forKey:[NSString stringWithFormat:@"sessionsLastUpdate-%@", [self.conference href]]];
        }
        
        self.refreshingSessions = NO;
        self.slotsDoneOperation = nil;
        self.roomsDoneOperation = nil;
        
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        
        if (self.delegate) {
            [self.delegate conferenceRetriever:self finishedWithError:error];
        }
        
    });
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

#pragma mark - TODO: Duplicated code below

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
