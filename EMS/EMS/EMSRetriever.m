//
//  EMSRetriever.m
//

#import "EMSRetriever.h"

#import "EMSConferencesRetriever.h"
#import "EMSSlotsRetriever.h"
#import "EMSSessionsRetriever.h"
#import "EMSRoomsRetriever.h"

@implementation EMSRetriever

- (void) refreshConferences {
    EMSConferencesRetriever *retriever = [[EMSConferencesRetriever alloc] init];
    
    retriever.delegate = self.delegate;
    
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"EMS-Config" ofType:@"plist"];
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
    [retriever fetch:[NSURL URLWithString:[prefs objectForKey:@"ems-root-url"]]];
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

@end
