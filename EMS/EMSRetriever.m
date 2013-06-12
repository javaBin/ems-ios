//
//  EMSRetriever.m
//  TestRig
//
//  Created by Chris Searle on 07.06.13.
//
//

#import "EMSRetriever.h"

#import "EMSConferencesRetriever.h"
#import "EMSSlotsRetriever.h"

@implementation EMSRetriever

@synthesize delegate;

- (void) refreshConferences {
    EMSConferencesRetriever *retriever = [[EMSConferencesRetriever alloc] init];
    
    retriever.delegate = delegate;
    
    [retriever fetch:[NSURL URLWithString:@"http://test.java.no/ems-redux/server/"]];
}

- (void) refreshSlots:(NSURL *)slotCollection {
    EMSSlotsRetriever *retriever = [[EMSSlotsRetriever alloc] init];
    
    retriever.delegate = delegate;
    
    [retriever fetch:slotCollection];
}

@end
