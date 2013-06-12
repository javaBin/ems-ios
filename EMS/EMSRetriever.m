//
//  EMSRetriever.m
//  TestRig
//
//  Created by Chris Searle on 07.06.13.
//
//

#import "EMSRetriever.h"

#import "EMSConferencesRetriever.h"

@implementation EMSRetriever

@synthesize delegate;

- (void) refreshConferences {
    EMSConferencesRetriever *retriever = [[EMSConferencesRetriever alloc] init];
    
    retriever.delegate = delegate;
    
    [retriever fetch:[NSURL URLWithString:@"http://test.java.no/ems-redux/server/"]];
}

@end
