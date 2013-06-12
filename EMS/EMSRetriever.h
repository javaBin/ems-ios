//
//  EMSRetriever.h
//  TestRig
//
//  Created by Chris Searle on 07.06.13.
//
//

#import <Foundation/Foundation.h>
#import "EMSRetrieverDelegate.h"

@interface EMSRetriever : NSObject

@property (nonatomic, strong) id <EMSRetrieverDelegate> delegate;

- (void) refreshConferences;

@end
