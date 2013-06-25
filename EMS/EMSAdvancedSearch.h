//
//  EMSAdvancedSearch.h
//

#import <Foundation/Foundation.h>

@interface EMSAdvancedSearch : NSObject

typedef enum EMSSearchField : NSUInteger {
    emsKeyword,
    emsLevel,
    emsType,
    emsRoom
} EMSSearchField;

- (NSString *)search;
- (void)setSearch:(NSString *)search;

- (NSSet *)fieldValuesForKey:(EMSSearchField)key;
- (void)setFieldValues:(NSSet *)values forKey:(EMSSearchField)key;

- (BOOL)hasAdvancedSearch;

- (void)clear;

@end
