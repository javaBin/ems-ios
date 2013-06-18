//
//  EMSConferencesRetriever.m
//

#import "EMSConferencesRetriever.h"
#import "EMSConference.h"

#import "CJCollection.h"
#import "CJLink.h"
#import "CJItem.h"

#import "EMSDateConverter.h"

@implementation EMSConferencesRetriever

- (void)fetchedEventCollection:(NSData *)responseData forHref:(NSURL *)href {
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
    
    [self.delegate finishedConferences:[NSArray arrayWithArray:temp] forHref:href];
}

- (void) fetch:(NSURL *)url {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        NSData* root = [NSData dataWithContentsOfURL:url];
        
        dispatch_async(queue, ^{
            CJCollection *collection = [CJCollection collectionForNSData:root];
            
            [collection.links enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                CJLink *link = (CJLink *)obj;
                
                if ([link.rel isEqualToString:@"event collection"]) {
                    dispatch_async(queue, ^{
                        NSData* events = [NSData dataWithContentsOfURL:link.href];

                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self fetchedEventCollection:events forHref:url];
                        });
                    });
                }
            }];
        });
    });
}


@end
