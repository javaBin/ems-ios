//
// Created by Chris Searle on 26/08/14.
// Copyright (c) 2014 Chris Searle. All rights reserved.
//

#import "CJCollection.h"
#import "CJLink.h"

#import "EMSRootParser.h"


@implementation EMSRootParser

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

- (void)parseData:(NSData *)data forHref:(NSURL *)href {
    NSDictionary *collection = [self processData:data forHref:href];

    [self.delegate finishedRoot:collection forHref:href];
}

@end