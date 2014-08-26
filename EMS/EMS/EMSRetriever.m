//
//  EMSRetriever.m
//

#import "EMSRetriever.h"

#import "EMSConferencesRetriever.h"
#import "EMSSlotsRetriever.h"
#import "EMSSessionsRetriever.h"
#import "EMSRoomsRetriever.h"
#import "EMSSpeakersRetriever.h"
#import "EMSConfig.h"

#import "EMSAppDelegate.h"

#import "EMSModel.h"
#import "EMSConference.h"

@interface EMSRetriever () <EMSRetrieverDelegate>

@property(readwrite) BOOL refreshingConferences;
@property(readwrite) BOOL refreshingSessions;
@property(readwrite) BOOL refreshingSpeakers;

@property(nonatomic) dispatch_queue_t parseQueue;

@property(nonatomic) NSURLSession *session;

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
        _refreshingSessions = NO;

        _refreshingSlots = NO;
        _refreshingRooms = NO;
        
        _parseQueue = dispatch_queue_create("ems-parse-queue", DISPATCH_QUEUE_CONCURRENT);
        
        _session = [NSURLSession sharedSession];
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


- (void)refreshConferences {
    NSAssert([NSThread isMainThread], @"Should be called on main thread.");

    if (self.refreshingConferences) {
        return;
    }

    self.refreshingConferences = YES;
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    [[EMSAppDelegate sharedAppDelegate] startNetwork];
    
    NSURL *url = [EMSConfig emsRootUrl];
    [[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", url, error, [error userInfo]);
        }
        
        EMSConferencesRetriever *retriever = [[EMSConferencesRetriever alloc] init];
        
        retriever.delegate = self;
        
        [retriever parse:data forHref:url withParseQueue:self.parseQueue];
        
        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];

}

- (void)finishedConferences:(NSArray *)conferences
                    forHref:
                            (NSURL *)href {

    EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

    [backgroundModel.managedObjectContext performBlock: ^{
        NSError *error = nil;

        if (![backgroundModel storeConferences:conferences error:&error]) {
            EMS_LOG(@"Failed to store conferences %@ - %@", error, [error userInfo]);
        }
    dispatch_async(dispatch_get_main_queue(), ^{
            [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];
            
            self.refreshingConferences = NO;
            
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

    EMS_LOG(@"Starting retrieval");

    if (activeConference != nil) {
        EMS_LOG(@"Starting retrieval - saw conf");

        if (activeConference.slotCollection != nil) {
            EMS_LOG(@"Starting retrieval - saw slot collection");
            _refreshingSlots = YES;
            [self refreshSlots:[NSURL URLWithString:activeConference.slotCollection]];
        }
        if (activeConference.roomCollection != nil) {
            EMS_LOG(@"Starting retrieval - saw room collection");
            _refreshingRooms = YES;
            [self refreshRooms:[NSURL URLWithString:activeConference.roomCollection]];
        }
    }
}

- (void)retrieveSessions {
    NSAssert([NSThread isMainThread], @"Should be called from main thread.");

    EMS_LOG(@"Starting retrieval of sessions");
    // Fetch sessions once rooms and slots are done. Don't want to get into a state when trying to persist sessions that it refers to non-existing room or slot
    if (!_refreshingRooms && !_refreshingSlots) {
        EMS_LOG(@"Starting retrieval of sessions - clear to go");
        Conference *activeConference = [self activeConference];
        [self refreshSessions:[NSURL URLWithString:activeConference.sessionCollection]];
    }
}

- (void)finishedSpeakers:(NSArray *)speakers
                 forHref:
                         (NSURL *)href {
    EMS_LOG(@"Storing speakers %lu for href %@", (unsigned long) [speakers count], href);

    EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

    [backgroundModel.managedObjectContext performBlock: ^{
        NSError *error = nil;

        if (![backgroundModel storeSpeakers:speakers forHref:[href absoluteString] error:&error]) {
            EMS_LOG(@"Failed to store speakers %@ - %@", error, [error userInfo]);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];
            self.refreshingSpeakers = NO;
            
            if ([self.delegate respondsToSelector:@selector(finishedSpeakers:forHref:)]) {
                [self.delegate finishedSpeakers:speakers forHref:href];
            } 
        });
    }];


}


- (void)finishedSlots:(NSArray *)slots
              forHref:
                      (NSURL *)href {
    EMS_LOG(@"Storing slots %lu", (unsigned long) [slots count]);

    EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

    [backgroundModel.managedObjectContext performBlock: ^{
        NSError *error = nil;

        if (![backgroundModel storeSlots:slots forHref:[href absoluteString] error:&error]) {
            EMS_LOG(@"Failed to store slots %@ - %@", error, [error userInfo]);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _refreshingSlots = NO;
            
            [self retrieveSessions];
        });
    }];

    
}

- (void)finishedSessions:(NSArray *)sessions
                 forHref:
                         (NSURL *)href {
    EMS_LOG(@"Storing sessions %lu", (unsigned long) [sessions count]);

    EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

    [backgroundModel.managedObjectContext performBlock: ^{
        NSError *error = nil;

        if (![backgroundModel storeSessions:sessions forHref:[href absoluteString] error:&error]) {
            EMS_LOG(@"Failed to store sessions %@ - %@", error, [error userInfo]);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[EMSAppDelegate sharedAppDelegate] syncManagedObjectContext];
            
            self.refreshingSessions = NO;
        });
    }];

}

