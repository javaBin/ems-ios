//
//  EMSConferencesRetriever.h
//  TestRig
//
//  Created by Chris Searle on 07.06.13.
//
//

#import <Foundation/Foundation.h>
#import "EMSRetrieverDelegate.h"

@interface EMSConferencesRetriever : NSObject

@property (nonatomic, strong) id <EMSRetrieverDelegate> delegate;

- (void) fetch:(NSURL *)url;

@end
