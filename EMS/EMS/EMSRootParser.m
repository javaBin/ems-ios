//
// Created by Chris Searle on 26/08/14.
// Copyright (c) 2014 Chris Searle. All rights reserved.
//

#import "CJCollection.h"
#import "CJLink.h"

#import "EMSRootParser.h"

@implementation EMSRootParser

- (NSDictionary *)processData:(NSData *)data forHref:(NSURL *)href error:(NSError **)error {
    NSError *parseError = nil;

    CJCollection *collection = [CJCollection collectionForNSData:data error:&parseError];

    if (!collection) {
        DDLogError(@"Failed to retrieve root %@ - %@ - %@", href, parseError, [parseError userInfo]);

        *error = parseError;

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
    NSError *error = nil;

    NSDictionary *collection = [self processData:data forHref:href error:&error];

    [self.delegate finishedRoot:collection forHref:href error:error];
}

@end