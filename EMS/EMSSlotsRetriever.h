//
//  EMSSlotsRetriever.h
//  EMS
//
//  Created by Chris Searle on 12.06.13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMSRetrieverDelegate.h"

@interface EMSSlotsRetriever : NSObject

@property (nonatomic, strong) id <EMSRetrieverDelegate> delegate;

- (void) fetch:(NSURL *)url;

@end
