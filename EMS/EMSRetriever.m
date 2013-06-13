//
//  EMSRetriever.m
//

#import "EMSRetriever.h"

#import "EMSConferencesRetriever.h"
#import "EMSSlotsRetriever.h"

@implementation EMSRetriever

@synthesize delegate;

- (void) refreshConferences {
    EMSConferencesRetriever *retriever = [[EMSConferencesRetriever alloc] init];
    
    retriever.delegate = delegate;
    
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"EMS-Config" ofType:@"plist"];
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
    [retriever fetch:[NSURL URLWithString:[prefs objectForKey:@"ems-root-url"]]];
}

- (void) refreshSlots:(NSURL *)slotCollection {
    EMSSlotsRetriever *retriever = [[EMSSlotsRetriever alloc] init];
    
    retriever.delegate = delegate;
    
    [retriever fetch:slotCollection];
}

@end