- (void)finishedRooms:(NSArray *)rooms
              forHref:
                      (NSURL *)href {
    EMS_LOG(@"Storing rooms %lu", (unsigned long) [rooms count]);

    EMSModel *backgroundModel = [[EMSAppDelegate sharedAppDelegate] modelForBackground];

    [backgroundModel.managedObjectContext performBlock: ^{
        NSError *error = nil;

        if (![backgroundModel storeRooms:rooms forHref:[href absoluteString] error:&error]) {
            EMS_LOG(@"Failed to store rooms %@ - %@", error, [error userInfo]);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            _refreshingRooms = NO;
            
            [self retrieveSessions];
        });
    }];

}

- (void)refreshSlots:(NSURL *)slotCollection {
    NSAssert([NSThread isMainThread], @"Should be called from main thread.");

    
    [[EMSAppDelegate sharedAppDelegate] startNetwork];
    
    [[self.session dataTaskWithURL:slotCollection completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", slotCollection, error, [error userInfo]);
        }
        
        EMSSlotsRetriever *retriever = [[EMSSlotsRetriever alloc] init];
        
        retriever.delegate = self;
        
        [retriever parse:data forHref:slotCollection withParseQueue:self.parseQueue];
        
        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];
}

- (void)refreshSessions:(NSURL *)sessionCollection {
    NSAssert([NSThread isMainThread], @"Should be called from main thread.");
    
    [[EMSAppDelegate sharedAppDelegate] startNetwork];
    
    [[self.session dataTaskWithURL:sessionCollection completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", sessionCollection, error, [error userInfo]);
        }
        
        EMSSessionsRetriever *retriever = [[EMSSessionsRetriever alloc] init];
        
        retriever.delegate = self;
        
        [retriever parse:data forHref:sessionCollection withParseQueue:self.parseQueue];
        
        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];

}

- (void)refreshRooms:(NSURL *)roomCollection {
    NSAssert([NSThread isMainThread], @"Should be called from main thread.");

    
    [[EMSAppDelegate sharedAppDelegate] startNetwork];
    [[self.session dataTaskWithURL:roomCollection completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", roomCollection, error, [error userInfo]);
        }
        
        EMSRoomsRetriever *retriever = [[EMSRoomsRetriever alloc] init];
        
        retriever.delegate = self;
        
        [retriever parse:data forHref:roomCollection withParseQueue:self.parseQueue];
        
        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];
    
    
}

- (void)refreshSpeakers:(NSURL *)speakerCollection {
    NSAssert([NSThread isMainThread], @"Should be called from main thread.");

    if (self.refreshingSpeakers) {
        return;
    }

    self.refreshingSpeakers = YES;
    
    [[EMSAppDelegate sharedAppDelegate] startNetwork];
    
    [[self.session dataTaskWithURL:speakerCollection completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            EMS_LOG(@"Retrieved nil root %@ - %@ - %@", speakerCollection, error, [error userInfo]);
        }
        
        EMSSpeakersRetriever *retriever = [[EMSSpeakersRetriever alloc] init];
        
        retriever.delegate = self;
        
        [retriever parse:data forHref:speakerCollection withParseQueue:self.parseQueue];
        
        [[EMSAppDelegate sharedAppDelegate] stopNetwork];
    }] resume];
    
}

@end
