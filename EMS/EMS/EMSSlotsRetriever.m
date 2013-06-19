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

- (void)fetchedSlots:(NSData *)responseData forHref:(NSURL *)href {
    CJCollection *collection = [CJCollection collectionForNSData:responseData];
    
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

    [[EMSAppDelegate sharedAppDelegate] stopNetwork];

    [self.delegate finishedSlots:[NSArray arrayWithArray:temp] forHref:href];
}

- (void) fetch:(NSURL *)url {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    [[EMSAppDelegate sharedAppDelegate] startNetwork];

    dispatch_async(queue, ^{
        NSData* root = [NSData dataWithContentsOfURL:url];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetchedSlots:root forHref:url];
        });
    });
}

@end
