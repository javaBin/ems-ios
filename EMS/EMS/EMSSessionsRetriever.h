//
//  EMSSessionsRetriever.h
//  EMS
//
//  Created by Chris Searle on 17.06.13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMSRetrieverDelegate.h"

@interface EMSSessionsRetriever : NSObject

@property (nonatomic, weak) id <EMSRetrieverDelegate> delegate;

- (void) fetch:(NSURL *)url;

@end
