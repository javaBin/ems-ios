//
// Created by Chris Searle on 26/08/14.
// Copyright (c) 2014 Chris Searle. All rights reserved.
//

#import "CJCollection.h"
#import "CJLink.h"

#import "EMSRootRetriever.h"
#import "EMSTracking.h"


@implementation EMSRootRetriever

NSDate *timer;

- (NSDictionary *)processData:(NSData *)data forHref:(NSURL *)href {
    NSError *error = nil;

    CJCollection *collection = [CJCollection collectionForNSData:data error:&error];

    if (!collection) {
        EMS_LOG(@"Failed to retrieve root %@ - %@ - %@", href, error, [error userInfo]);

        return [NSDictionary dictionary];
    }

    NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];

    [collection.links enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CJLink *link = (CJLink *) obj;

        temp[link.rel] = link.href;
    }];

    return [NSDictionary dictionaryWithDictionary:temp];
}
- (void)fetchedRoot:(NSData *)responseData forHref:(NSURL *)href {
    NSDictionary *collection = [self processData:responseData forHref:href];

    [EMSTracking trackTimingWithCategory:@"retrieval" interval:@([[NSDate date] timeIntervalSinceDate:timer]) name:@"root"];
    [EMSTracking dispatch];

    [self.delegate finishedRoot:collection forHref:href];
}


- (void)parse:(NSData *)data forHref:(NSURL *)url withParseQueue:(dispatch_queue_t)queue {
    if (url == nil) {
        EMS_LOG(@"Asked to fetch nil root url");

        return;
    }

    dispatch_async(queue, ^{
        [self fetchedRoot:data forHref:url];
    });

}

@end