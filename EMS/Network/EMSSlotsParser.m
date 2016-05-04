//
//  EMSSlotsParser.m
//

#import "EMS-Swift.h"

#import "EMSSlotsParser.h"
#import "EMSSlot.h"

#import "CJCollection.h"
#import "CJItem.h"

#import "EMSDateConverter.h"

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation EMSSlotsParser

- (NSArray *)processData:(NSData *)data forHref:(NSURL *)href error:(NSError **)error {
    NSError *parseError = nil;

    CJCollection *collection = [CJCollection collectionForNSData:data error:&parseError];

    if (!collection) {
        DDLogError(@"Failed to retrieve slots %@ - %@ - %@", href, parseError, [parseError userInfo]);

        *error = parseError;

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
            if ([@"duration" isEqualToString:field]) {
                slot.duration = [value integerValue];
            }

        }];

        [temp addObject:slot];
    }];

    return [NSArray arrayWithArray:temp];
}

- (void)parseData:(NSData *)data forHref:(NSURL *)href {
    NSError *error;

    NSArray *collection = [self processData:data forHref:href error:&error];

    [self.delegate finishedSlots:collection forHref:href error:error];
}

@end
