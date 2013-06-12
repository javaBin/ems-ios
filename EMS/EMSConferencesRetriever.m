//
//  EMSConferencesRetriever.m
//  TestRig
//
//  Created by Chris Searle on 07.06.13.
//
//

#import "EMSConferencesRetriever.h"
#import "EMSConference.h"

#import "CJCollection.h"
#import "CJLink.h"
#import "CJItem.h"

#import "EMSDateConverter.h"

@implementation EMSConferencesRetriever

@synthesize delegate;

- (void)fetchedEventCollection:(NSData *)responseData {
    CJCollection *collection = [CJCollection collectionForNSData:responseData];
    
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    
    [collection.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CJItem *item = (CJItem *)obj;
        
        EMSConference *conf = [[EMSConference alloc] init];
        
        conf.href = item.href;
        
        [item.data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *dict = (NSDictionary *)obj;

            NSString *field = [dict objectForKey:@"name"];
            NSString *value = [dict objectForKey:@"value"];
            
            if ([@"name" isEqualToString:field]) {
                conf.name = value;
            }
            if ([@"slug" isEqualToString:field]) {
                conf.slug = value;
            }
            if ([@"start" isEqualToString:field]) {
                conf.start = [EMSDateConverter dateFromString:value];
            }
            if ([@"end" isEqualToString:field]) {
                conf.end = [EMSDateConverter dateFromString:value];
            }
        }];
        
        [item.links enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CJLink *link = (CJLink *)obj;
            
            if ([@"session collection" isEqualToString:link.rel]) {
                NSLog(@"Saw a session collection href of %@", link.href);
            }
            if ([@"slot collection" isEqualToString:link.rel]) {
                NSLog(@"Saw a slot collection href of %@", link.href);
            }
            if ([@"room collection" isEqualToString:link.rel]) {
                NSLog(@"Saw a room collection href of %@", link.href);
            }
        }];
        
        [temp addObject:conf];
    }];
    
    [delegate finishedConferences:[NSArray arrayWithArray:temp]];
}


- (void)fetchedRoot:(NSData *)responseData {
    CJCollection *collection = [CJCollection collectionForNSData:responseData];
    
    [collection.links enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CJLink *link = (CJLink *)obj;
        
        if ([link.rel isEqualToString:@"event collection"]) {
            [self fetch:link.href withSelector:@selector(fetchedEventCollection:)];
        }
    }];
    
}

- (void)fetch:(NSURL *)url withSelector:(SEL)selector {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL:url];
        [self performSelectorOnMainThread:selector
                               withObject:data waitUntilDone:YES];
    });
}

- (void) fetch:(NSURL *)url {
    [self fetch:url withSelector:@selector(fetchedRoot:)];
}


@end
