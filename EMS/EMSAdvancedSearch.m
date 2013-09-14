//
//  EMSAdvancedSearch.m
//

#import "EMSAdvancedSearch.h"

@interface EMSAdvancedSearch ()

@property (nonatomic, strong) NSString* searchText;
@property (nonatomic, strong) NSMutableDictionary *fields;

@end

@implementation EMSAdvancedSearch

NSString *const PrefsSearchText  = @"searchText";
NSString *const PrefsSearchField = @"searchFields";

-(id)init
{
    self = [super init];

    if(self) {
        self.searchText = @"";
        self.fields = [[NSMutableDictionary alloc] init];
    }
    
    [self retrieve];
    
    return self;
}

- (NSString *)search {
    return [NSString stringWithString:self.searchText];
}

- (void)setSearch:(NSString *)search {
    self.searchText = [NSString stringWithString:search];
    
    [self persist];
}

- (NSSet *)fieldValuesForKey:(EMSSearchField)key {
    NSNumber *k = [NSNumber numberWithInt:key];
    
    if ([self.fields.allKeys containsObject:k]) {
        return [NSSet setWithSet:[self.fields objectForKey:k]];
    }
    
    return [NSSet set];
}

- (void)setFieldValues:(NSSet *)values forKey:(EMSSearchField)key {
    NSNumber *k = [NSNumber numberWithInt:key];

    if (values != nil) {
        [self.fields setObject:values forKey:k];
    } else {
        [self.fields setObject:[NSSet set] forKey:k];
    }
    
    [self persist];
}

- (void) persist {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:self.searchText forKey:PrefsSearchText];

    NSMutableDictionary *fieldsAsArrays = [[NSMutableDictionary alloc] init];

    for (int i = emsKeyword; i <= emsLang; i++) {
        NSNumber *key = [NSNumber numberWithInt:i];
        
        if ([[self.fields allKeys] containsObject:key]) {
            [fieldsAsArrays setObject:[[self.fields objectForKey:key] allObjects] forKey:[key stringValue]];
        }
    }
    [defaults setObject:[NSDictionary dictionaryWithDictionary:fieldsAsArrays] forKey:PrefsSearchField];
    
    [defaults synchronize];
    
    [Crashlytics setObjectValue:self.searchText forKey:@"lastStoredSearchText"];
    [Crashlytics setObjectValue:self.fields forKey:@"lastStoredSearchFields"];
}

- (void) retrieve {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *storedSearchText = [defaults objectForKey:PrefsSearchText];
    if (storedSearchText != nil) {
        self.searchText = [NSString stringWithString:storedSearchText];
    }

    NSDictionary *storedSearchFields = [defaults objectForKey:PrefsSearchField];
    
    if (storedSearchFields != nil) {
        for (int i = emsKeyword; i <= emsLang; i++) {
            NSString *key = [[NSNumber numberWithInt:i] stringValue];
            
            if ([[storedSearchFields allKeys] containsObject:key]) {
                [self setFieldValues:[NSSet setWithArray:[storedSearchFields objectForKey:key]] forKey:i];
            } else {
                [self setFieldValues:[NSSet set] forKey:i];
            }
        }
    }

    [Crashlytics setObjectValue:self.searchText forKey:@"lastRetrievedSearchText"];
    [Crashlytics setObjectValue:self.fields forKey:@"lastRetrievedSearchFields"];
}

- (BOOL)hasAdvancedSearch {
    return ([[self fieldValuesForKey:emsKeyword] count] > 0 ||
            [[self fieldValuesForKey:emsLevel] count] > 0 ||
            [[self fieldValuesForKey:emsType] count] > 0 ||
            [[self fieldValuesForKey:emsRoom] count] > 0 ||
            [[self fieldValuesForKey:emsLang] count] > 0);
}

- (void) clear {
    [self setSearch:@""];
    
    for (int i = emsKeyword; i <= emsRoom; i++) {
        [self setFieldValues:[NSSet set] forKey:i];
    }
}

@end
