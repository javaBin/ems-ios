//
//  EMSRetriever.m
//

#import "EMSRetriever.h"

#import "EMSConferencesRetriever.h"
#import "EMSSlotsRetriever.h"
#import "EMSSessionsRetriever.h"
#import "EMSRoomsRetriever.h"
#import "EMSSpeakersRetriever.h"

@implementation EMSRetriever

- (void) refreshConferences {
    EMSConferencesRetriever *retriever = [[EMSConferencesRetriever alloc] init];
    
    retriever.delegate = self.delegate;
    
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"EMS-Config" ofType:@"plist"];
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
#ifdef DEBUG
#ifdef TEST_PROD
    [retriever fetch:[NSURL URLWithString:[prefs objectForKey:@"ems-root-url-prod"]]];
#else
    [retriever fetch:[NSURL URLWithString:[prefs objectForKey:@"ems-root-url"]]];
#endif
#else
    [retriever fetch:[NSURL URLWithString:[prefs objectForKey:@"ems-root-url-prod"]]];
#endif
}

- (void) refreshSlots:(NSURL *)slotCollection {
    EMSSlotsRetriever *retriever = [[EMSSlotsRetriever alloc] init];
    
    retriever.delegate = self.delegate;
    
    [retriever fetch:slotCollection];
}

- (void) refreshSessions:(NSURL *)sessionCollection {
    EMSSessionsRetriever *retriever = [[EMSSessionsRetriever alloc] init];
    
    retriever.delegate = self.delegate;
    
    [retriever fetch:sessionCollection];
}

- (void) refreshRooms:(NSURL *)roomCollection {
    EMSRoomsRetriever *retriever = [[EMSRoomsRetriever alloc] init];
    
    retriever.delegate = self.delegate;
    
    [retriever fetch:roomCollection];
}

- (void) refreshSpeakers:(NSURL *)speakerCollection {
    EMSSpeakersRetriever *retriever = [[EMSSpeakersRetriever alloc] init];
    
    retriever.delegate = self.delegate;
    
    [retriever fetch:speakerCollection];
}

@end
