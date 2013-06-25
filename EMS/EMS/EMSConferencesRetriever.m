//
//  EMSConferencesRetriever.m
//

#import "EMSAppDelegate.h"

#import "EMSConferencesRetriever.h"
#import "EMSConference.h"

#import "CJCollection.h"
#import "CJLink.h"
#import "CJItem.h"

#import "EMSDateConverter.h"

@implementation EMSConferencesRetriever

NSDate *timer;

- (NSArray *)processData:(NSData *)data andHref:(NSURL *) href {
    NSError *error = nil;
    
    CJCollection *collection = [CJCollection collectionForNSData:data error:&error];
    
    if (!collection) {
        CLS_LOG(@"Failed to retrieve conferences %@ - %@ - %@", href, error, [error userInfo]);
        
        return [NSArray array];
    }
    
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
            if ([@"venue" isEqualToString:field]) {
                conf.venue = value;
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
                conf.sessionCollection = link.href;
                
                if (link.otherFields != nil) {
                    conf.hintCount = [link.otherFields objectForKey:@"count"];
                }
            }
            if ([@"slot collection" isEqualToString:link.rel]) {
                conf.slotCollection = link.href;
            }
            if ([@"room collection" isEqualToString:link.rel]) {
                conf.roomCollection = link.href;
            }
        }];
        
        [temp addObject:conf];
    }];
    
    return [NSArray arrayWithArray:temp];
}

- (void)fetchedEventCollection:(NSData *)responseData forHref:(NSURL *)href {
    NSArray *collection = [self processData:responseData andHref:href];

    [[EMSAppDelegate sharedAppDelegate] stopNetwork];

    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendTimingWithCategory:@"retrieval"
                          withValue:[[NSDate date] timeIntervalSinceDate:timer]
                           withName:@"conferences"
                          withLabel:nil];

    [[GAI sharedInstance] dispatch];

    [self.delegate finishedConferences:collection forHref:href];
}

- (void) fetch:(NSURL *)url {
    dispatch_queue_t queue = dispatch_queue_create("ems_conference_queue", DISPATCH_QUEUE_CONCURRENT);

    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    timer = [NSDate date];

    dispatch_async(queue, ^{
        NSError *rootError = nil;
        
        NSData* root = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&rootError];
        
        if (root == nil) {
            CLS_LOG(@"Retrieved nil root %@ - %@ - %@", url, rootError, [rootError userInfo]);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self fetchedEventCollection:nil forHref:url];
            });
        }
        
        if (root != nil) {
            dispatch_async(queue, ^{
                NSError *error = nil;
                
                CJCollection *collection = [CJCollection collectionForNSData:root error:&error];
            
                if (!collection) {
                    CLS_LOG(@"Failed to retrieve root %@ - %@ - %@", url, error, [error userInfo]);

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self fetchedEventCollection:nil forHref:url];
                    });
                }

                if (collection) {
                    [collection.links enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        CJLink *link = (CJLink *)obj;
                
                        if ([link.rel isEqualToString:@"event collection"]) {
                            dispatch_async(queue, ^{
                                NSError *eventsError = nil;
                            
                                NSData* events = [NSData dataWithContentsOfURL:link.href options:NSDataReadingMappedIfSafe error:&eventsError];

                                if (events == nil) {
                                    CLS_LOG(@"Retrieved nil events %@ - %@ - %@", url, eventsError, [eventsError userInfo]);
                                }

                                dispatch_async(queue, ^{
                                    [self fetchedEventCollection:events forHref:url];
                                });
                            });
                        }
                    }];
                }
            });
        }
    });
}


@end
