//
//  EMSSlotsRetriever.m
//

#import "EMSAppDelegate.h"

#import "EMSSlotsRetriever.h"
#import "EMSSlot.h"

#import "CJCollection.h"
#import "CJItem.h"

#import "EMSDateConverter.h"

@implementation EMSSlotsRetriever

NSDate *timer;

- (NSArray *)processData:(NSData *)data forHref:(NSURL *)href {
    NSError *error = nil;
    
    CJCollection *collection = [CJCollection collectionForNSData:data error:&error];
    
    if (!collection) {
        CLS_LOG(@"Failed to retrieve slots %@ - %@ - %@", href, error, [error userInfo]);
        
        return [NSArray array];
    }
    
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    
    [collection.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CJItem *item = (CJItem *)obj;
        
        EMSSlot *slot = [[EMSSlot alloc] init];
        
        slot.href = item.href;
        
        [item.data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *dict = (NSDictionary *)obj;
            
            NSString *field = [dict objectForKey:@"name"];
            NSString *value = [dict objectForKey:@"value"];
            
            if ([@"start" isEqualToString:field]) {
                slot.start = [EMSDateConverter dateFromString:value];
            }
            if ([@"end" isEqualToString:field]) {
                slot.end = [EMSDateConverter dateFromString:value];
            }
        }];
        
        [temp addObject:slot];
    }];
    
    return [NSArray arrayWithArray:temp];
}

- (void)fetchedSlots:(NSData *)responseData forHref:(NSURL *)href {
    NSArray *collection = [self processData:responseData forHref:href];
    
    [[EMSAppDelegate sharedAppDelegate] stopNetwork];

    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendTimingWithCategory:@"retrieval"
                          withValue:[[NSDate date] timeIntervalSinceDate:timer]
                           withName:@"slots"
                          withLabel:nil];


    [self.delegate finishedSlots:collection forHref:href];
}

- (void) fetch:(NSURL *)url {
    if (url == nil) {
        CLS_LOG(@"Asked to fetch nil slots url");

        return;
    }

    dispatch_queue_t queue = dispatch_queue_create("ems_slot_queue", DISPATCH_QUEUE_CONCURRENT);
    
    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    timer = [NSDate date];

    dispatch_async(queue, ^{
        NSError *rootError = nil;
        
        NSData* root = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&rootError];
        
        if (root == nil) {
            CLS_LOG(@"Retrieved nil root %@ - %@ - %@", url, rootError, [rootError userInfo]);
        }

        dispatch_async(queue, ^{
            [self fetchedSlots:root forHref:url];
        });
    });
}

@end
