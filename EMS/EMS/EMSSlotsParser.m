//
//  EMSSlotsParser.m
//

#import "EMSSlotsParser.h"
#import "EMSSlot.h"

#import "CJCollection.h"
#import "CJItem.h"

#import "EMSDateConverter.h"

@implementation EMSSlotsParser

- (NSArray *)processData:(NSData *)data forHref:(NSURL *)href {
    NSError *error = nil;

    CJCollection *collection = [CJCollection collectionForNSData:data error:&error];

    if (!collection) {
        EMS_LOG(@"Failed to retrieve slots %@ - %@ - %@", href, error, [error userInfo]);

        return [NSArray array];
    }

    NSMutableArray *temp = [[NSMutableArray alloc] init];

    [collection.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CJItem *item = (CJItem *) obj;

        EMSSlot *slot = [[EMSSlot alloc] init];

        slot.href = item.href;

        [item.data enumerateObjectsUsingBlock:^(id dataObj, NSUInteger dataIdx, BOOL *dataStop) {
            NSDictionary *dict = (NSDictionary *) dataObj;

            NSString *field = dict[@"name"];
            NSString *value = dict[@"value"];

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

- (void)parseData:(NSData *)data forHref:(NSURL *)href {
    NSArray *collection = [self processData:data forHref:href];

    [self.delegate finishedSlots:collection forHref:href];
}

@end
